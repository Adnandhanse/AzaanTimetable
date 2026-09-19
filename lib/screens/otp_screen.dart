import 'dart:async';
import 'package:flutter/material.dart';
import '../services/auth_service.dart';

/// OTP verification screen for masjid admin registration.
class OtpScreen extends StatefulWidget {
  final String phoneNumber;
  final String verificationId;
  final int? resendToken;
  /// Called after OTP is successfully verified.
  final Future<void> Function() onVerified;

  const OtpScreen({
    super.key,
    required this.phoneNumber,
    required this.verificationId,
    required this.onVerified,
    this.resendToken,
  });

  final String phoneNumber;
  final String verificationId;
  final int? resendToken;
  final Future<void> Function() onVerified;

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  final TextEditingController _otpController = TextEditingController();

  bool _isVerifying = false;
  bool _isResending = false;
  StreamSubscription<dynamic>? _authSub;
  bool _autoHandled = false;

  @override
  void dispose() {
    _authSub?.cancel();
    _countdownTimer?.cancel();
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _verifyOtp() async {
    final otp = _otpController.text.trim();

    if (otp.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter the 6-digit OTP'),
        ),
      );
      return;
    }

    setState(() {
      _isVerifying = true;
    });

    try {
      await AuthService.verifyOtp(
        verificationId: _verificationId,
        smsCode: otp,
      );
    } on Exception catch (e) {
      if (!mounted) return;

      setState(() {
        _isVerifying = false;
      });

      debugPrint('OTP VERIFICATION ERROR: $e');

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'OTP verification failed:\n$e',
          ),
          duration: const Duration(seconds: 10),
        ),
      );

      return;
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isVerifying = false;
      });

      debugPrint('OTP VERIFICATION UNKNOWN ERROR: $e');

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'OTP verification failed:\n$e',
          ),
          duration: const Duration(seconds: 10),
        ),
      );

      return;
    }

    try {
      await widget.onVerified();

    try {
      await widget.onVerified();

      if (!mounted) return;

      setState(() {
        _isVerifying = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isVerifying = false;
      });

      debugPrint('POST OTP / REGISTRATION ERROR: $e');

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'OTP verified, but registration could not be completed:\n$e',
          ),
          duration: const Duration(seconds: 10),
        ),
      );
    }
  }

  Future<void> _resendCode() async {
    setState(() => _isResending = true);
    await AuthService.sendOtp(
      phoneNumber: '+91${widget.phoneNumber}',
      forceResendingToken: _resendToken,
      onCodeSent: (verificationId, resendToken) {
        if (!mounted) return;
        setState(() {
          _verificationId = verificationId;
          _resendToken = resendToken;
          _isResending = false;
          _otpController.clear();
        });
        _startCountdown();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('A new code has been sent.')),
        );
      },
      onError: (error) {
        if (!mounted) return;
        setState(() => _isResending = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not resend code: $error')),
        );
      },
    );
  }

  Future<void> _verifyOtp() async {
    if (_otpController.text.length < 4) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter the OTP sent to your phone')),
      );
      return;
    }

    setState(() => _isVerifying = true);

    // ANOTHER REAL CAUSE OF "incorrect code" WITH A CORRECT CODE:
    //
    // AuthService.sendOtp's verificationCompleted callback signs the user in
    // AUTOMATICALLY, silently, the moment Android's SMS Retriever API reads
    // the code off the incoming SMS - which can happen before the person
    // even finishes typing it in by hand. That already consumes this
    // verification session. The subsequent manual "Verify" tap then tries to
    // use the SAME session a second time, which Firebase rejects outright -
    // regardless of whether the digits typed are the correct ones.
    //
    // The initState listener above should already catch this before the
    // person even presses this button, most of the time - this check is the
    // fallback for whatever gap remains (e.g. the auth state event and this
    // button press landing in the same frame).
    if (AuthService.currentUser != null && !AuthService.currentUser!.isAnonymous) {
      _autoHandled = true;
      await _completeVerification();
      return;
    }

    // THE BUG THIS USED TO HAVE: this wrapped OTP verification AND
    // onVerified() (which saves the masjid to Firestore) in the SAME
    // try/catch, and reported every failure - from either step - as
    // "Incorrect code, please try again." So a correct OTP with a Firestore
    // write failure behind it looked EXACTLY like a wrong OTP. Split into
    // two separate try blocks so each failure gets reported as what it
    // actually was.
    try {
      await AuthService.verifyOtp(
        verificationId: _verificationId,
        smsCode: _otpController.text,
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isVerifying = false);
      // A genuinely expired/invalid session (Firebase's own
      // auth/code-expired, auth/invalid-verification-code, or
      // auth/session-expired) reads differently from a plain wrong digit -
      // points straight at "resend" instead of "try typing it again",
      // since retyping the same dead code will never work.
      final String message = e.toString();
      final bool expired = message.contains('expired') || message.contains('session');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            expired
                ? 'This code has expired. Tap "Resend code" below to get a new one.'
                : 'Incorrect code, please try again.',
          ),
        ),
      );
      return;
    }

    await _completeVerification();
  }

  @override
  Widget build(BuildContext context) {
    final bool canResend = _secondsRemaining == 0 && !_isResending;

    return Scaffold(
      appBar: AppBar(
        title: const Text('OTP Verification'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF1F5E4A)),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Enter the OTP sent to +91 ${widget.phoneNumber}',
                style: const TextStyle(
                  fontSize: 16,
                ),
              ),

              const SizedBox(height: 24),

              TextField(
                controller: _otpController,
                keyboardType: TextInputType.number,
                maxLength: 6,
                enabled: !_isVerifying,
                decoration: const InputDecoration(
                  labelText: 'OTP',
                  border: OutlineInputBorder(),
                  counterText: '',
                ),
              ),

              const SizedBox(height: 16),

              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1F5E4A),
                  ),
                  onPressed: _isVerifying ? null : _verifyOtp,
                  child: _isVerifying
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          'Verify',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 4),

              ),
              const SizedBox(height: 4),
              // Countdown, so it is obvious when a code has actually gone
              // stale instead of someone re-typing a dead code repeatedly.
              Text(
                _secondsRemaining > 0
                    ? 'Code expires in ${_secondsRemaining ~/ 60}:${(_secondsRemaining % 60).toString().padLeft(2, '0')}'
                    : 'This code has expired.',
                style: TextStyle(
                  color: _secondsRemaining > 0 ? Colors.black54 : Colors.red,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                height: 50,
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1F5E4A),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  onPressed: _isVerifying ? null : _verifyOtp,
                  child: _isVerifying
                      ? const SizedBox(
                          height: 20, width: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text('Verify', style: TextStyle(color: Colors.white, fontSize: 16)),
                ),
              ),
              const SizedBox(height: 12),
              Center(
                child: TextButton(
                  onPressed: canResend ? _resendCode : null,
                  child: _isResending
                      ? const SizedBox(
                          height: 16, width: 16,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF1F5E4A)))
                      : Text(
                          canResend
                              ? 'Resend code'
                              : 'Resend code (${_secondsRemaining}s)',
                          style: TextStyle(
                            color: canResend ? const Color(0xFF1F5E4A) : Colors.black38,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
