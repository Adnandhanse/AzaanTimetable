import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Compatibility error helper. Email OTP has been retired; callers use
/// Firebase email/password plus Platform Admin approval instead.
class EmailAdminVerification {
  final FirebaseAuth auth;
  EmailAdminVerification(this.auth);
  Future<Map<String, dynamic>> send(Map<String, dynamic> details) =>
      Future.error(StateError('Email OTP is no longer used. Update the app.'));
  Future<void> verify(String challengeId, String code) =>
      Future.error(StateError('Email OTP is no longer used.'));
  static String friendly(Object e) {
    if (e is FirebaseFunctionsException &&
        ['failed-precondition','invalid-argument','already-exists','resource-exhausted'].contains(e.code)) {
      return e.message ?? 'Check your details and try again.';
    }
    return 'Could not continue. Check your connection and try again.';
  }
}
