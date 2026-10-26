import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_functions/cloud_functions.dart';

/// Recipient authenticates in a separate app: current admin stays signed in.
class DirectOwnershipTransfer {
  static const functionName = 'transferMasjidAdministration';
  static const functionRegion = 'us-central1';
  FirebaseApp? _app;
  FirebaseAuth? _auth;
  FirebaseAuth get auth => _auth!;
  Future<void> initialize() async {
    _app = await Firebase.initializeApp(name: 'ownership-recipient-${DateTime.now().microsecondsSinceEpoch}', options: Firebase.app().options);
    _auth = FirebaseAuth.instanceFor(app: _app!);
    await _auth!.signOut();
  }
  Future<void> submit({required String masjidId, required String name,
    required String mobile, required String email, required String operationId,
    required String expectedAdminMobile, required String? expectedAdminUid,
    String countryIso = 'IN', bool requireApproval = false}) async {
    final caller = FirebaseAuth.instance.currentUser;
    if (caller == null || (expectedAdminUid != null && caller.uid != expectedAdminUid)) {
      throw StateError('Sign in as the current masjid admin.');
    }
    await caller.getIdToken(true);
    final user = auth.currentUser;
    if (user == null) throw StateError('Verify the new admin first.');
    final token = await user.getIdToken(true);
    if (token == null || token.isEmpty) throw StateError('Verify the new admin again.');
    await FirebaseFunctions.instanceFor(region: functionRegion).httpsCallable(requireApproval ? 'submitInternationalAdminTransfer' : functionName).call({
      'masjidId': masjidId, 'name': name.trim(), 'mobile': mobile,
      'email': email.trim(), 'countryIso': countryIso, 'recipientIdToken': token,
      'operationId': operationId, 'expectedAdminMobile': expectedAdminMobile,
      'expectedAdminUid': expectedAdminUid,
    }).timeout(const Duration(seconds: 45));
  }
  Future<void> dispose() async {
    try { await _auth?.signOut(); } finally { await _app?.delete(); }
  }
}
