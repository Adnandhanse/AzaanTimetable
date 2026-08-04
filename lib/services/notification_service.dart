import 'dart:convert';
import 'dart:ui' show DartPluginRegistrant;

import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:android_intent_plus/android_intent.dart';
import '../models/masjid.dart';
import 'alarm_event_log.dart';
import 'foreground_alarm_manager.dart';
import 'notification_channels.dart';
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
  static const _channelId = NotificationChannels.azan;
  static const _channelName = NotificationChannels.name;

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
  /// Channel carrying the bundled azan.
  static const String channelIdAzan = _channelId;

  /// Fallback channel using the system alert sound. A separate id is required:
  /// a channel's sound is fixed the moment Android creates it.
  static const String channelIdPlain = NotificationChannels.plain;

  static AndroidNotificationDetails alarmChannel({bool withAzan = true}) =>
      AndroidNotificationDetails(
        withAzan ? channelIdAzan : channelIdPlain,
        _channelName,
        channelDescription: withAzan
            ? 'Plays the azan when it is time for prayer'
            : 'Alerts you when it is time for prayer',
        importance: Importance.max,
        priority: Priority.high,
        category: AndroidNotificationCategory.alarm,
        fullScreenIntent: true,
        playSound: true,
        sound: withAzan
            ? const RawResourceAndroidNotificationSound('azan')
            : null,
        audioAttributesUsage: AudioAttributesUsage.alarm,
        autoCancel: true,
      );

  /// What happened on the last scheduling run.
  ///
  /// Scheduling used to fail silently: cancelAll() ran, something threw,
  /// nothing was re-armed, and there was no trace of it anywhere. An alarm app
  /// must never lose its alarms quietly.
  static const _diagKey = 'alarm_last_diagnostics';

  static const _useAzanKey = 'alarm_use_azan_sound';
  static const _useAlarmClockKey = 'alarm_use_alarmclock_mode';

  /// Whether to use AlarmManager's alarm-clock scheduling.
  ///
  /// Defaults to FALSE. It is the strongest API Android exposes, but some ROMs
  /// accept the call and never deliver, without error. exactAllowWhileIdle is
  /// less privileged and more honest about failing.
  static Future<bool> useAlarmClockMode() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_useAlarmClockKey) ?? false;
    } catch (_) {
      return false;
    }
  }

  static Future<void> setUseAlarmClockMode(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_useAlarmClockKey, value);
  }

  /// Whether to attach the bundled azan to the notification CHANNEL.
  ///
  /// DEFAULTS TO FALSE, deliberately.
  ///
  /// The channel sound is an Android raw resource, copied into res/raw by the
  /// CI workflow. If that copy has not happened, the sound URI is invalid —
  /// and while a notification posted from the app still appears (silently), a
  /// SCHEDULED one is rebuilt by a background receiver that throws on the bad
  /// resource, so nothing appears at all.
  ///
  /// That is a catastrophic failure mode for an optional feature: a missing
  /// sound file silently disables every prayer alarm. The alarm must never
  /// depend on it.
  ///
  /// With this off, notifications use the system alarm sound, which cannot
  /// fail, and the azan itself is played by the ringing screen from the
  /// bundled Flutter asset — which ships with the app as a matter of course.
  static Future<bool> useAzanSound() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_useAzanKey) ?? false;
    } catch (_) {
      return false;
    }
  }

  static Future<void> setUseAzanSound(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_useAzanKey, value);
    // Create the channel now, so the very next notification can use it.
    if (value) await _createChannels();
  }

  /// Creates both channels up front.
  ///
  /// Previously channels were created implicitly by the first notification.
  /// That is fragile: it happens once, invisibly, and whatever state it
  /// captures is permanent. Creating them explicitly at startup makes the
  /// moment of creation something we control.
  /// Tells the background service to stop the azan. The player lives in that
  /// isolate; this one cannot touch it directly.
  static void _stopAzanEverywhere() {
    try {
      FlutterForegroundTask.sendDataToTask('stop_azan');
    } catch (_) {}
  }

  static Future<void> _createChannels() async {
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (android == null) return;

    // The plain channel always exists. The azan channel is only created once
    // the user opts in — creating it eagerly would bake a possibly-invalid
    // sound URI into a channel permanently, and Android never lets you change
    // a channel's sound afterwards.
    if (await useAzanSound()) {
      try {
        await android.createNotificationChannel(const AndroidNotificationChannel(
          _channelId,
          _channelName,
          description: 'Plays the azan when it is time for prayer',
          importance: Importance.max,
          playSound: true,
          sound: RawResourceAndroidNotificationSound('azan'),
          audioAttributesUsage: AudioAttributesUsage.alarm,
        ));
      } catch (_) {}
    }

    try {
      await android.createNotificationChannel(const AndroidNotificationChannel(
        channelIdPlain,
        'Prayer Alarms (default sound)',
        description: 'Alerts you when it is time for prayer',
        importance: Importance.max,
        playSound: true,
        audioAttributesUsage: AudioAttributesUsage.alarm,
      ));
    } catch (_) {}
  }

  /// Posts a notification immediately, bypassing AlarmManager entirely.
  ///
  /// This is the single most useful diagnostic in the app. If this shows
  /// nothing, the problem is the CHANNEL and no scheduling fix will ever help.
  /// If it shows, the channel is fine and the problem is scheduling or the
  /// phone freezing the app. Nothing else separates those two.
  static Future<void> showNotificationNow({bool? withAzan}) async {
    await init();
    final bool azan = withAzan ?? await useAzanSound();
    await _plugin.show(
      997,
      'Immediate test',
      azan
          ? 'Posted to the azan channel. You should hear the azan.'
          : 'Posted to the default-sound channel.',
      NotificationDetails(android: alarmChannel(withAzan: azan)),
      payload: 'Test|||Test|||',
    );
  }

  static Future<void> _writeDiagnostics(Map<String, dynamic> d) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      d['at'] = DateTime.now().millisecondsSinceEpoch;
      await prefs.setString(_diagKey, json.encode(d));
    } catch (_) {}
  }

  static Future<Map<String, dynamic>?> lastDiagnostics() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_diagKey);
      return raw == null
          ? null
          : Map<String, dynamic>.from(json.decode(raw));
    } catch (_) {
      return null;
    }
  }

  /// Schedules one alarm, degrading rather than failing.
  ///
  ///   1. alarmClock + bundled azan
  ///   2. alarmClock + default alert sound   (bad or missing azan resource)
  ///   3. exactAllowWhileIdle + default      (alarmClock refused by the OS)
  ///
  /// An alarm that rings with the wrong sound beats one that does not ring.
  /// Returns which tier worked, or null if all three were refused.
  static Future<String?> _scheduleWithFallback({
    required int id,
    required String title,
    required String body,
    required tz.TZDateTime when,
    required String? payload,
    DateTimeComponents? match,
  }) async {
    final bool azanWanted = await useAzanSound();
    final bool useAlarmClock = await useAlarmClockMode();

    // ORDER MATTERS, AND alarmClock IS NO LONGER FIRST BY DEFAULT.
    //
    // setAlarmClock is the strongest API on paper, but several Android ROMs
    // accept the call and then never deliver. It does not throw, so a
    // try/catch ladder cannot detect it — scheduling reports success and the
    // alarm silently never fires. exactAllowWhileIdle is slightly weaker on
    // paper and actually delivers, which wins.
    final AndroidScheduleMode primary = useAlarmClock
        ? AndroidScheduleMode.alarmClock
        : AndroidScheduleMode.exactAllowWhileIdle;
    final AndroidScheduleMode secondary = useAlarmClock
        ? AndroidScheduleMode.exactAllowWhileIdle
        : AndroidScheduleMode.alarmClock;

    final attempts = <(String, bool, AndroidScheduleMode)>[
      if (azanWanted) ('azan + ${primary.name}', true, primary),
      ('default sound + ${primary.name}', false, primary),
      ('default sound + ${secondary.name}', false, secondary),
    ];

    for (final (String label, bool azan, AndroidScheduleMode mode) in attempts) {
      try {
        await _plugin.zonedSchedule(
          id,
          title,
          body,
          when,
          NotificationDetails(android: alarmChannel(withAzan: azan)),
          androidScheduleMode: mode,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
          matchDateTimeComponents: match,
          payload: payload,
        );
        return label;
      } catch (_) {
        // fall through to the next tier
      }
    }
    return null;
  }

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
        if (response.actionId == 'stop_azan') {
          _stopAzanEverywhere();
          return;
        }
        onTapPayload?.call(response.payload);
      },
      // Taps that arrive while the app is not running come here instead.
      // Without this, the Stop button on a prayer notification would do
      // nothing in exactly the case that matters — phone locked, app closed.
      onDidReceiveBackgroundNotificationResponse: notificationActionBackground,
    );

    // Remove the pre-azan channel. Anyone upgrading already has it, it has no
    // sound attached, and leaving it behind means a stale duplicate sitting in
    // the phone's notification settings.
    // Remove every channel this app has ever used except the current pair.
    // A channel created with a bad sound URI keeps that URI forever and
    // silently swallows notifications, so old ids must not linger.
    for (final String dead in NotificationChannels.retired) {
      try {
        await _plugin
            .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin>()
            ?.deleteNotificationChannel(dead);
      } catch (_) {}
    }

    await _createChannels();

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

  /// Exact alarms have NO system dialog — Android only offers a settings screen
  /// for this one. On Android 14+ it is usually already granted, because the
  /// manifest declares USE_EXACT_ALARM, which the OS grants automatically to
  /// apps whose core purpose is alarms.
  static Future<void> openExactAlarmSettings() async {
    // permission_handler first: on Android 14+ this can return granted without
    // showing anything at all.
    try {
      final status = await Permission.scheduleExactAlarm.request();
      if (status.isGranted) return;
    } catch (_) {}

    try {
      // No package name hardcoded. It was com.example.masjid_alarm_app, which
      // would break silently the moment the package is renamed for the Play
      // Store.
      const intent = AndroidIntent(
        action: 'android.settings.REQUEST_SCHEDULE_EXACT_ALARM',
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
  /// Requests everything the alarm system needs, in one pass.
  ///
  /// Asked all at once at first launch rather than scattered through the app.
  /// A prayer alarm that is missing one permission is not partly working, it
  /// is broken, so there is no point deferring any of them.
  /// Stops the setup wizard reappearing. Only the user sets this.
  static Future<void> setSetupDismissed(bool value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('alarm_setup_dismissed_v1', value);
    } catch (_) {}
  }

  static Future<Map<String, bool>> requestAllPermissions() async {
    await init();
    try {
      await Permission.notification.request();
    } catch (_) {}
    try {
      await Permission.scheduleExactAlarm.request();
    } catch (_) {}
    try {
      await Permission.ignoreBatteryOptimizations.request();
    } catch (_) {}
    return alarmHealth();
  }

  static Future<Map<String, bool>> alarmHealth() async {
    return <String, bool>{
      'Notifications allowed': await Permission.notification.isGranted,
      'Alarms & reminders': await Permission.scheduleExactAlarm.isGranted,
      'Battery unrestricted': await hasBatteryExemption(),
    };
  }

  /// Asks for the battery exemption with the SYSTEM DIALOG, the same kind of
  /// prompt as the notification permission — not a settings page.
  ///
  /// The old version launched REQUEST_IGNORE_BATTERY_OPTIMIZATIONS by intent
  /// with the package name HARDCODED as com.example.masjid_alarm_app. Two
  /// problems: it dropped the user onto a screen instead of a one-tap dialog,
  /// and it would silently stop working the moment the package is renamed for
  /// the Play Store — which is still on the to-do list.
  ///
  /// permission_handler needs no package name and shows the real dialog. The
  /// intent stays as a fallback for devices that refuse the dialog.
  static Future<void> requestIgnoreBatteryOptimizations() async {
    try {
      final status = await Permission.ignoreBatteryOptimizations.request();
      if (status.isGranted) return;
    } catch (_) {}

    try {
      const intent = AndroidIntent(
        action: 'android.settings.IGNORE_BATTERY_OPTIMIZATION_SETTINGS',
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

  static Future<String?> _scheduleDaily({
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
      // Juma used to be scheduled with DateTimeComponents.time like the other
      // five, which made the Friday prayer ring every single day.
      while (scheduled.weekday != DateTime.friday || !scheduled.isAfter(now)) {
        scheduled = scheduled.add(const Duration(days: 1));
      }
    } else if (!scheduled.isAfter(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }

    return _scheduleWithFallback(
      id: id,
      title: title,
      body: body,
      when: scheduled,
      payload: payload,
      match: fridayOnly
          ? DateTimeComponents.dayOfWeekAndTime
          : DateTimeComponents.time,
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
    if (schedule == null) {
      await _writeDiagnostics(
          <String, dynamic>{'result': 'no cached schedule yet', 'scheduled': 0});
      return <String>['No cached schedule yet'];
    }

    await cancelAll();
    final scheduledSummary = <String>[];
    final nextFires = <String>[];
    final failures = <String>[];
    String? modeUsed;

    for (final entry in _labels.entries) {
      final key = entry.key;
      final label = entry.value;
      final timeStr = schedule.times[key];
      if (timeStr == null) continue;
      final dt = _parseTimeToday(timeStr);
      if (dt == null) continue;

      // One prayer failing must not abort the rest. Previously a single throw
      // left every alarm cancelled and nothing rescheduled — which is exactly
      // how the app went from "one notification" to total silence.
      String? tier;
      try {
        tier = await _scheduleDaily(
          id: _ids[key]!,
          title: '$label - ${schedule.masjidName}',
          body: "It's time for $label prayer.",
          timeToday: dt,
          payload: _buildPayload(label, schedule.masjidName, schedule.audioUrl),
          fridayOnly: key == 'juma',
        );
      } catch (_) {
        tier = null;
      }

      if (tier == null) {
        failures.add(label);
      } else {
        modeUsed ??= tier;
        scheduledSummary
            .add('$label: $timeStr${key == 'juma' ? ' (Fridays only)' : ''}');
        nextFires.add('$label -> ${_describeNext(dt, key == 'juma')}');
      }

      // REDUNDANCY. The repeating alarm above relies on the plugin re-arming
      // itself after each firing; if that link breaks, everything after today
      // is lost silently. These explicit one-shots cover the next few days on
      // their own, and are re-armed every time the app opens.
      if (key != 'juma') {
        await _scheduleExtraDays(key: key, label: label, base: dt,
            masjidName: schedule.masjidName, audioUrl: schedule.audioUrl);
      }
    }

    // Keep the polling service's copy of the times in step. It is only ever
    // refreshed here and from Home; forgetting it is what left the service
    // watching yesterday's times.
    try {
      await ForegroundAlarmManager.refreshFromCache();
    } catch (_) {}

    await _writeDiagnostics(<String, dynamic>{
      'result': failures.isEmpty ? 'ok' : 'partial',
      'scheduled': scheduledSummary.length,
      'failed': failures,
      'mode': modeUsed ?? 'none',
      'masjid': schedule.masjidName,
      'next': nextFires,
    });

    await AlarmEventLog.add(
      'alarms armed',
      detail: '${scheduledSummary.length} set via ${modeUsed ?? 'none'}'
          '${failures.isEmpty ? '' : ', FAILED: ${failures.join('/')}'}'
          '${nextFires.isEmpty ? '' : ' | ${nextFires.join(', ')}'}',
    );

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

    // The important line in the whole log. If alarms are being wiped between
    // app opens, this is where it shows up.
    await AlarmEventLog.add('alarms MISSING, repairing',
        detail: '${missing.length} of ${expected.length} gone');

    // Re-arm the whole set rather than patching individual ids — cheap, and it
    // avoids a half-armed state if several went missing at once.
    await scheduleFromCache(schedule);
    return true;
  }

  /// Fires a real alarm-path notification after [delay]. This is the only
  /// honest way for someone to find out whether alarms work on THEIR phone,
  /// rather than discovering it at Fajr.
  /// Fires a real alarm down the exact path a prayer uses. Returns which tier
  /// worked, or null if the system refused all three — that null is the
  /// diagnosis.
  static Future<String?> scheduleTestAlarm(
      {Duration delay = const Duration(seconds: 60)}) async {
    await init();
    final tier = await _scheduleWithFallback(
      id: 998,
      title: 'Test alarm',
      body: 'If you are seeing this, alarms work on this phone.',
      when: tz.TZDateTime.now(tz.local).add(delay),
      payload: 'Test|||Test|||',
    );
    await _writeDiagnostics(<String, dynamic>{
      'result':
          tier == null ? 'test alarm REFUSED by the system' : 'test alarm armed',
      'mode': tier ?? 'none',
      'scheduled': tier == null ? 0 : 1,
    });
    await AlarmEventLog.add(
      tier == null ? 'test alarm REFUSED' : 'test alarm armed',
      detail: tier ?? 'all scheduling modes refused',
    );
    return tier;
  }

  static Future<void> cancelTestAlarm() async => _plugin.cancel(998);

  /// Base id for the redundant one-shot alarms. Kept well clear of the
  /// repeating ids (100-105) and the test ids (997/998).
  static const int _extraBase = 300;
  static const int _extraDays = 3;

  /// Explicit one-shot alarms for the next few days, independent of the
  /// repeating alarm. If the plugin's re-arm-after-firing ever fails, these
  /// still ring, and every app open pushes the window forward again.
  static Future<void> _scheduleExtraDays({
    required String key,
    required String label,
    required DateTime base,
    required String masjidName,
    required String? audioUrl,
  }) async {
    final int slot = _ids[key]! - 100; // 0..5
    final now = tz.TZDateTime.now(tz.local);

    for (int day = 1; day <= _extraDays; day++) {
      var when = tz.TZDateTime.from(base, tz.local).add(Duration(days: day));
      if (!when.isAfter(now)) continue;
      await _scheduleWithFallback(
        id: _extraBase + slot * 10 + day,
        title: '$label - $masjidName',
        body: "It's time for $label prayer.",
        when: when,
        payload: _buildPayload(label, masjidName, audioUrl),
      );
    }
  }

  static String _describeNext(DateTime timeToday, bool fridayOnly) {
    final now = tz.TZDateTime.now(tz.local);
    var when = tz.TZDateTime.from(timeToday, tz.local);
    if (fridayOnly) {
      while (when.weekday != DateTime.friday || !when.isAfter(now)) {
        when = when.add(const Duration(days: 1));
      }
    } else if (!when.isAfter(now)) {
      when = when.add(const Duration(days: 1));
    }
    final bool today = when.day == now.day && when.month == now.month;
    final String hh = when.hour.toString().padLeft(2, '0');
    final String mm = when.minute.toString().padLeft(2, '0');
    // Saying "tomorrow" out loud matters: setting a time that has already
    // passed today is not a bug, but it looks exactly like one.
    return today ? 'today $hh:$mm' : 'tomorrow $hh:$mm';
  }

  static Future<void> cancelAll() async {
    for (final id in _ids.values) {
      await _plugin.cancel(id);
    }
    // The redundant one-shots too, or old times linger alongside new ones.
    for (int slot = 0; slot < 6; slot++) {
      for (int day = 1; day <= _extraDays; day++) {
        await _plugin.cancel(_extraBase + slot * 10 + day);
      }
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
      NotificationDetails(android: alarmChannel()),
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

/// Handles notification actions when the app is not running.
///
/// Must be top level and marked as an entry point, or the compiler drops it in
/// release builds and Stop does nothing when the phone is locked — the one
/// situation it exists for.
@pragma('vm:entry-point')
void notificationActionBackground(NotificationResponse response) {
  if (response.actionId != 'stop_azan') return;
  try {
    // Plugins are not registered by default in a background isolate.
    DartPluginRegistrant.ensureInitialized();
  } catch (_) {}
  try {
    FlutterForegroundTask.sendDataToTask('stop_azan');
  } catch (_) {}
}
