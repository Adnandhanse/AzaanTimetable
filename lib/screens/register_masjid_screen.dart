import 'package:flutter/material.dart';
import '../models/masjid.dart';
import '../data/mock_masjids.dart';
import 'upload_verification_screen.dart';

class RegisterMasjidScreen extends StatefulWidget {
  const RegisterMasjidScreen({super.key});

  @override
  State<RegisterMasjidScreen> createState() => _RegisterMasjidScreenState();
}

class _RegisterMasjidScreenState extends State<RegisterMasjidScreen> {
  final _formKey = GlobalKey<FormState>();
  final _masjidName = TextEditingController();
  final _city = TextEditingController();
  final _address = TextEditingController();
  final _mapLink = TextEditingController();
  final _adminName = TextEditingController();
  final _mobile = TextEditingController();
  final _email = TextEditingController();

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    final newMasjid = Masjid(
      id: 'm${mockMasjids.length + 1}',
      name: _masjidName.text,
      city: _city.text,
      address: _address.text,
      // Phase 3: latitude/longitude should come from Google Maps picker.
      // Using placeholder coordinates until Google Maps API is wired in.
      latitude: 0.0,
      longitude: 0.0,
      verificationStatus: 'Pending Verification',
      adminName: _adminName.text,
      adminMobile: _mobile.text,
      adminEmail: _email.text,
      prayerTimes: PrayerTimes(
        fajr: '--:--',
        dhuhr: '--:--',
        asr: '--:--',
        maghrib: '--:--',
        isha: '--:--',
        juma: '--:--',
      ),
    );

    mockMasjids.add(newMasjid);

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => UploadVerificationScreen(masjid: newMasjid),
      ),
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
            _field(_city, 'City', Icons.location_city),
            _field(_address, 'Address', Icons.home),
            _field(_mapLink, 'Google Map Location (link)', Icons.map),
            const Divider(height: 32),
            const Text('Admin Details', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 12),
            _field(_adminName, 'Admin Name (Imam/Trustee)', Icons.person),
            _field(_mobile, 'Mobile Number', Icons.phone, keyboardType: TextInputType.phone),
            _field(_email, 'Email', Icons.email, keyboardType: TextInputType.emailAddress),
            const SizedBox(height: 24),
            SizedBox(
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF14532D)),
                onPressed: _submit,
                child: const Text(
                  'Continue to Verification',
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
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
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon),
          border: const OutlineInputBorder(),
        ),
        validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
      ),
    );
  }
}
