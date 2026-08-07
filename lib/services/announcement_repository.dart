import 'package:cloud_firestore/cloud_firestore.dart';

/// Something a masjid wants its followers to know: a change of Juma timing, a
/// funeral prayer, a class, a collection.
class Announcement {
  const Announcement({
    required this.id,
    required this.masjidId,
    required this.masjidName,
    required this.message,
    required this.createdAt,
    required this.expiresAt,
  });

  final String id;
  final String masjidId;
  final String masjidName;
  final String message;
  final DateTime createdAt;

  /// When this stops being shown.
  ///
  /// REQUIRED, not optional. An announcement board with no expiry fills up with
  /// last Ramadan's timetable and stops being read — and the one time something
  /// urgent is posted, nobody notices it among the stale ones. The admin picks
  /// a duration; the app hides it afterwards.
  final DateTime expiresAt;

  bool get isActive => DateTime.now().isBefore(expiresAt);

  static Announcement? fromDoc(
      DocumentSnapshot doc, String masjidId, String masjidName) {
    try {
      final d = doc.data() as Map<String, dynamic>?;
      if (d == null) return null;
      final created = d['createdAt'];
      final expires = d['expiresAt'];
      return Announcement(
        id: doc.id,
        masjidId: masjidId,
        masjidName: masjidName,
        message: (d['message'] as String?) ?? '',
        createdAt: created is Timestamp ? created.toDate() : DateTime.now(),
        expiresAt: expires is Timestamp
            ? expires.toDate()
            : DateTime.now().add(const Duration(days: 1)),
      );
    } catch (_) {
      return null;
    }
  }
}

class AnnouncementRepository {
  AnnouncementRepository._();

  static CollectionReference _for(String masjidId) => FirebaseFirestore.instance
      .collection('masjids')
      .doc(masjidId)
      .collection('announcements');

  /// Live announcements for a masjid, newest first, expired ones filtered out.
  ///
  /// Filtered in Dart rather than with a Firestore where-clause on expiresAt,
  /// because that would need a composite index and would silently return
  /// nothing until someone created it in the console. A masjid will never have
  /// enough announcements for this to matter.
  static Stream<List<Announcement>> streamActive(
      String masjidId, String masjidName) {
    return _for(masjidId)
        .orderBy('createdAt', descending: true)
        .limit(20)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => Announcement.fromDoc(d, masjidId, masjidName))
            .whereType<Announcement>()
            .where((a) => a.isActive)
            .toList());
  }

  /// Everything including expired, for the admin who posted them.
  static Stream<List<Announcement>> streamAll(
      String masjidId, String masjidName) {
    return _for(masjidId)
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => Announcement.fromDoc(d, masjidId, masjidName))
            .whereType<Announcement>()
            .toList());
  }

  static Future<void> post({
    required String masjidId,
    required String message,
    required Duration lifetime,
  }) async {
    await _for(masjidId).add(<String, dynamic>{
      'message': message.trim(),
      'createdAt': FieldValue.serverTimestamp(),
      'expiresAt': Timestamp.fromDate(DateTime.now().add(lifetime)),
    });
  }

  static Future<void> delete(String masjidId, String id) =>
      _for(masjidId).doc(id).delete();
}
