import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/masjid.dart';

/// Everything the alarm system needs, held on the device.
///
/// WHY THIS EXISTS
///
/// Alarms used to be armed only when the Home screen's Firestore stream
/// emitted. That makes a prayer alarm depend on a network round trip: open the
/// app on a bad connection, the stream never emits, nothing gets scheduled, and
/// the user finds out at Fajr.
///
/// Firestore should be the thing that UPDATES prayer times, never the thing
/// that GATES them. The cache is written whenever fresh data arrives and read
/// at every app start, so alarms are armed from local storage before the
/// network is consulted at all.
class CachedSchedule {
  const CachedSchedule({
    required this.masjidId,
    required this.masjidName,
    required this.times,
    this.audioUrl,
    this.savedAt,
  });

  final String masjidId;
  final String masjidName;

  /// Key -> display string, e.g. {'fajr': '5:45 AM'}. Kept as the same strings
  /// the rest of the app uses so there is one parsing path, not two.
  final Map<String, String> times;

  final String? audioUrl;
  final DateTime? savedAt;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'masjidId': masjidId,
        'masjidName': masjidName,
        'times': times,
        'audioUrl': audioUrl,
        'savedAt': (savedAt ?? DateTime.now()).millisecondsSinceEpoch,
      };

  static CachedSchedule fromJson(Map<String, dynamic> j) => CachedSchedule(
        masjidId: j['masjidId'] as String? ?? '',
        masjidName: j['masjidName'] as String? ?? '',
        times: Map<String, String>.from(
          (j['times'] as Map?)?.map(
                (dynamic k, dynamic v) =>
                    MapEntry<String, String>(k.toString(), v.toString()),
              ) ??
              <String, String>{},
        ),
        audioUrl: j['audioUrl'] as String?,
        savedAt: j['savedAt'] == null
            ? null
            : DateTime.fromMillisecondsSinceEpoch(j['savedAt'] as int),
      );

  static CachedSchedule fromMasjid(Masjid m) => CachedSchedule(
        masjidId: m.id,
        masjidName: m.name,
        audioUrl: m.customAzanAudioUrl,
        times: <String, String>{
          'fajr': m.prayerTimes.fajr,
          'dhuhr': m.prayerTimes.dhuhr,
          'asr': m.prayerTimes.asr,
          'maghrib': m.prayerTimes.maghrib,
          'isha': m.prayerTimes.isha,
          'juma': m.prayerTimes.juma,
        },
      );

  /// Identity of the schedule itself. Used to skip pointless rescheduling.
  String get signature => '$masjidId|${times.values.join('|')}';
}

class PrayerScheduleCache {
  PrayerScheduleCache._();

  static const _key = 'cached_prayer_schedule';
  static const _lastFiredPrefix = 'last_fired_';

  static Future<void> save(CachedSchedule schedule) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, json.encode(schedule.toJson()));
  }

  static Future<CachedSchedule?> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return null;
    try {
      return CachedSchedule.fromJson(
          Map<String, dynamic>.from(json.decode(raw)));
    } catch (_) {
      // A corrupt cache must never stop the app starting.
      return null;
    }
  }

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }

  /// Records that a prayer's alarm time has passed, so the app can notice a
  /// prayer whose alarm never actually fired. Silent failure is the worst
  /// property of the current system — nobody knows until they miss a prayer.
  static Future<void> markSeen(String prayerKey, DateTime when) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(
        '$_lastFiredPrefix$prayerKey', when.millisecondsSinceEpoch);
  }

  static Future<DateTime?> lastSeen(String prayerKey) async {
    final prefs = await SharedPreferences.getInstance();
    final v = prefs.getInt('$_lastFiredPrefix$prayerKey');
    return v == null ? null : DateTime.fromMillisecondsSinceEpoch(v);
  }
}
