import 'dart:convert';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'alarm_event_log.dart';
import 'notification_channels.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart' as overlay;

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
  String? _lastFiredKey;

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
      notificationTitle: 'Masjid Namaz Alarm is active',
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

    // One heartbeat a minute, not one every 20 seconds. Its value is not the
    // beat itself but the GAP: a hole in these timestamps is the OS having
    // frozen the service, which is invisible any other way.
    if (now.second < 20) {
      await AlarmEventLog.add('service tick',
          detail: 'watching ${times.values.join(', ')}');
    }

    for (final entry in times.entries) {
      final label = entry.key;
      final timeStr = entry.value as String;
      final parsed = _parseTime(timeStr);
      if (parsed == null) continue;

      final scheduledMinutes = parsed.$1 * 60 + parsed.$2;
      final nowMinutes = now.hour * 60 + now.minute;
      // Allow a small window (the scheduled minute or the one right after)
      // so a single slightly-delayed polling cycle doesn't cause a missed
      // alarm - the _lastFiredKey check below still guarantees it only
      // fires once per prayer per day.
      final withinWindow = nowMinutes == scheduledMinutes || nowMinutes == scheduledMinutes + 1;
      final fireKey = '$todayKey-$label';

      if (withinWindow && _lastFiredKey != fireKey) {
        _lastFiredKey = fireKey;
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
          ),
        ),
        payload: 'Test|||Test|||',
      );
    } catch (_) {}
  }

  Future<void> _fireAlarm(String label, String masjidName, String? audioUrl) async {
    // Primary path: a real system overlay window that appears on top of
    // ANY app or even the lock screen - stronger than a notification's
    // "full screen intent", which Android only auto-launches when the
    // phone is locked. This guarantees the alert is seen either way.
    try {
      final isActive = await overlay.FlutterOverlayWindow.isActive();
      if (!isActive) {
        await overlay.FlutterOverlayWindow.showOverlay(
          height: overlay.WindowSize.matchParent,
          width: overlay.WindowSize.matchParent,
          flag: overlay.OverlayFlag.defaultFlag,
          visibility: overlay.NotificationVisibility.visibilityPublic,
          positionGravity: overlay.PositionGravity.none,
        );
        // Give the overlay a moment to initialize before sending it data.
        await Future.delayed(const Duration(milliseconds: 400));
      }
      await overlay.FlutterOverlayWindow.shareData({
        'prayer': label,
        'masjid': masjidName,
        'audioUrl': audioUrl ?? '',
      });
    } catch (_) {
      // If overlay permission isn't granted, fall through to the
      // notification below so the user still gets some alert.
    }

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
          // The azan plays from the bundled Flutter asset in the ringing
          // screen instead.
          audioAttributesUsage: AudioAttributesUsage.alarm,
        ),
      ),
      payload: '$label|||$masjidName|||${audioUrl ?? ''}',
    );
  }

  @override
  Future<void> onDestroy(DateTime timestamp) async {}
}
