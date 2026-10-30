import 'masjid_clock.dart';

import 'package:timezone/timezone.dart' as tz;

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui' show Color;

import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:path_provider/path_provider.dart';

import 'alarm_event_log.dart';
import 'notification_channels.dart';
import 'azan_stop_controller.dart';
import 'prayer_notification_preferences.dart';

import 'package:azan_screen_events/azan_screen_events.dart';

/// This runs in its own persistent background isolate, kept alive by a
/// permanent low-priority "service" notification. Instead of relying on
/// a single OS-scheduled alarm (which Samsung and other OEMs can silently
/// kill), this actively checks the time every ~20 seconds and fires the
/// Azan itself when a prayer time matches - the same technique used by
/// alarm-clock and fitness-tracking apps that need to survive aggressive
/// battery management.
@pragma('vm:entry-point')
void startForegroundTaskCallback() {
  FlutterForegroundTask.setTaskHandler(PrayerAlarmTaskHandler());
}

class PrayerAlarmTaskHandler extends TaskHandler {
  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  bool _pluginInitialized = false;

  /// Prayers already fired, as "date-label-time" strings.
  ///
  /// A SET, not a single value, and the TIME is part of the key. Both matter:
  ///
  ///   * A single value meant Fajr firing wiped the memory of Dhuhr, so
  ///     ordering bugs were possible.
  ///   * Keying on date+label alone meant a prayer could only ever fire once
  ///     per day. Correct a time after that prayer has already passed — which
  ///     an admin fixing a mistake does, and which is exactly how this app
  ///     gets tested — and the corrected alarm was silently skipped.
  ///
  /// Including the time means a changed time is a genuinely new alarm and
  /// rings, while an unchanged one still fires only once.
  Set<String> _firedKeys = <String>{};

