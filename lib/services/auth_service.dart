import 'package:firebase_auth/firebase_auth.dart';

/// Wraps Firebase Phone Authentication so screens don't need to know
/// Firebase details directly.
class AuthService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  /// The currently logged-in user, or null if nobody is logged in.
  /// Firebase Auth persists this automatically across app restarts.
  static User? get currentUser => _auth.currentUser;

  /// True only for a real (non-anonymous) signed-in account - i.e. the
  /// platform admin, who signs in with email/password rather than the
  /// anonymous sessions regular users get automatically.
  static bool get isAdminLoggedIn => currentUser != null && !currentUser!.isAnonymous;

  static Future<void> signInAdmin(String email, String password) async {
    await _auth.signInWithEmailAndPassword(email: email, password: password);
  }

  /// Signs the admin out, then immediately restores an anonymous session
  /// so the rest of the app (which expects someone to always be signed
  /// in, even if just anonymously) keeps working normally.
  static Future<void> signOutAdmin() async {
    await _auth.signOut();
    await signInAnonymouslyIfNeeded();
  }

  /// Signs the user in anonymously - free, instant, no SMS cost. Used for
  /// regular app users so we can still remember their followed masjid
  /// (via Firestore keyed by this UID) without ever asking for OTP.
  static Future<void> signInAnonymouslyIfNeeded() async {
    if (currentUser == null) {
      await _auth.signInAnonymously();
    }
  }

  /// Starts phone verification. Calls [onCodeSent] with the verificationId
  /// once Firebase has sent the SMS, or [onError] if something goes wrong.
  static Future<void> sendOtp({
    required String phoneNumber,
    required void Function(String verificationId) onCodeSent,
    required void Function(String error) onError,
  }) async {
    try {
      await _auth.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        timeout: const Duration(seconds: 60),
        verificationCompleted: (PhoneAuthCredential credential) async {
          // Auto-retrieval on some Android devices - sign in directly.
          await _auth.signInWithCredential(credential);
        },
        verificationFailed: (FirebaseAuthException e) {
          onError(e.message ?? 'Verification failed');
        },
        codeSent: (String verificationId, int? resendToken) {
          onCodeSent(verificationId);
        },
        codeAutoRetrievalTimeout: (String verificationId) {},
      );
    } catch (e) {
      onError(e.toString());
    }
  }

  /// Verifies the OTP code the user typed in, using the verificationId
  /// from [sendOtp]'s onCodeSent callback.
  static Future<UserCredential> verifyOtp({
    required String verificationId,
    required String smsCode,
  }) async {
    final credential = PhoneAuthProvider.credential(
      verificationId: verificationId,
      smsCode: smsCode,
    );
    return await _auth.signInWithCredential(credential);
  }

  static Future<void> signOut() async {
    await _auth.signOut();
  }
}
