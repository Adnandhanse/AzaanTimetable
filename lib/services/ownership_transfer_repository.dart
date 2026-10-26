import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import '../models/masjid.dart';

class OwnershipTransferRepository {
  static final _functions = FirebaseFunctions.instanceFor(region: 'us-central1');
  static Future<void> request(Masjid masjid, {
    required String name, required String mobile, required String email,
    String countryIso = 'IN',
  }) async {
    await _functions.httpsCallable('requestVerifiedAdminTransfer').call({
      'masjidId': masjid.id, 'name': name.trim(), 'mobile': mobile.trim(),
      'email': email.trim(), 'countryIso': countryIso,
    });
  }
  static Stream<QuerySnapshot<Map<String, dynamic>>> pending() =>
      FirebaseFirestore.instance.collection('ownershipTransferRequests')
        .where('status', isEqualTo: 'Pending').snapshots();
  static Future<void> review(String requestId, {required bool approve}) async {
    await _functions.httpsCallable('reviewVerifiedAdminTransfer')
      .call({'requestId': requestId, 'approve': approve});
  }
}
