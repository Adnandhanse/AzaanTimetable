import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/masjid.dart';

/// Handles all reads/writes to the "masjids" collection in Firestore.
/// This is the single source of truth for masjid data - replacing the
/// old in-memory mock_masjids.dart list. Every device now sees the same
/// data, and it persists across app restarts.
class MasjidRepository {
  static final CollectionReference _collection =
      FirebaseFirestore.instance.collection('masjids');

  /// Live stream of every masjid - used for search/browse screens.
  static Stream<List<Masjid>> streamAll() {
    return _collection.snapshots().map((snapshot) => snapshot.docs
        .map((doc) => Masjid.fromMap(doc.id, doc.data() as Map<String, dynamic>))
        .toList());
  }

  /// Live stream of masjids awaiting platform admin review.
  static Stream<List<Masjid>> streamPending() {
    return _collection
        .where('verificationStatus', isEqualTo: 'Pending Verification')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Masjid.fromMap(doc.id, doc.data() as Map<String, dynamic>))
            .toList());
  }

  /// Live stream of masjids managed by a specific admin mobile number.
  static Stream<List<Masjid>> streamByAdminMobile(String mobile) {
    return _collection
        .where('adminMobile', isEqualTo: mobile)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Masjid.fromMap(doc.id, doc.data() as Map<String, dynamic>))
            .toList());
  }

  /// One-time fetch of a single masjid by id - used when a user is
  /// following a specific masjid and just needs its current data.
  static Future<Masjid?> getById(String id) async {
    final doc = await _collection.doc(id).get();
    if (!doc.exists) return null;
    return Masjid.fromMap(doc.id, doc.data() as Map<String, dynamic>);
  }

  /// Live updates for a single masjid - used on the Home screen so a
  /// user's followed masjid updates in real time if the admin changes
  /// prayer times or gets verified.
  static Stream<Masjid?> streamById(String id) {
    return _collection.doc(id).snapshots().map((doc) {
      if (!doc.exists) return null;
      return Masjid.fromMap(doc.id, doc.data() as Map<String, dynamic>);
    });
  }

  /// Registers a new masjid and returns the new Firestore document id.
  static Future<String> register(Masjid masjid) async {
    final docRef = await _collection.add(masjid.toMap());
    return docRef.id;
  }

  static Future<void> updatePrayerTimes(String id, PrayerTimes times) async {
    await _collection.doc(id).update({'prayerTimes': times.toMap()});
  }

  static Future<void> updateVerificationStatus(String id, String status) async {
    await _collection.doc(id).update({'verificationStatus': status});
  }

  static Future<void> updateAzanAudio(String id, String fileName, String url) async {
    await _collection.doc(id).update({
      'customAzanAudioName': fileName,
      'customAzanAudioUrl': url,
    });
  }
}
