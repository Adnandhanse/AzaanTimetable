import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_functions/cloud_functions.dart';

/// B authenticates in a separate Firebase app. A's main login stays intact.
class DirectOwnershipTransfer {
  // Must match the export/region in functions/index.js.
  static const functionName = 'transferMasjidAdministration';
  static const functionRegion = 'us-central1';
  FirebaseApp? _app;
  FirebaseAuth? _auth;
  FirebaseAuth get auth => _auth!;

  Future<void> initialize() async {
    _app = await Firebase.initializeApp(
      name: 'ownership-recipient', options: Firebase.app().options);
    _auth = FirebaseAuth.instanceFor(app: _app!);
    await _auth!.signOut();
  }

  Future<void> submit({required String masjidId, required String name,
    required String mobile, required String email, required String operationId,
    required String expectedAdminMobile, required String? expectedAdminUid}) async {
    final user = auth.currentUser;
    if (user?.phoneNumber != '+91$mobile') throw StateError('Verify B’s phone first.');
    final token = await user!.getIdToken(true);
    await FirebaseFunctions.instanceFor(app: Firebase.app(), region: functionRegion)
      .httpsCallable(functionName).call({
        'masjidId': masjidId, 'name': name.trim(), 'mobile': mobile,
        'email': email.trim(), 'recipientIdToken': token, 'operationId': operationId,
        'expectedAdminMobile': expectedAdminMobile, 'expectedAdminUid': expectedAdminUid,
      });
  }

  Future<void> dispose() async {
    try { await _auth?.signOut(); } finally { await _app?.delete(); }
  }
}
