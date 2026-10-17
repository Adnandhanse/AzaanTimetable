import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/masjid.dart';
import 'auth_service.dart';

/// Handles all reads/writes to the "masjids" collection in Firestore.
/// This is the single source of truth for masjid data - replacing the
/// old in-memory mock_masjids.dart list. Every device now sees the same
/// data, and it persists across app restarts.
class MasjidRepository {
  static final CollectionReference _collection =
      FirebaseFirestore.instance.collection('masjids');

  /// Live stream of only Verified masjids - this is what regular users
  /// should see when searching/browsing. Pending and Rejected masjids
  /// stay hidden from the public until (re)approved.
  static Stream<List<Masjid>> streamVerified() {
    return _collection
        .where('verificationStatus', isEqualTo: 'Verified')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Masjid.fromMap(doc.id, doc.data() as Map<String, dynamic>))
            .toList());
  }

  /// Live stream of every masjid regardless of status - used only by the
  /// Platform Admin's "All Masjids" tab, which needs to see everything.
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

  static Future<String?> getAdminUid(String id) async {
    final doc = await _collection.doc(id).get();
    if (!doc.exists) throw StateError('Masjid not found.');
    return (doc.data() as Map<String, dynamic>)['adminUid'] as String?;
  }

  /// Registers a new masjid and returns the new Firestore document id.
  static Future<String> register(Masjid masjid) async {
    if (await findActiveByRegistrationNo(masjid.registrationNo.trim()) != null) {
      throw StateError('This registration already exists. Request administration transfer instead.');
    }
    final data = masjid.toMap();
    data['registrationNo'] = masjid.registrationNo.trim();
    final user = AuthService.currentUser;
    if (user == null || user.phoneNumber != '+91${masjid.adminMobile.trim()}') {
      throw StateError('Verify the registered admin mobile first.');
    }
    data['adminUid'] = user.uid;
    final docRef = await _collection.add(data);
    return docRef.id;
  }

  /// Updates the times and stamps WHEN.
  ///
  /// Written with the SERVER's clock, not the device's. A phone with the wrong
  /// date would otherwise record a masjid as last updated in 2019, and you
  /// would have no way to tell that from a masjid that genuinely has not been
  /// touched since.
  ///
  /// Useful for exactly the thing you asked about: seeing which masjids have
  /// gone stale and need chasing.
  static Future<void> updatePrayerTimes(String id, PrayerTimes times) async {
    await _collection.doc(id).update({
      'prayerTimes': times.toMap(),
      'timesUpdatedAt': FieldValue.serverTimestamp(),
    });
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

  /// Clears the masjid's custom azan, reverting everyone following it back
  /// to the bundled default. Does NOT delete anything about the masjid
  /// itself - only these two fields.
  static Future<void> removeAzanAudio(String id) async {
    await _collection.doc(id).update({
      'customAzanAudioName': FieldValue.delete(),
      'customAzanAudioUrl': FieldValue.delete(),
    });
  }

  static Future<void> updateAboutAndCapacity(
    String id, {
    String? about,
    int? capacity,
  }) async {
    await _collection.doc(id).update({
      'about': about,
      'capacity': capacity,
    });
  }

  /// Replaces the masjid's whole photo list. Capped at 3 - the screen that
  /// calls this enforces the limit before it ever gets here, so the person
  /// finds out at the point of picking a 4th photo, not after an upload.
  static Future<void> updatePhotos(String id, List<String> photoUrls) async {
    await _collection.doc(id).update({'photoUrls': photoUrls});
  }

  /// Match any existing registration, regardless of verification status.
  /// Refuse ambiguous legacy duplicates instead of choosing the wrong record.
  static Future<Masjid?> findActiveByRegistrationNo(String registrationNo) async {
    final snapshot = await _collection
        .where('registrationNo', isEqualTo: registrationNo)
        .get();
    if (snapshot.docs.isEmpty) return null;
    if (snapshot.docs.length > 1) {
      throw StateError('Multiple masjids have this registration number. Contact the platform admin to resolve them before transferring.');
    }
    final doc = snapshot.docs.first;
    return Masjid.fromMap(doc.id, doc.data() as Map<String, dynamic>);
  }
}
