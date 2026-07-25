import 'dart:convert';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

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

    final dataString = await FlutterForegroundTask.getData<String>(key: 'prayer_times_data');
    if (dataString == null) return;

    final Map<String, dynamic> data = json.decode(dataString);
    final masjidName = data['masjidName'] as String? ?? 'Your Masjid';
    final audioUrl = data['audioUrl'] as String?;
    final times = Map<String, dynamic>.from(data['times'] ?? {});

    final now = DateTime.now();
    final todayKey = '${now.year}-${now.month}-${now.day}';

    for (final entry in times.entries) {
      final label = entry.key;
      final timeStr = entry.value as String;
      final parsed = _parseTime(timeStr);
      if (parsed == null) continue;

      final matchesNow = now.hour == parsed.$1 && now.minute == parsed.$2;
      final fireKey = '$todayKey-$label';

      if (matchesNow && _lastFiredKey != fireKey) {
        _lastFiredKey = fireKey;
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

  Future<void> _fireAlarm(String label, String masjidName, String? audioUrl) async {
    await _plugin.show(
      200,
      '$label - $masjidName',
      "It's time for $label prayer.",
      NotificationDetails(
        android: AndroidNotificationDetails(
          'prayer_times_channel',
          'Prayer Time Alarms',
          channelDescription: 'Notifies you when it is time for prayer',
          importance: Importance.max,
          priority: Priority.high,
          category: AndroidNotificationCategory.alarm,
          fullScreenIntent: true,
        ),
      ),
      payload: '$label|||$masjidName|||${audioUrl ?? ''}',
    );
  }

  @override
  Future<void> onDestroy(DateTime timestamp, bool isTimeout) async {}
}
