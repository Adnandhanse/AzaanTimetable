import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'auth_service.dart';

/// Which masjid the user follows.
///
/// DEVICE FIRST, FIRESTORE SECOND.
///
/// This used to live only in Firestore, keyed by the anonymous Firebase Auth
/// UID. That made a plain device restart lose the selection, for any of three
/// reasons:
///
///   * Auth had not restored yet, so currentUser was null and the lookup
///     returned nothing — the app then asked the user to pick a masjid again.
///   * A fresh anonymous account was created, giving a new UID, orphaning the
///     old document permanently.
///   * No network on boot, so the read simply failed.
///
/// Which masjid I follow is a device preference. It should not depend on a
/// login or a network round trip. It is now written to local storage first and
/// read from there first; Firestore is kept in sync so the choice can follow
/// the user to a new device, but it is never what the app waits on.
class UserRepository {
  static const _localKey = 'selected_masjid_id';

  static CollectionReference get _collection =>
      FirebaseFirestore.instance.collection('users');

  static Future<void> setSelectedMasjid(String masjidId) async {
    // Local write first, and unconditionally. If the network or auth is
    // unavailable the choice must still survive a restart.
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_localKey, masjidId);
    } catch (_) {}

    // Then Firestore, best effort. A failure here costs cross-device sync,
    // not the selection itself.
    try {
      final uid = AuthService.currentUser?.uid;
      if (uid == null) return;
      await _collection.doc(uid).set(
        {'selectedMasjidId': masjidId},
        SetOptions(merge: true),
      );
    } catch (_) {}
  }

  static Future<String?> getSelectedMasjidId() async {
    // Local first. Instant, works offline, works before auth restores.
    try {
      final prefs = await SharedPreferences.getInstance();
      final local = prefs.getString(_localKey);
      if (local != null && local.isNotEmpty) return local;
    } catch (_) {}

    // Nothing stored locally — a fresh install, or an upgrade from a build
    // that only ever wrote to Firestore. Recover from the server and cache it,
    // so this path runs once and never again.
    try {
      final uid = AuthService.currentUser?.uid;
      if (uid == null) return null;
      final doc = await _collection.doc(uid).get();
      if (!doc.exists) return null;
      final data = doc.data() as Map<String, dynamic>?;
      final remote = data?['selectedMasjidId'] as String?;
      if (remote != null && remote.isNotEmpty) {
        try {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString(_localKey, remote);
        } catch (_) {}
      }
      return remote;
    } catch (_) {
      return null;
    }
  }

  /// Used when the user deliberately clears their choice. Nothing else should
  /// remove the local copy — that is what caused the original problem.
  static Future<void> clearSelectedMasjid() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_localKey);
    } catch (_) {}
  }
}
