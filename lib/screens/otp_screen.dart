import 'package:flutter/material.dart';
import '../services/auth_service.dart';

/// OTP verification screen for masjid admin registration.
class OtpScreen extends StatefulWidget {
  final String phoneNumber;
  final String verificationId;

  /// Called after OTP is successfully verified.
  final Future<void> Function() onVerified;

  const OtpScreen({
    super.key,
    required this.phoneNumber,
    required this.verificationId,
    required this.onVerified,
  });

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  final TextEditingController _otpController = TextEditingController();

  bool _isVerifying = false;

  @override
  void dispose() {
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

    // ---------------------------------------------------------
    // STEP 1: Verify OTP with Firebase
    // ---------------------------------------------------------
    try {
      await AuthService.verifyOtp(
        verificationId: widget.verificationId,
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

    // ---------------------------------------------------------
    // STEP 2: OTP is verified successfully
    // Now save the masjid / continue registration.
    // ---------------------------------------------------------
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('OTP Verification'),
      ),
      body: Padding(
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
          ],
        ),
      ),
    );
  }
}
