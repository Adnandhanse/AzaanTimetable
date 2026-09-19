import 'package:firebase_auth/firebase_auth.dart';

/// Wraps Firebase Phone Authentication so screens don't need to know
/// Firebase details directly.
class AuthService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  /// The currently logged-in user, or null if nobody is logged in.
  /// Firebase Auth persists this automatically across app restarts.
  static User? get currentUser => _auth.currentUser;

  /// Fires whenever the signed-in user changes - used by OtpScreen to
  /// notice when verificationCompleted's background auto sign-in lands,
  /// so it can move on immediately instead of waiting on a manual "Verify"
  /// tap that would otherwise fail against an already-spent session.
  static Stream<User?> get authStateChanges => _auth.authStateChanges();

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
  /// Waits for Firebase to finish restoring any previously-signed-in
  /// session before we decide whether a new anonymous account is needed.
  /// Without this, checking currentUser immediately on a fresh app start
  /// (e.g. right after a phone reboot) can wrongly conclude "nobody is
  /// logged in" before the real restored session has loaded - creating a
  /// brand new anonymous account and orphaning the old one (along with
  /// whatever masjid the user had previously followed).
  static Future<void> signInAnonymouslyIfNeeded() async {
    await _auth.authStateChanges().first;
    if (currentUser == null) {
      await _auth.signInAnonymously();
    }
  }

  /// Starts phone verification. Calls [onCodeSent] with the verificationId
  /// once Firebase has sent the SMS, or [onError] if something goes wrong.
  ///
  /// [forceResendingToken] - pass the token from a previous [onCodeSent]
  /// call to request a genuine RESEND on the same number, rather than a
  /// fresh verification attempt. Lets OtpScreen offer a "Resend code"
  /// button when the SMS code expires (Firebase's codes are only valid for
  /// a few minutes - taking too long to type it in makes even the exact
  /// right digits get rejected, which is expected security behaviour, not
  /// a bug - the fix is a way to get a new code without leaving the screen).
  static Future<void> sendOtp({
    required String phoneNumber,
    required void Function(String verificationId, int? resendToken) onCodeSent,
    required void Function(String error) onError,
    int? forceResendingToken,
  }) async {
    try {
      await _auth.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        timeout: const Duration(seconds: 60),
        forceResendingToken: forceResendingToken,
        verificationCompleted: (PhoneAuthCredential credential) async {
          // Auto-retrieval on some Android devices - sign in directly.
          await _auth.signInWithCredential(credential);
        },
        verificationFailed: (FirebaseAuthException e) {
          onError(e.message ?? 'Verification failed');
        },
        codeSent: (String verificationId, int? resendToken) {
          onCodeSent(verificationId, resendToken);
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
