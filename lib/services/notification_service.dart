import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:permission_handler/permission_handler.dart';
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
  static Future<void> init({void Function(String? payload)? onTapPayload}) async {
    if (_initialized) return;
    tzdata.initializeTimeZones();

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

  static Future<void> scheduleForMasjid(Masjid masjid) async {
    await init();
    await cancelAll();

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
    }
  }

  static Future<void> cancelAll() async {
    for (final id in _ids.values) {
      await _plugin.cancel(id);
    }
  }
}
