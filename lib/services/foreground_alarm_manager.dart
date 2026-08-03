import 'dart:convert';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import '../models/masjid.dart';
import 'prayer_schedule_cache.dart';
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
  /// Refreshes the background service from the device cache.
  ///
  /// The service polls prayer times every 20 seconds and posts the alarm
  /// itself — on phones that block AlarmManager's alarm-clock scheduling, this
  /// is the only path that actually delivers. It was only ever refreshed from
  /// the Home screen, so saving new prayer times left the service watching the
  /// OLD ones. That is why a changed time fired once and then never again.
  /// Queues a test to be delivered by the polling service.
  ///
  /// Deliberately not AlarmManager. On devices where the OS scheduler silently
  /// refuses to deliver, this is the only honest way to test the path that
  /// actually carries prayer alarms.
  static Future<void> queueServiceTest(
      {Duration delay = const Duration(seconds: 60)}) async {
    _configureIfNeeded();
    await FlutterForegroundTask.saveData(
      key: 'service_test_at',
      value: DateTime.now().add(delay).millisecondsSinceEpoch.toString(),
    );
  }

  static Future<void> refreshFromCache() async {
    final CachedSchedule? c = await PrayerScheduleCache.load();
    if (c == null) return;
    await _push(
      masjidName: c.masjidName,
      audioUrl: c.audioUrl,
      times: <String, String>{
        'Fajr': c.times['fajr'] ?? '',
        'Dhuhr': c.times['dhuhr'] ?? '',
        'Asr': c.times['asr'] ?? '',
        'Maghrib': c.times['maghrib'] ?? '',
        'Isha': c.times['isha'] ?? '',
        'Juma (Friday)': c.times['juma'] ?? '',
      },
    );
  }

  static Future<void> _push({
    required String masjidName,
    required String? audioUrl,
    required Map<String, String> times,
  }) async {
    _configureIfNeeded();
    await FlutterForegroundTask.saveData(
      key: 'prayer_times_data',
      value: json.encode(<String, dynamic>{
        'masjidName': masjidName,
        'audioUrl': audioUrl,
        'times': times,
      }),
    );

    final isRunning = await FlutterForegroundTask.isRunningService;
    try {
      if (!isRunning) {
        await FlutterForegroundTask.startService(
          notificationTitle: 'Masjid Namaz Alarm is active',
          notificationText: 'Watching prayer times for $masjidName',
          // The only stop control that is ALWAYS reachable. The ringing
          // screen's button only exists if Android launched that screen,
          // which it refuses to do exactly when the phone is locked — so
          // without this the azan could play with no way to stop it.
          notificationButtons: [
            const NotificationButton(id: 'stop_azan', text: 'Stop azan'),
          ],
          callback: startForegroundTaskCallback,
        );
      } else {
        await FlutterForegroundTask.updateService(
          notificationTitle: 'Masjid Namaz Alarm is active',
          notificationText: 'Watching prayer times for $masjidName',
        );
      }
    } catch (e) {
      throw Exception('Foreground service failed to start: $e');
    }
  }

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
    try {
      if (!isRunning) {
        await FlutterForegroundTask.startService(
          notificationTitle: 'Masjid Namaz Alarm is active',
          notificationText: 'Watching prayer times for ${masjid.name}',
          notificationButtons: [
            const NotificationButton(id: 'stop_azan', text: 'Stop azan'),
          ],
          callback: startForegroundTaskCallback,
        );
      } else {
        await FlutterForegroundTask.updateService(
          notificationTitle: 'Masjid Namaz Alarm is active',
          notificationText: 'Watching prayer times for ${masjid.name}',
        );
      }
    } catch (e) {
      throw Exception('Foreground service failed to start: $e');
    }
  }

  static Future<bool> isRunning() async {
    // Starting a foreground service is async at the OS level - checking
    // immediately after calling startService() can return false even
    // though it's actually starting up. Give it a moment, then check.
    await Future.delayed(const Duration(milliseconds: 800));
    return await FlutterForegroundTask.isRunningService;
  }

  static Future<void> stop() async {
    await FlutterForegroundTask.stopService();
  }
}
