import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:android_intent_plus/android_intent.dart';
import '../models/masjid.dart';
import 'prayer_schedule_cache.dart';

/// Schedules local notifications that fire daily at each prayer time for
/// the masjid a user is following. Uses a full-screen alarm-style
/// notification so tapping (or the phone unlocking to it) opens the app
/// directly to a ringing screen that plays the masjid's uploaded Azan
/// audio, similar to how a normal alarm clock app behaves.
class NotificationService {
  static final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  static bool _initialized = false;

  /// NEW CHANNEL ID ON PURPOSE.
  ///
  /// A notification channel's sound is fixed the moment Android creates it and
  /// cannot be changed afterwards — editing the old channel would do nothing on
  /// any phone that already had the app. Bumping the id creates a fresh channel
  /// carrying the azan. If you ever change the sound again, bump it again.
  static const _channelId = 'prayer_alarm_azan_v1';
  static const _channelName = 'Prayer Time Alarms';

  /// The azan plays as the NOTIFICATION'S OWN SOUND, not from the ringing
  /// screen.
  ///
  /// Previously the sound depended on the full-screen intent launching an
  /// activity, and when Android blocked that — Android 14 restrictions, OEM
  /// background limits, or the app having been killed — you got a default
  /// chime and no azan. A channel sound is played by the OS itself, so it works
  /// whether or not the app can start anything.
  ///
  /// usage: alarm means it plays at ALARM volume and follows alarm rules rather
  /// than notification ones, which is what a prayer call should do.
  static AndroidNotificationDetails _alarmChannel() =>
      const AndroidNotificationDetails(
        _channelId,
        _channelName,
        channelDescription: 'Plays the azan when it is time for prayer',
        importance: Importance.max,
        priority: Priority.high,
        category: AndroidNotificationCategory.alarm,
        fullScreenIntent: true,
        playSound: true,
        sound: RawResourceAndroidNotificationSound('azan'),
        audioAttributesUsage: AudioAttributesUsage.alarm,
        // The azan runs over three minutes; without this Android can cut it
        // short when the notification is auto-dismissed.
        ongoing: false,
        autoCancel: true,
      );

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

  // Some devices/plugins report older, retired IANA timezone names that
  // aren't in the bundled tz database anymore - map the common ones to
  // their current equivalents.
  static const _legacyTimezoneAliases = {
    'Asia/Calcutta': 'Asia/Kolkata',
    'Asia/Katmandu': 'Asia/Kathmandu',
    'Asia/Saigon': 'Asia/Ho_Chi_Minh',
    'Asia/Rangoon': 'Asia/Yangon',
  };

