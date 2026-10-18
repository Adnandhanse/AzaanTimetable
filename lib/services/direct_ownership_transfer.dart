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
      name: 'ownership-recipient-${DateTime.now().microsecondsSinceEpoch}',
      options: Firebase.app().options);
    _auth = FirebaseAuth.instanceFor(app: _app!);
    await _auth!.signOut();
  }

  Future<void> submit({required String masjidId, required String name,
    required String mobile, required String email, required String operationId,
    required String expectedAdminMobile, required String? expectedAdminUid}) async {
    final caller = FirebaseAuth.instanceFor(app: Firebase.app()).currentUser;
    if (caller?.phoneNumber != '+91${expectedAdminMobile.trim()}') {
      throw StateError('Sign in again as the current masjid administrator.');
    }
    // Refresh BOTH independent sessions. Never replace A's login with B's OTP.
    await caller!.getIdToken(true);
    final user = auth.currentUser;
    if (user?.phoneNumber != '+91$mobile') throw StateError('Verify B’s phone first.');
    final token = await user!.getIdToken(true);
    if (token == null || token.isEmpty) throw StateError('Verify the new admin phone again.');
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
