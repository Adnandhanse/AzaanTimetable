import 'package:cloud_firestore/cloud_firestore.dart';
import 'auth_service.dart';

/// Stores per-user preferences (currently just which masjid they follow)
/// in Firestore, keyed by their Firebase Auth UID. This is what makes
/// "which masjid am I following" persist across app restarts and devices.
class UserRepository {
  static CollectionReference get _collection =>
      FirebaseFirestore.instance.collection('users');

  static Future<void> setSelectedMasjid(String masjidId) async {
    final uid = AuthService.currentUser?.uid;
    if (uid == null) return;
    await _collection.doc(uid).set(
      {'selectedMasjidId': masjidId},
      SetOptions(merge: true),
    );
  }

  static Future<String?> getSelectedMasjidId() async {
    final uid = AuthService.currentUser?.uid;
    if (uid == null) return null;
    final doc = await _collection.doc(uid).get();
    if (!doc.exists) return null;
    final data = doc.data() as Map<String, dynamic>?;
    return data?['selectedMasjidId'];
  }
}