  static Future<void> init({void Function(String? payload)? onTapPayload}) async {
    if (_initialized) return;
    tzdata.initializeTimeZones();

    try {
      var deviceTimeZone = await FlutterTimezone.getLocalTimezone();
      final resolvedName = _legacyTimezoneAliases[deviceTimeZone] ?? deviceTimeZone;
      tz.setLocalLocation(tz.getLocation(resolvedName));
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

    // Remove the pre-azan channel. Anyone upgrading already has it, it has no
    // sound attached, and leaving it behind means a stale duplicate sitting in
    // the phone's notification settings.
    try {
      await _plugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.deleteNotificationChannel('prayer_times_channel');
    } catch (_) {}

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

  /// Triggers Android's own native system dialog asking the user to
  /// exempt this app from battery optimization - bypasses hunting through
  /// Samsung's (or any OEM's) reorganized Settings menus entirely, since
  /// this is a stock Android dialog the manufacturer can't hide or rename.
  /// Whether this app is exempt from battery optimisation.
  ///
  /// This is the single biggest cause of "sometimes the alarm comes, sometimes
  /// it doesn't" on Xiaomi, Realme, Oppo, Vivo and Samsung handsets. Without
  /// the exemption the OS is free to freeze the app, and a frozen app's
  /// alarms simply do not fire.
  static Future<bool> hasBatteryExemption() async {
    try {
      return await Permission.ignoreBatteryOptimizations.isGranted;
    } catch (_) {
      return true; // unknown - do not nag the user over a failed check
    }
  }

  /// One call, everything that has to be true for an alarm to fire.
  /// Anything false here explains a missed prayer.
  static Future<Map<String, bool>> alarmHealth() async {
    return <String, bool>{
      'Notifications allowed': await Permission.notification.isGranted,
      'Alarms & reminders': await Permission.scheduleExactAlarm.isGranted,
      'Battery unrestricted': await hasBatteryExemption(),
    };
  }

  static Future<void> requestIgnoreBatteryOptimizations() async {
    try {
      const intent = AndroidIntent(
        action: 'android.settings.REQUEST_IGNORE_BATTERY_OPTIMIZATIONS',
        data: 'package:com.example.masjid_alarm_app',
      );
      await intent.launch();
    } catch (_) {
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
    bool fridayOnly = false,
  }) async {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime.from(timeToday, tz.local);

    if (fridayOnly) {
      // BUG FIX: Juma was scheduled with DateTimeComponents.time like every
      // other prayer, which made the Friday prayer alarm ring EVERY DAY.
      // Walk forward to the next Friday that is still in the future, and
      // match on day-of-week as well as time.
      while (scheduled.weekday != DateTime.friday || !scheduled.isAfter(now)) {
        scheduled = scheduled.add(const Duration(days: 1));
      }
    } else if (!scheduled.isAfter(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }

    await _plugin.zonedSchedule(
      id,
      title,
      body,
      scheduled,
      NotificationDetails(android: _alarmChannel()),
      // HIGHEST TIER ANDROID OFFERS.
      //
      // exactAllowWhileIdle is an exact alarm that doze *permits*; alarmClock
      // is the primitive the OS uses for the user's own alarm clock. It is
      // exempt from doze, survives battery optimisation far better, and is the
      // most reliable scheduling call available to a third-party app.
      //
      // The cost: the phone shows an alarm icon in the status bar and reports
      // the next prayer as the device's next alarm. For a prayer alarm app
      // that is arguably correct behaviour rather than a side effect.
      androidScheduleMode: AndroidScheduleMode.alarmClock,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: fridayOnly
          ? DateTimeComponents.dayOfWeekAndTime
          : DateTimeComponents.time,
      payload: payload,
    );
  }

  static const _labels = {
    'fajr': 'Fajr',
    'dhuhr': 'Dhuhr',
    'asr': 'Asr',
    'maghrib': 'Maghrib',
    'isha': 'Isha',
    'juma': 'Juma (Friday)',
  };

  /// Arms alarms from fresh Firestore data, and caches that data so the next
  /// app start can arm without any network at all.
  static Future<List<String>> scheduleForMasjid(Masjid masjid) async {
    final cached = CachedSchedule.fromMasjid(masjid);
    await PrayerScheduleCache.save(cached);
    return scheduleFromCache(cached);
  }

  /// Arms alarms from device storage. This is the path used at app start,
  /// before Firestore is consulted — Firestore updates prayer times, it does
  /// not gate them.
  static Future<List<String>> scheduleFromCache([CachedSchedule? given]) async {
    await init();

    final CachedSchedule? schedule = given ?? await PrayerScheduleCache.load();
    if (schedule == null) return <String>['No cached schedule yet'];

    await cancelAll();
    final scheduledSummary = <String>[];

    for (final entry in _labels.entries) {
      final key = entry.key;
      final label = entry.value;
      final timeStr = schedule.times[key];
      if (timeStr == null) continue;
      final dt = _parseTimeToday(timeStr);
      if (dt == null) continue;

      await _scheduleDaily(
        id: _ids[key]!,
        title: '$label - ${schedule.masjidName}',
        body: "It's time for $label prayer.",
        timeToday: dt,
        payload:
            _buildPayload(label, schedule.masjidName, schedule.audioUrl),
        fridayOnly: key == 'juma',
      );
      scheduledSummary
          .add('$label: $timeStr${key == 'juma' ? ' (Fridays only)' : ''}');
    }
    return scheduledSummary;
  }

  /// Checks what the OS actually still holds and re-arms anything missing.
  ///
  /// The app used to schedule and hope. Alarms disappear for reasons outside
  /// the app's control — a force-stop, an OEM cleanup, a reboot the boot
  /// receiver did not survive. Verifying on every app start turns a silent
  /// failure into a self-repair.
  ///
  /// Returns true if it had to repair anything.
  static Future<bool> verifyAndRepair() async {
    await init();
    final CachedSchedule? schedule = await PrayerScheduleCache.load();
    if (schedule == null) return false;

    final pending = await _plugin.pendingNotificationRequests();
    final pendingIds = pending.map((p) => p.id).toSet();

    final expected = <int>{};
    for (final entry in _labels.entries) {
      final t = schedule.times[entry.key];
      if (t == null) continue;
      if (_parseTimeToday(t) == null) continue;
      expected.add(_ids[entry.key]!);
    }

    final missing = expected.difference(pendingIds);
    if (missing.isEmpty) return false;

    // Re-arm the whole set rather than patching individual ids — cheap, and it
    // avoids a half-armed state if several went missing at once.
    await scheduleFromCache(schedule);
    return true;
  }

  /// Fires a real alarm-path notification after [delay]. This is the only
  /// honest way for someone to find out whether alarms work on THEIR phone,
  /// rather than discovering it at Fajr.
  static Future<void> scheduleTestAlarm(
      {Duration delay = const Duration(seconds: 60)}) async {
    await init();
    final when = tz.TZDateTime.now(tz.local).add(delay);
    await _plugin.zonedSchedule(
      998,
      'Test alarm',
      'If you are seeing this, alarms work on this phone.',
      when,
      NotificationDetails(android: _alarmChannel()),
      androidScheduleMode: AndroidScheduleMode.alarmClock,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      payload: 'Test|||Test|||',
    );
  }

  static Future<void> cancelTestAlarm() async => _plugin.cancel(998);

  static Future<void> cancelAll() async {
    for (final id in _ids.values) {
      await _plugin.cancel(id);
    }
  }

  /// Shows a notification RIGHT NOW, with no scheduling/timing involved
  /// at all - isolates "can this phone display our notifications" from
  /// "is the scheduled alarm timing correct".
  static Future<void> showTestNotificationNow() async {
    await init();
    await _plugin.show(
      999,
      'Test Notification',
      'If you see this, notifications work on this phone.',
      NotificationDetails(android: _alarmChannel()),
      payload: 'Test|||Test Masjid|||',
    );
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
