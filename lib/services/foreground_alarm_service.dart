import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:path_provider/path_provider.dart';

import 'alarm_event_log.dart';
import 'notification_channels.dart';

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
  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
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
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidSettings);
    await _plugin.initialize(initSettings);
    _pluginInitialized = true;
  }

  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {
    await _ensurePluginInitialized();
  }

  @override
  Future<void> onRepeatEvent(DateTime timestamp) async {
    await _ensurePluginInitialized();

    // Proof-of-life: update the persistent notification's text with the
    // last-checked time, so we can visually confirm this loop is really
    // running, without needing device logs.
    await FlutterForegroundTask.updateService(
      notificationTitle: 'Islam Connect is active',
      notificationText: 'Last checked: ${timestamp.hour.toString().padLeft(2, '0')}:'
          '${timestamp.minute.toString().padLeft(2, '0')}:'
          '${timestamp.second.toString().padLeft(2, '0')}',
    );

    // A one-off test, delivered down the SAME path a prayer uses.
    //
    // The OS scheduler does not deliver on every device — this app has a phone
    // where zonedSchedule arms without error and never fires, while this
    // service posts notifications perfectly. Routing the test through here
    // tests the mechanism that actually carries prayers.
    await _checkTestAlarm();

    final dataString =
        await FlutterForegroundTask.getData<String>(key: 'prayer_times_data');
    if (dataString == null) {
      await AlarmEventLog.add('service tick', detail: 'NO PRAYER DATA STORED');
      return;
    }

    final Map<String, dynamic> data = json.decode(dataString);
    final masjidName = data['masjidName'] as String? ?? 'Your Masjid';
    final audioUrl = data['audioUrl'] as String?;
    final times = Map<String, dynamic>.from(data['times'] ?? {});

    final now = DateTime.now();
    final todayKey = '${now.year}-${now.month}-${now.day}';

    // Restore from disk on the first tick after an isolate restart. Held only
    // in memory, this set resets whenever Android recreates the isolate — and
    // a forgotten "already fired" means the same prayer rings twice.
    if (!_restored) {
      _restored = true;
      try {
        final String? raw =
            await FlutterForegroundTask.getData<String>(key: 'fired_keys');
        if (raw != null) {
          final decoded = json.decode(raw) as Map<String, dynamic>;
          if (decoded['day'] == todayKey) {
            _firedKeys =
                (decoded['keys'] as List).map((e) => e.toString()).toSet();
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
      await _updateNotificationText(times, now);
    }

    if (now.second < 20) {
      await AlarmEventLog.add('service tick',
          detail: 'watching ${times.values.join(', ')}');
    }

    for (final entry in times.entries) {
      final label = entry.key;
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
        final String juma = (times.entries
                .firstWhere((e) => e.key.toLowerCase().contains('juma'),
                    orElse: () => const MapEntry<String, dynamic>('', ''))
                .value as String?) ??
            '';
        if (juma.trim().isNotEmpty && _parseTime(juma) != null) continue;
      }

      final scheduledMinutes = parsed.$1 * 60 + parsed.$2;
      final nowMinutes = now.hour * 60 + now.minute;
      // Allow a small window (the scheduled minute or the one right after)
      // so a single slightly-delayed polling cycle doesn't cause a missed
      // alarm - the _firedKeys check below still guarantees a given
      // prayer at a given time fires only once.
      final withinWindow = nowMinutes == scheduledMinutes || nowMinutes == scheduledMinutes + 1;
      final fireKey = '$todayKey-$label-$timeStr';

      if (withinWindow && !_firedKeys.contains(fireKey)) {
        _firedKeys.add(fireKey);
        await _persistFired(todayKey);
        await AlarmEventLog.add('FIRED by service', detail: '$label at $timeStr');
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

  Future<void> _playAzan(String? audioUrl) async {
    try {
      // Alarm usage: plays at alarm volume and is not silenced by the ringer
      // switch, which is what a call to prayer should do.
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
    } catch (_) {}

    if (audioUrl != null && audioUrl.isNotEmpty) {
      // Local cache first - see ForegroundAlarmManager._cacheCustomAzan,
      // which downloads this ahead of time whenever the app has a normal
      // foreground connection. No network dependency at all if it is there.
      try {
        final Directory dir = await getApplicationDocumentsDirectory();
        final File urlFile = File('${dir.path}/custom_azan_cache_url.txt');
        final File audioFile = File('${dir.path}/custom_azan_cache.mp3');

        if (await audioFile.exists() &&
            await urlFile.exists() &&
            await urlFile.readAsString() == audioUrl) {
          await _azanPlayer.play(DeviceFileSource(audioFile.path));
          await AlarmEventLog.add('azan playing',
              detail: 'masjid recording (cached)');
          return;
        }
      } catch (_) {}

      // Cache missed - fall back to fetching it live. THIS USED TO BE A
      // 4-SECOND TIMEOUT, which was the actual bug: not enough time for the
      // radio to wake, resolve DNS, and start buffering from Firebase
      // Storage, especially from inside a background service at exactly the
      // moment Android is least willing to grant network access. Every
      // real-world custom upload could plausibly miss that window and
      // silently fall back to the bundled azan below - which is exactly
      // "I uploaded a recording and the default still plays." 15 seconds
      // gives a cold connection a real chance while still giving up before
      // the prayer time is meaningfully late.
      try {
        await _azanPlayer
            .play(UrlSource(audioUrl))
            .timeout(const Duration(seconds: 15));
        await AlarmEventLog.add('azan playing',
            detail: 'masjid recording (live)');
        return;
      } catch (_) {}
    }

    try {
      await _azanPlayer.play(AssetSource('audio/azan.mp3'));
      await AlarmEventLog.add('azan playing', detail: 'bundled recording');
    } catch (e) {
      await AlarmEventLog.add('azan FAILED', detail: '$e');
    }
  }

  /// Belt and braces. If playback somehow loops or hangs, this ends it without
  /// the user having to do anything. An azan that will not stop is worse than
  /// one that is a minute late.
  void _armAutoStop() {
    _autoStop?.cancel();
    _autoStop = Timer(const Duration(minutes: 6), () {
      _stopAzan();
      _setServiceNotice('Watching prayer times');
    });
  }

  Timer? _autoStop;

  Future<void> _stopAzan() async {
    _autoStop?.cancel();
    try {
      await _azanPlayer.stop();
      await AlarmEventLog.add('azan stopped');
    } catch (_) {}
  }

  /// Lets the app tell the service to stop the azan. The two live in different
  /// isolates and cannot share the player, so this is the only route.
  @override
  void onReceiveData(Object data) {
    if (data == 'stop_azan') {
      _stopAzan();
    }
  }

  /// The Stop button on the service's own persistent notification.
  ///
  /// THIS is the reliable stop. The ringing screen's button only exists if
  /// Android launched that screen, which is the very thing it refuses to do
  /// when the phone is locked — so the azan could play with no way to stop it
  /// short of powering the phone off.
  ///
  /// The service notification is always present whenever the service is
  /// running, and this handler executes in the isolate that owns the player.
  @override
  void onNotificationButtonPressed(String id) {
    if (id == 'stop_azan') {
      _stopAzan();
      _setServiceNotice('Watching prayer times');
    }
  }

  Future<void> _setServiceNotice(String text) async {
    try {
      await FlutterForegroundTask.updateService(
        notificationTitle: 'Islam Connect is active',
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
        value: json.encode(
            <String, dynamic>{'day': todayKey, 'keys': _firedKeys.toList()}),
      );
    } catch (_) {}
  }

  /// Writes "Asr 5:40 PM · in 2h 6m" onto the service notification.
  Future<void> _updateNotificationText(
      Map<String, dynamic> times, DateTime now) async {
    try {
      String? bestLabel;
      DateTime? bestAt;

      for (final entry in times.entries) {
        final label = entry.key;
        final value = (entry.value as String?) ?? '';
        if (value.trim().isEmpty) continue;
        // Juma only counts down on a Friday, and Dhuhr does not count down on
        // one — the same rule the alarms follow.
        final bool isJuma = label.toLowerCase().contains('juma');
        if (isJuma && now.weekday != DateTime.friday) continue;
        if (label.toLowerCase() == 'dhuhr' && now.weekday == DateTime.friday) {
          continue;
        }
        final parsed = _parseTime(value);
        if (parsed == null) continue;

        var at = DateTime(now.year, now.month, now.day, parsed.$1, parsed.$2);
        if (!at.isAfter(now)) at = at.add(const Duration(days: 1));
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
        notificationText: times[bestLabel] as String? ?? '',
      );
    } catch (_) {
      // Never let a notification update interfere with the alarm loop.
    }
  }

  Future<void> _checkTestAlarm() async {
    try {
      final String? raw =
          await FlutterForegroundTask.getData<String>(key: 'service_test_at');
      if (raw == null) return;

      final int at = int.tryParse(raw) ?? 0;
      if (at == 0) return;
      if (DateTime.now().millisecondsSinceEpoch < at) return;

      // Overwrite with 0 rather than removeData — same effect (the guard
      // above treats 0 as "nothing pending") and it avoids depending on an
      // API whose presence varies across plugin versions.
      await FlutterForegroundTask.saveData(key: 'service_test_at', value: '0');
      await AlarmEventLog.add('FIRED test by service',
          detail: 'delivered by the polling service, not the OS scheduler');

      await _plugin.show(
        996,
        'Test alarm',
        'Delivered by the background service. This is the path prayers use.',
        NotificationDetails(
          android: AndroidNotificationDetails(
            NotificationChannels.plain,
            'Prayer Time Alarms',
            channelDescription: 'Alerts you when it is time for prayer',
            importance: Importance.max,
            priority: Priority.high,
            category: AndroidNotificationCategory.alarm,
            fullScreenIntent: true,
            ongoing: true,
            actions: <AndroidNotificationAction>[
              AndroidNotificationAction(
                'stop_azan',
                'Stop azan',
                showsUserInterface: false,
                cancelNotification: true,
              ),
            ],
          ),
        ),
        payload: 'Test|||Test|||',
      );

      // Play the azan on the test too — otherwise the test proves the
      // notification works while saying nothing about the part that matters.
      await _setServiceNotice('Azan playing - tap Stop azan to end it');
      _armAutoStop();
      await _playAzan(null);
    } catch (_) {}
  }

  Future<void> _fireAlarm(String label, String masjidName, String? audioUrl) async {
    // OVERLAY REMOVED.
    //
    // This used to open a system overlay window before posting the
    // notification, on the reasoning that an overlay draws over anything
    // including the lock screen, whereas a full-screen intent only
    // auto-launches when locked.
    //
    // In practice it earned nothing. Tested on a device with "Appear on top"
    // switched OFF the whole time: the azan still played and the alert still
    // arrived, because the service plays the audio itself and the notification
    // carries a full-screen intent.
    //
    // It cost SYSTEM_ALERT_WINDOW — the permission Google scrutinises hardest —
    // plus a native plugin and a second Flutter entry point, to duplicate
    // something that already worked.

    // Also fire a regular notification as a backup/secondary signal -
    // this still works even if overlay permission was never granted.
    await _plugin.show(
      200,
      '$label - $masjidName',
      "It's time for $label prayer.",
      NotificationDetails(
        // MUST match the channel NotificationService creates.
        //
        // This posted to 'prayer_times_channel', which NotificationService now
        // deletes on startup. On Android 8+ posting to a deleted channel fails
        // SILENTLY - so this backup path, the one that matters most when the
        // app has been killed, was doing nothing at all.
        android: AndroidNotificationDetails(
          NotificationChannels.plain,
          'Prayer Time Alarms',
          channelDescription: 'Alerts you when it is time for prayer',
          importance: Importance.max,
          priority: Priority.high,
          category: AndroidNotificationCategory.alarm,
          fullScreenIntent: true,
          playSound: true,
          // Deliberately NOT the raw azan resource. If that file is missing
          // from the build the URI is invalid, and this path — the one that
          // actually delivers on restrictive phones — would break with it.
          // The service plays the azan itself instead.
          audioAttributesUsage: AudioAttributesUsage.alarm,
          // Stop, on the notification you actually see. The service's own
          // notification also carries one, but that sits collapsed at the
          // bottom of the shade at LOW importance — no use when an azan is
          // playing and you want it to stop NOW.
          ongoing: true,
          actions: <AndroidNotificationAction>[
            AndroidNotificationAction(
              'stop_azan',
              'Stop azan',
              showsUserInterface: false,
              cancelNotification: true,
            ),
          ],
        ),
      ),
      payload: '$label|||$masjidName|||${audioUrl ?? ''}',
    );

    // Play it here, from the service. Whether or not any screen opens.
    await _setServiceNotice('Azan playing - tap Stop azan to end it');
    _armAutoStop();
    await _playAzan(audioUrl);
  }

  @override
  Future<void> onDestroy(DateTime timestamp) async {}
}
