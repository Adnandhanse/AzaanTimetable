import 'package:flutter/material.dart';
import '../services/auth_service.dart';

/// Generic OTP verification screen. Used only for masjid admin
/// registration (to prove the admin's phone is real) - regular app
/// users never see this, to keep SMS costs down.
class OtpScreen extends StatefulWidget {
  final String phoneNumber;
  final String verificationId;

  /// Called after the OTP is successfully verified. The caller decides
  /// what happens next (e.g. save the masjid, then navigate onward).
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

  Future<void> _verifyOtp() async {
    if (_otpController.text.length < 4) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter the OTP sent to your phone')),
      );
      return;
    }

    setState(() => _isVerifying = true);
    try {
      await AuthService.verifyOtp(
        verificationId: widget.verificationId,
        smsCode: _otpController.text,
      );
      await widget.onVerified();
    } catch (e) {
      if (!mounted) return;
      setState(() => _isVerifying = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Incorrect code, please try again.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('OTP Verification')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Enter the OTP sent to +91 ${widget.phoneNumber}'),
            const SizedBox(height: 24),
            TextField(
              controller: _otpController,
              keyboardType: TextInputType.number,
              maxLength: 6,
              decoration: const InputDecoration(labelText: 'OTP', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF14532D)),
                onPressed: _isVerifying ? null : _verifyOtp,
                child: _isVerifying
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('Verify', style: TextStyle(color: Colors.white, fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
