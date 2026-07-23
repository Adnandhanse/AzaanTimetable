import 'package:flutter/material.dart';
import '../models/masjid.dart';
import '../services/masjid_repository.dart';
import '../services/auth_service.dart';
import 'admin_dashboard_screen.dart';
import 'otp_screen.dart';

class RegisterMasjidScreen extends StatefulWidget {
  const RegisterMasjidScreen({super.key});

  @override
  State<RegisterMasjidScreen> createState() => _RegisterMasjidScreenState();
}

class _RegisterMasjidScreenState extends State<RegisterMasjidScreen> {
  final _formKey = GlobalKey<FormState>();
  final _masjidName = TextEditingController();
  final _registrationNo = TextEditingController();
  final _city = TextEditingController();
  final _address = TextEditingController();
  final _mapLink = TextEditingController();
  final _adminName = TextEditingController();
  final _mobile = TextEditingController();
  final _email = TextEditingController();
  bool _isSendingOtp = false;

  // OTP is required here specifically - proving the admin's phone is real
  // - but nowhere else in the app, to keep SMS costs down.
  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSendingOtp = true);

    await AuthService.sendOtp(
      phoneNumber: '+91${_mobile.text}',
      onCodeSent: (verificationId) {
        if (!mounted) return;
        setState(() => _isSendingOtp = false);
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => OtpScreen(
              phoneNumber: _mobile.text,
              verificationId: verificationId,
              onVerified: _saveMasjidAfterVerification,
            ),
          ),
        );
      },
      onError: (error) {
        if (!mounted) return;
        setState(() => _isSendingOtp = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not send OTP: $error')),
        );
      },
    );
  }

  Future<void> _saveMasjidAfterVerification() async {
    final newMasjid = Masjid(
      id: '',
      name: _masjidName.text,
      city: _city.text,
      address: _address.text,
      // Phase 4: latitude/longitude should come from a Google Maps picker.
      latitude: 0.0,
      longitude: 0.0,
      verificationStatus: 'Pending Verification',
      registrationNo: _registrationNo.text,
      adminName: _adminName.text,
      adminMobile: _mobile.text,
      adminEmail: _email.text,
      prayerTimes: PrayerTimes(fajr: '--:--', dhuhr: '--:--', asr: '--:--', maghrib: '--:--', isha: '--:--', juma: '--:--'),
    );

    await MasjidRepository.register(newMasjid);
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Registered. Status: Pending Verification.')),
    );

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => AdminDashboardScreen(adminMobile: _mobile.text)),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Register Masjid'),
        backgroundColor: const Color(0xFF14532D),
        foregroundColor: Colors.white,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _field(_masjidName, 'Masjid Name', Icons.mosque),
            _field(_registrationNo, 'Mosque Registration No.', Icons.badge),
            _field(_city, 'City', Icons.location_city),
            _field(_address, 'Address', Icons.home),
            _field(_mapLink, 'Google Map Location (link)', Icons.map),
            const Divider(height: 32),
            const Text('Admin Details', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 12),
            _field(_adminName, 'Admin Name (Imam/Trustee)', Icons.person),
            _field(_mobile, 'Mobile Number', Icons.phone, keyboardType: TextInputType.phone),
            _field(_email, 'Email', Icons.email, keyboardType: TextInputType.emailAddress),
            const SizedBox(height: 8),
            Card(
              color: const Color(0xFFF0FDF4),
              child: const Padding(
                padding: EdgeInsets.all(12),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Color(0xFF14532D)),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        "We'll send an OTP to the mobile number above to confirm it's yours "
                        'before your masjid is registered.',
                        style: TextStyle(fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF14532D)),
                onPressed: _isSendingOtp ? null : _submit,
                child: _isSendingOtp
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('Verify Mobile & Register', style: TextStyle(color: Colors.white, fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _field(TextEditingController c, String label, IconData icon, {TextInputType? keyboardType}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: c,
        keyboardType: keyboardType,
        decoration: InputDecoration(labelText: label, prefixIcon: Icon(icon), border: const OutlineInputBorder()),
        validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
      ),
    );
  }
}
