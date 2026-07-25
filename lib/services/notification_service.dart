import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:android_intent_plus/android_intent.dart';
import '../models/masjid.dart';

/// Schedules local notifications that fire daily at each prayer time for
/// the masjid a user is following. Uses a full-screen alarm-style
/// notification so tapping (or the phone unlocking to it) opens the app
/// directly to a ringing screen that plays the masjid's uploaded Azan
/// audio, similar to how a normal alarm clock app behaves.
class NotificationService {
  static final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  static bool _initialized = false;

  static const _ids = {
    'fajr': 100,
    'dhuhr': 101,
    'asr': 102,
    'maghrib': 103,
    'isha': 104,
    'juma': 105,
  };

  /// [onTapPayload] is called with the notification's payload string
  /// whenever the user taps a fired notification - the app (main.dart)
  /// uses this to open the Azan ringing screen.
  static String _detectedTimezoneDebugInfo = 'not yet initialized';

  static Future<void> init({void Function(String? payload)? onTapPayload}) async {
    if (_initialized) return;
    tzdata.initializeTimeZones();

    try {
      final deviceTimeZone = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(deviceTimeZone));
      _detectedTimezoneDebugInfo = 'Detected: "$deviceTimeZone" -> using: ${tz.local.name}';
    } catch (e) {
      _detectedTimezoneDebugInfo = 'FAILED to detect/set timezone: $e (falling back to ${tz.local.name})';
    }

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidSettings);
    await _plugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (response) {
        onTapPayload?.call(response.payload);
      },
    );

    await Permission.notification.request();
    await Permission.scheduleExactAlarm.request();

    _initialized = true;
  }

  /// Android 12+ requires the user to explicitly enable "Alarms &
  /// Reminders" in system settings - a normal permission dialog can't
  /// grant this. If it's off, prayer alarms will silently fail to fire
  /// on time (or not fire at all), so the app should check this and
  /// prompt the user to fix it in Settings.
  static Future<bool> hasExactAlarmPermission() async {
    return await Permission.scheduleExactAlarm.isGranted;
  }

  static Future<void> openExactAlarmSettings() async {
    try {
      const intent = AndroidIntent(
        action: 'android.settings.REQUEST_SCHEDULE_EXACT_ALARM',
        data: 'package:com.example.masjid_alarm_app',
      );
      await intent.launch();
    } catch (_) {
      // Fallback for phones/Android versions that don't support this
      // specific screen - opens the app's general settings page instead.
      await openAppSettings();
    }
  }

  static DateTime? _parseTimeToday(String timeStr) {
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

      final now = DateTime.now();
      return DateTime(now.year, now.month, now.day, hour, minute);
    } catch (_) {
      return null;
    }
  }

  static String _buildPayload(String prayerLabel, String masjidName, String? audioUrl) {
    return '$prayerLabel|||$masjidName|||${audioUrl ?? ''}';
  }

  /// Splits a payload string back into (prayerLabel, masjidName, audioUrl).
  static (String, String, String?) parsePayload(String payload) {
    final parts = payload.split('|||');
    final prayer = parts.isNotEmpty ? parts[0] : 'Prayer';
    final masjid = parts.length > 1 ? parts[1] : '';
    final audio = parts.length > 2 && parts[2].isNotEmpty ? parts[2] : null;
    return (prayer, masjid, audio);
  }

  static Future<void> _scheduleDaily({
    required int id,
    required String title,
    required String body,
    required DateTime timeToday,
    String? payload,
  }) async {
    var scheduled = tz.TZDateTime.from(timeToday, tz.local);
    if (scheduled.isBefore(tz.TZDateTime.now(tz.local))) {
      scheduled = scheduled.add(const Duration(days: 1));
    }

    await _plugin.zonedSchedule(
      id,
      title,
      body,
      scheduled,
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
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
      payload: payload,
    );
  }

  static Future<List<String>> scheduleForMasjid(Masjid masjid) async {
    await init();
    await cancelAll();

    final scheduledSummary = <String>[];
    final times = masjid.prayerTimes;
    final entries = {
      'fajr': ('Fajr', times.fajr),
      'dhuhr': ('Dhuhr', times.dhuhr),
      'asr': ('Asr', times.asr),
      'maghrib': ('Maghrib', times.maghrib),
      'isha': ('Isha', times.isha),
      'juma': ('Juma (Friday)', times.juma),
    };

    for (final entry in entries.entries) {
      final key = entry.key;
      final label = entry.value.$1;
      final timeStr = entry.value.$2;
      final dt = _parseTimeToday(timeStr);
      if (dt == null) continue;

      await _scheduleDaily(
        id: _ids[key]!,
        title: '$label - ${masjid.name}',
        body: "It's time for $label prayer.",
        timeToday: dt,
        payload: _buildPayload(label, masjid.name, masjid.customAzanAudioUrl),
      );
      scheduledSummary.add('$label: $timeStr');
    }
    return scheduledSummary;
  }

  static Future<void> cancelAll() async {
    for (final id in _ids.values) {
      await _plugin.cancel(id);
    }
  }

  /// Diagnostic helper: lists whatever is currently scheduled at the OS
  /// level, so we can tell "never scheduled" (a code bug) apart from
  /// "scheduled correctly but the phone is killing it" (an OEM battery
  /// restriction) - the two look identical from the user's side (nothing
  /// happens), but need completely different fixes.
  static Future<List<String>> getPendingAlarms() async {
    final pending = await _plugin.pendingNotificationRequests();
    return pending.map((p) => '${p.title}\n   payload: ${p.payload}').toList();
  }

  /// Returns the actual next-trigger time for each currently scheduled
  /// prayer, computed the same way scheduling does - so we can directly
  /// compare "what the app thinks is scheduled" against "what you just set".
  static List<String> debugNextTriggerTimes(Masjid masjid) {
    final times = masjid.prayerTimes;
    final entries = {
      'Fajr': times.fajr,
      'Dhuhr': times.dhuhr,
      'Asr': times.asr,
      'Maghrib': times.maghrib,
      'Isha': times.isha,
      'Juma': times.juma,
    };
    final results = <String>['[Timezone] $_detectedTimezoneDebugInfo'];
    for (final e in entries.entries) {
      final dt = _parseTimeToday(e.value);
      if (dt == null) {
        results.add('${e.key}: not set');
        continue;
      }
      var scheduled = tz.TZDateTime.from(dt, tz.local);
      if (scheduled.isBefore(tz.TZDateTime.now(tz.local))) {
        scheduled = scheduled.add(const Duration(days: 1));
      }
      results.add('${e.key}: next fires at $scheduled');
    }
    return results;
  }
}
