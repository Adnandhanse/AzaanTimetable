import 'dart:convert';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import '../models/masjid.dart';
import 'foreground_alarm_service.dart';

/// Controls the persistent background service that reliably checks
/// prayer times, even on phones (like Samsung) that aggressively kill
/// simple scheduled alarms.
class ForegroundAlarmManager {
  static bool _configured = false;

  static void _configureIfNeeded() {
    if (_configured) return;
    FlutterForegroundTask.init(
      androidNotificationOptions: AndroidNotificationOptions(
        channelId: 'masjid_alarm_service',
        channelName: 'Masjid Alarm - Running',
        channelDescription: 'Keeps checking prayer times so alarms fire reliably.',
        channelImportance: NotificationChannelImportance.LOW,
        priority: NotificationPriority.LOW,
      ),
      iosNotificationOptions: const IOSNotificationOptions(),
      foregroundTaskOptions: ForegroundTaskOptions(
        eventAction: ForegroundTaskEventAction.repeat(20000), // check every 20 seconds
        autoRunOnBoot: true,
        allowWakeLock: true,
        allowWifiLock: false,
      ),
    );
    _configured = true;
  }

  /// Pushes the current masjid's prayer times + Azan audio URL into the
  /// background service's storage, and (re)starts the service so it
  /// picks up the new data immediately.
  static Future<void> startOrUpdate(Masjid masjid) async {
    _configureIfNeeded();

    final data = {
      'masjidName': masjid.name,
      'audioUrl': masjid.customAzanAudioUrl,
      'times': {
        'Fajr': masjid.prayerTimes.fajr,
        'Dhuhr': masjid.prayerTimes.dhuhr,
        'Asr': masjid.prayerTimes.asr,
        'Maghrib': masjid.prayerTimes.maghrib,
        'Isha': masjid.prayerTimes.isha,
        'Juma (Friday)': masjid.prayerTimes.juma,
      },
    };
    await FlutterForegroundTask.saveData(key: 'prayer_times_data', value: json.encode(data));

    final isRunning = await FlutterForegroundTask.isRunningService;
    if (!isRunning) {
      await FlutterForegroundTask.startService(
        notificationTitle: 'Masjid Namaz Alarm is active',
        notificationText: 'Watching prayer times for ${masjid.name}',
        callback: startForegroundTaskCallback,
      );
    } else {
      await FlutterForegroundTask.updateService(
        notificationTitle: 'Masjid Namaz Alarm is active',
        notificationText: 'Watching prayer times for ${masjid.name}',
      );
    }
  }

  static Future<void> stop() async {
    await FlutterForegroundTask.stopService();
  }
}
