import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Follower counts per masjid, and a daily count of active devices.
///
/// WHAT THIS DELIBERATELY DOES NOT STORE
///
/// No user records. No names, no phone numbers, no device identifiers, no list
/// of who follows what, and no per-user last-seen timestamp.
///
/// Everything here is a COUNTER. "How many people follow this masjid" and "how
/// many devices opened the app today" are both numbers, and a number cannot
/// identify anyone. That keeps the app outside the whole category of obligations
/// that come with holding personal data — consent, purpose limitation, deletion
/// on request, breach notification — and there is nothing here that could reveal
/// an individual's prayer habits if the database leaked.
///
/// The tradeoff, stated honestly: counts drift. A reinstall counts as a new
/// follower because the app deliberately keeps nothing that would recognise a
/// returning device. Treat the numbers as indicative, not exact. Making them
/// exact would mean identifying devices, which is a bad trade for a prayer app.
class FollowerService {
  FollowerService._();

  static final _masjids = FirebaseFirestore.instance.collection('masjids');
  static final _stats = FirebaseFirestore.instance.collection('stats');

  static const _countedKey = 'followed_masjid_counted';
  static const _lastActiveKey = 'last_active_day';

  /// Moves this device's follow from one masjid to another.
  ///
  /// Called when the selection changes. Decrements the old masjid and increments
  /// the new one in a single batch, so the two can never drift apart because one
  /// write succeeded and the other did not.
  ///
  /// The previously counted masjid is remembered LOCALLY. Without that the app
  /// would have to ask Firestore who this device follows, which would mean
  /// storing that — exactly what this design avoids.
  static Future<void> setFollowed(String? newMasjidId) async {
    String? previous;
    try {
      final prefs = await SharedPreferences.getInstance();
      previous = prefs.getString(_countedKey);
      if (previous == newMasjidId) return; // nothing changed
      if (newMasjidId == null) {
        await prefs.remove(_countedKey);
      } else {
        await prefs.setString(_countedKey, newMasjidId);
      }
    } catch (_) {
      // Without local state this cannot be done safely — a retry would count
      // the same device twice. Better to skip than to inflate.
      return;
    }

    try {
      final batch = FirebaseFirestore.instance.batch();
      if (previous != null && previous.isNotEmpty) {
        batch.set(
          _masjids.doc(previous),
          <String, dynamic>{'followerCount': FieldValue.increment(-1)},
          SetOptions(merge: true),
        );
      }
      if (newMasjidId != null && newMasjidId.isNotEmpty) {
        batch.set(
          _masjids.doc(newMasjidId),
          <String, dynamic>{'followerCount': FieldValue.increment(1)},
          SetOptions(merge: true),
        );
      }
      await batch.commit();
    } catch (_) {
      // Offline or rules-blocked. The local flag is already updated, so this
      // device will not be counted twice later. A missed increment costs one off
      // a count; a double increment would be worse.
    }
  }

  /// Records that a device was active today. Once per device per day.
  ///
  /// THIS IS WHY THERE IS NO PER-USER "LAST LOGIN". The question was how many
  /// people use the app daily, and that is answered by one number per date.
  /// Storing a timestamp against every user would answer the same question while
  /// creating a personal-data record for every one of them.
  ///
  /// It also cannot support following up with inactive users, and neither could
  /// a per-user record: these accounts are anonymous, with no name, phone or
  /// email attached. Contacting anyone would need details the app does not ask
  /// for.
  static Future<void> markActiveToday() async {
    final now = DateTime.now();
    final String today = '${now.year}-'
        '${now.month.toString().padLeft(2, '0')}-'
        '${now.day.toString().padLeft(2, '0')}';

    try {
      final prefs = await SharedPreferences.getInstance();
      if (prefs.getString(_lastActiveKey) == today) return; // already counted
      await prefs.setString(_lastActiveKey, today);
    } catch (_) {
      return;
    }

    try {
      await _stats.doc('daily_$today').set(
        <String, dynamic>{
          'date': today,
          'activeDevices': FieldValue.increment(1),
        },
        SetOptions(merge: true),
      );
    } catch (_) {
      // Analytics must never be able to interfere with the app working.
    }
  }

  /// Live follower count for a masjid, for the admin dashboard.
  static Stream<int> streamFollowerCount(String masjidId) => _masjids
      .doc(masjidId)
      .snapshots()
      .map((doc) {
        final data = doc.data();
        if (data == null) return 0;
        return ((data as Map<String, dynamic>)['followerCount'] as num?)
                ?.toInt() ??
            0;
      });
}