  Future<void> _ensurePluginInitialized() async {
    if (_pluginInitialized) return;
    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const initSettings = InitializationSettings(android: androidSettings);
    await _plugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (response) {
        if (response.actionId == 'stop_azan') _stopAzan();
      },
      onDidReceiveBackgroundNotificationResponse:
          azanNotificationActionBackground,
    );
    _pluginInitialized = true;
  }

  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {
    await _ensurePluginInitialized();
    _screenEvents = AzanScreenEvents.changes.listen(
      (_) {
        if (_ringing || _activeNotificationId != null) _stopAzan();
      },
      onError: (Object error) {
        AlarmEventLog.add('screen event listener failed', detail: '$error');
      },
    );
    _playerComplete = _azanPlayer.onPlayerComplete.listen((_) {
      if (_ringing) _stopAzan(reason: 'Azaan finished');
    });
  }

  StreamSubscription<void>? _playerComplete;
  StreamSubscription<dynamic>? _screenEvents;
  bool _ringing = false;
  int _playbackGeneration = 0;

  @override
  Future<void> onRepeatEvent(DateTime timestamp) async {
    await _ensurePluginInitialized();

    // A one-off test, delivered down the SAME path a prayer uses.
    //
    // The OS scheduler does not deliver on every device — this app has a phone
    // where zonedSchedule arms without error and never fires, while this
    // service posts notifications perfectly. Routing the test through here
    // tests the mechanism that actually carries prayers.
    await _checkTestAlarm();

    final dataString = await FlutterForegroundTask.getData<String>(
      key: 'prayer_times_data',
    );
    if (dataString == null) {
      await AlarmEventLog.add('service tick', detail: 'NO PRAYER DATA STORED');
      return;
    }

    final Map<String, dynamic> data = json.decode(dataString);
    final masjidName = data['masjidName'] as String? ?? 'Your Masjid';
    final audioUrl = data['audioUrl'] as String?;
    final times = Map<String, dynamic>.from(data['times'] ?? {});

    final zone = data['timeZone'] as String?;
    if (zone == null) return; // Legacy cache must be refreshed online.
    final now = tz.TZDateTime.now(MasjidClock.location(zone));
    final todayKey = '${now.year}-${now.month}-${now.day}';

    // Restore from disk on the first tick after an isolate restart. Held only
    // in memory, this set resets whenever Android recreates the isolate — and
    // a forgotten "already fired" means the same prayer rings twice.
    if (!_restored) {
      _restored = true;
      try {
        final String? raw = await FlutterForegroundTask.getData<String>(
          key: 'fired_keys',
        );
        if (raw != null) {
          final decoded = json.decode(raw) as Map<String, dynamic>;
          if (decoded['day'] == todayKey) {
            _firedKeys = (decoded['keys'] as List)
                .map((e) => e.toString())
                .toSet();
          }
        }
      } catch (_) {}
    }

    // THE NOTIFICATION EARNS ITS PLACE.
    //
    // Android requires a foreground service to show a permanent notification —
    // it cannot be hidden, and the service is what actually delivers the alarms
    // on this phone. So the only honest options were to leave it saying
    // "Islam Connect is active", which tells the user nothing, or to make it
    // useful.
    //
    // It now shows the next prayer and how long until it. Updated once a minute
    // rather than every tick: the text only changes by the minute, and
    // rewriting a notification every 20 seconds is three times the work for no
    // visible difference.
    if (now.second < 20) {
      if (!_ringing) await _updateNotificationText(times, now, zone);
    }

    if (now.second < 20) {
      await AlarmEventLog.add(
        'service tick',
        detail: 'watching ${times.values.join(', ')}',
      );
    }

    for (final entry in times.entries) {
      final label = entry.key;
      if (!await PrayerNotificationPreferences.enabled(
        PrayerNotificationPreferences.keyForLabel(label),
      ))
        continue;
      final timeStr = entry.value as String;
      final parsed = _parseTime(timeStr);
      if (parsed == null) continue;

      // JUMA IS A FRIDAY PRAYER.
      //
      // The scheduler was taught this in v10 (matchDateTimeComponents set to
      // dayOfWeekAndTime), but this loop was not — it walks all six times and
      // fires whichever matches the clock, on any day. Since this service is
      // the path that actually delivers on restrictive phones, the scheduler
      // fix never took effect where it counted, and Juma rang on a Monday.
      //
      // Matching on the label rather than a key because that is what the
      // service is given: 'Juma (Friday)'.
      if (label.toLowerCase().contains('juma') &&
          now.weekday != DateTime.friday) {
        continue;
      }

      // AND THE REVERSE: no Dhuhr alarm on a Friday.
      //
      // Juma REPLACES Dhuhr, it does not accompany it. Both were firing every
      // Friday — two azans within minutes of each other, and the Dhuhr one for
      // a prayer nobody is praying.
      //
      // Only suppressed when the masjid has actually set a Juma time. If Juma
      // is blank, Dhuhr must still fire or Friday would have no midday alarm at
      // all.
      if (label.toLowerCase() == 'dhuhr' && now.weekday == DateTime.friday) {
        final String juma =
            (times.entries
                    .firstWhere(
                      (e) => e.key.toLowerCase().contains('juma'),
                      orElse: () => const MapEntry<String, dynamic>('', ''),
                    )
                    .value
                as String?) ??
            '';
        if (juma.trim().isNotEmpty && _parseTime(juma) != null) continue;
      }

      final scheduledMinutes = parsed.$1 * 60 + parsed.$2;
      final nowMinutes = now.hour * 60 + now.minute;
      // Allow a small window (the scheduled minute or the one right after)
      // so a single slightly-delayed polling cycle doesn't cause a missed
      // alarm - the _firedKeys check below still guarantees a given
      // prayer at a given time fires only once.
      final withinWindow =
          nowMinutes == scheduledMinutes || nowMinutes == scheduledMinutes + 1;
      final fireKey = '$zone-$masjidName-$todayKey-$label-$timeStr';

      if (withinWindow && !_firedKeys.contains(fireKey)) {
        _firedKeys.add(fireKey);
        await _persistFired(todayKey);
        await AlarmEventLog.add(
          'FIRED by service',
          detail: '$label at $timeStr',
        );
        await _fireAlarm(label, masjidName, audioUrl);
      }
    }
  }

  (int, int)? _parseTime(String timeStr) {
    if (timeStr.trim() == '--:--' || timeStr.trim().isEmpty) return null;
    try {
      final parts = timeStr.trim().split(' ');
      final hm = parts[0].split(':');
      int hour = int.parse(hm[0]);
      final minute = int.parse(hm[1]);
      final isPM = parts.length > 1 && parts[1].toUpperCase() == 'PM';
      final isAM = parts.length > 1 && parts[1].toUpperCase() == 'AM';
      if (isPM && hour != 12) hour += 12;
      if (isAM && hour == 12) hour = 0;
      return (hour, minute);
    } catch (_) {
      return null;
    }
  }

  /// Fires a pending service test once its moment arrives, then clears it.
  bool _restored = false;

  /// The azan is played BY THE SERVICE, not by the ringing screen.
  ///
  /// It used to depend on the full-screen intent launching an activity — which
  /// is the exact thing Android blocks when the phone is locked or the app has
  /// been killed. So the alarm arrived and the azan did not, which is the
  /// worst possible half-success for this app.
  ///
  /// This isolate is already alive and already posting the notifications. It
  /// can play audio too, needing no activity, no full-screen intent and no
  /// notification channel sound. Nothing has to be granted for it to work.
  static final AudioPlayer _azanPlayer = AudioPlayer();

  Timer? _autoStop;
  Timer? _stopWatch;
  int? _activeNotificationId;
  String _activePrayer = 'Prayer';
  String _activeMasjid = '';

  Future<void> _playAzan(
    String? audioUrl,
    int generation,
    int stopSequence,
  ) async {
    Future<bool> cancelled() async =>
        !_ringing ||
        generation != _playbackGeneration ||
        await AzanScreenEvents.stopSequence() != stopSequence;

    try {
      await _azanPlayer.setAudioContext(
        AudioContext(
          android: const AudioContextAndroid(
            isSpeakerphoneOn: false,
            stayAwake: true,
            contentType: AndroidContentType.music,
            usageType: AndroidUsageType.alarm,
            audioFocus: AndroidAudioFocus.gainTransientMayDuck,
          ),
        ),
      );
      await _azanPlayer.setVolume(1.0);
      bool loaded = false;
      if (audioUrl != null && audioUrl.isNotEmpty) {
        try {
          final dir = await getApplicationDocumentsDirectory();
          final urlFile = File('${dir.path}/custom_azan_cache_url.txt');
          final audioFile = File('${dir.path}/custom_azan_cache.mp3');
          if (await cancelled()) return;
          if (await audioFile.exists() &&
              await urlFile.exists() &&
              await urlFile.readAsString() == audioUrl) {
            await _azanPlayer.setSource(DeviceFileSource(audioFile.path));
            loaded = true;
          }
        } catch (_) {}
        if (!loaded) {
          if (await cancelled()) return;
          try {
            // Prepare first; never start playback as a side effect of loading.
            await _azanPlayer
                .setSource(UrlSource(audioUrl))
                .timeout(const Duration(seconds: 15));
            loaded = true;
          } catch (_) {
            await _azanPlayer.stop();
          }
        }
      }
      if (await cancelled()) return;
      if (!loaded) await _azanPlayer.setSource(AssetSource('audio/azan.mp3'));
      if (await cancelled()) return;
      await _azanPlayer.resume();
      if (await cancelled()) {
        await _azanPlayer.stop();
        return;
      }
      await AlarmEventLog.add('azan playing', detail: _activePrayer);
    } catch (error) {
      await AlarmEventLog.add('azan FAILED', detail: '$error');
      if (generation == _playbackGeneration)
        await _stopAzan(reason: 'Audio unavailable');
    }
  }

  /// All stop controls reach the same player and invalidate pending audio loads.
  Future<void> _stopAzan({String reason = 'Azaan stopped'}) async {
    _ringing = false;
    final generation = ++_playbackGeneration;
    _autoStop?.cancel();
    _stopWatch?.cancel();
    try {
      await _azanPlayer.stop();
    } catch (_) {}
    if (generation != _playbackGeneration) return;
    final id = _activeNotificationId;
    _activeNotificationId = null;
    if (id != null) {
      await _plugin.show(
        id,
        '$_activePrayer • $reason',
        _activeMasjid,
        NotificationDetails(
          android: AndroidNotificationDetails(
            NotificationChannels.silent,
            'Prayer Time Alarms',
            playSound: false,
            enableVibration: false,
            importance: Importance.defaultImportance,
            priority: Priority.defaultPriority,
            onlyAlertOnce: true,
            ongoing: false,
            autoCancel: true,
            color: const Color(0xFF175941),
          ),
        ),
      );
    }
    await _setServiceNotice('Prayer reminders are active');
    await AlarmEventLog.add('azan stopped', detail: reason);
  }

  @override
  void onReceiveData(Object data) {
    if (data == 'stop_azan') _stopAzan();
  }

  @override
  void onNotificationButtonPressed(String id) {
    if (id == 'stop_azan') _stopAzan();
  }

  Future<void> _setServiceNotice(String text) async {
    try {
      await FlutterForegroundTask.updateService(
        notificationTitle: 'Islam Connect',
        notificationText: text,
      );
    } catch (_) {}
  }

  /// Keeps the fired set across isolate restarts. Scoped to the day, so it
  /// clears itself at midnight rather than growing forever.
  Future<void> _persistFired(String todayKey) async {
    try {
      await FlutterForegroundTask.saveData(
        key: 'fired_keys',
        value: json.encode(<String, dynamic>{
          'day': todayKey,
          'keys': _firedKeys.toList(),
        }),
      );
    } catch (_) {}
  }

  /// Writes "Asr 5:40 PM · in 2h 6m" onto the service notification.
  Future<void> _updateNotificationText(
    Map<String, dynamic> times,
    DateTime now,
    String zone,
  ) async {
    try {
      String? bestLabel;
      DateTime? bestAt;

      for (final entry in times.entries) {
        final label = entry.key;
        final value = (entry.value as String?) ?? '';
        if (value.trim().isEmpty) continue;
        final at = MasjidClock.next(
          value,
          zone,
          now,
          fridayOnly: label.toLowerCase().contains('juma'),
          skipFriday:
              label.toLowerCase() == 'dhuhr' &&
              times.entries.any(
                (e) =>
                    e.key.toLowerCase().contains('juma') &&
                    MasjidClock.parse(e.value as String? ?? '') != null,
              ),
        );
        if (at == null) continue;
        if (bestAt == null || at.isBefore(bestAt)) {
          bestAt = at;
          bestLabel = label;
        }
      }

      if (bestLabel == null || bestAt == null) return;

      final d = bestAt.difference(now);
      final String left = d.inHours > 0
          ? '${d.inHours}h ${d.inMinutes % 60}m'
          : '${d.inMinutes}m';

      await FlutterForegroundTask.updateService(
        notificationTitle: '$bestLabel — in $left',
        notificationText:
            '${MasjidClock.localDisplay(times[bestLabel] as String? ?? '', zone, now)} (device time)',
      );
    } catch (_) {
      // Never let a notification update interfere with the alarm loop.
    }
  }

  Future<void> _checkTestAlarm() async {
    try {
      final String? raw = await FlutterForegroundTask.getData<String>(
        key: 'service_test_at',
      );
      if (raw == null) return;

      final int at = int.tryParse(raw) ?? 0;
      if (at == 0) return;
      if (DateTime.now().millisecondsSinceEpoch < at) return;

      // Overwrite with 0 rather than removeData — same effect (the guard
      // above treats 0 as "nothing pending") and it avoids depending on an
      // API whose presence varies across plugin versions.
      await FlutterForegroundTask.saveData(key: 'service_test_at', value: '0');
      await AlarmEventLog.add(
        'FIRED test by service',
        detail: 'delivered by the polling service, not the OS scheduler',
      );

      await _showPrayerAlert('Test', 'Islam Connect', null, id: 996);
    } catch (_) {}
  }

  Future<void> _fireAlarm(String label, String masjidName, String? audioUrl) =>
      _showPrayerAlert(label, masjidName, audioUrl);

  Future<void> _showPrayerAlert(
    String label,
    String masjidName,
    String? audioUrl, {
    int id = 200,
  }) async {
    final generation = ++_playbackGeneration;
    _autoStop?.cancel();
    _stopWatch?.cancel();
    _activePrayer = label;
    _activeMasjid = masjidName;
    _activeNotificationId = id;
    _ringing = true; // Includes preparation: a stop during loading must win.
    final sequence = await AzanScreenEvents.stopSequence();
    final sound = await PrayerNotificationPreferences.soundEnabled();
    if (generation != _playbackGeneration) return;
    _ringing = sound;
    await _plugin.show(
      id,
      '$label prayer time',
      sound ? '$masjidName • Tap STOP AZAAN to end the sound' : masjidName,
      NotificationDetails(
        android: AndroidNotificationDetails(
          NotificationChannels.silent,
          'Prayer Time Alarms',
          channelDescription: 'Prayer reminders with Azaan playback controls',
          importance: Importance.max,
          priority: Priority.high,
          category: AndroidNotificationCategory.alarm,
          fullScreenIntent: sound,
          playSound: false,
          color: const Color(0xFF175941),
          styleInformation: BigTextStyleInformation(
            sound
                ? '$masjidName\nAzaan is playing. Tap STOP AZAAN to stop.'
                : '$masjidName\nIt is time for $label prayer.',
          ),
          onlyAlertOnce: true,
          ongoing: sound,
          autoCancel: !sound,
          actions: sound
              ? <AndroidNotificationAction>[
                  AndroidNotificationAction(
                    'stop_azan',
                    'STOP AZAAN',
                    showsUserInterface: false,
                    cancelNotification: false,
                  ),
                ]
              : null,
        ),
      ),
      payload: '$label|||$masjidName|||${audioUrl ?? ''}',
    );
    if (generation != _playbackGeneration ||
        await AzanScreenEvents.stopSequence() != sequence) {
      await _stopAzan();
      return;
    }
    if (!sound) {
      _activeNotificationId = null;
      return;
    }
    await _setServiceNotice('$label Azaan • Tap STOP AZAAN to stop');
    _autoStop = Timer(
      const Duration(minutes: 6),
      () => _stopAzan(reason: 'Azaan finished'),
    );
    // Persisted fallback: if a broadcast is missed, stop still reaches playback.
    _stopWatch = Timer.periodic(const Duration(milliseconds: 400), (_) async {
      if (_ringing && await AzanScreenEvents.stopSequence() != sequence) {
        await _stopAzan();
      }
    });
    await _playAzan(audioUrl, generation, sequence);
  }

  @override
  Future<void> onDestroy(DateTime timestamp) async {
    await _screenEvents?.cancel();
    await _playerComplete?.cancel();
    await _stopAzan();
    await _azanPlayer.dispose();
  }
}
