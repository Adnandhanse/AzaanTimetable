import 'package:cloud_firestore/cloud_firestore.dart';
import 'auth_service.dart';
import '../models/masjid.dart';

class OwnershipTransferRepository {
  static final _db = FirebaseFirestore.instance;
  static final _requests = _db.collection('ownershipTransferRequests');

  static Future<void> request(Masjid masjid, {
    required String name, required String mobile, required String email,
  }) async {
    final user = AuthService.currentUser;
    if (user == null || user.phoneNumber != '+91${mobile.trim()}') {
      throw StateError('Verify the new admin mobile number first.');
    }
    final ref = _requests.doc('${masjid.id}_${user.uid}');
    final masjidRef = _db.collection('masjids').doc(masjid.id);
    await _db.runTransaction((tx) async {
      final current = await tx.get(masjidRef);
      final previous = await tx.get(ref);
      if (!current.exists) throw StateError('Masjid no longer exists.');
      final data = current.data()!;
      if (data['registrationNo'] != masjid.registrationNo) {
        throw StateError('Registration details changed. Please try again.');
      }
      if (data['adminMobile'] == mobile.trim()) {
        throw StateError('This number already manages the masjid. Please log in.');
      }
      if (previous.exists && previous.data()?['status'] == 'Pending') return;
      tx.set(ref, {
        'masjidId': masjid.id, 'masjidName': data['name'],
        'registrationNo': data['registrationNo'],
        'previousAdminMobile': data['adminMobile'],
        'previousAdminUid': data['adminUid'],
        'requesterUid': user.uid, 'newAdminName': name.trim(),
        'newAdminMobile': mobile.trim(), 'newAdminEmail': email.trim(),
        'status': 'Pending', 'requestedAt': FieldValue.serverTimestamp(),
      });
    });
  }

  static Stream<QuerySnapshot<Map<String, dynamic>>> pending() =>
      _requests.where('status', isEqualTo: 'Pending').snapshots();

  static Future<void> review(String requestId, {required bool approve}) async {
    final user = AuthService.currentUser;
    if (user == null) throw StateError('Platform admin login required.');
    final permission = await _db.collection('platformAdmins').doc(user.uid).get();
    if (permission.data()?['enabled'] != true) {
      throw StateError('Your account must be enabled in platformAdmins before reviewing transfers.');
    }
    final ref = _requests.doc(requestId);
    await _db.runTransaction((tx) async {
      final request = await tx.get(ref);
      final data = request.data();
      if (data == null || data['status'] != 'Pending') {
        throw StateError('This request has already been reviewed.');
      }
      final masjidRef = _db.collection('masjids').doc(data['masjidId'] as String);
      final masjid = await tx.get(masjidRef);
      if (!masjid.exists) throw StateError('Masjid no longer exists.');
      if (approve) {
        if (masjid.data()?['adminMobile'] != data['previousAdminMobile'] ||
            masjid.data()?['adminUid'] != data['previousAdminUid']) {
          throw StateError('Ownership changed since this request. Reject it and ask for a new request.');
        }
        // Never serialize a new Masjid here: update ONLY administrator fields.
        tx.update(masjidRef, {
          'adminName': data['newAdminName'], 'adminMobile': data['newAdminMobile'],
          'adminEmail': data['newAdminEmail'], 'adminUid': data['requesterUid'],
          'ownershipTransferredAt': FieldValue.serverTimestamp(),
          'ownershipTransferRequestId': requestId,
        });
      }
      tx.update(ref, {
        'status': approve ? 'Approved' : 'Rejected',
        'reviewedBy': user.uid, 'reviewedAt': FieldValue.serverTimestamp(),
      });
    });
  }
}
