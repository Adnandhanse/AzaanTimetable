import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
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
  final _adminName = TextEditingController();
  final _mobile = TextEditingController();
  final _email = TextEditingController();

  bool _isSendingOtp = false;
  bool _isFetchingLocation = false;
  double? _latitude;
  double? _longitude;

  Future<void> _useCurrentLocation() async {
    setState(() => _isFetchingLocation = true);
    try {
      // Check/request location permission.
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
        throw Exception('Location permission denied. Please allow it in phone settings.');
      }

      if (!await Geolocator.isLocationServiceEnabled()) {
        throw Exception('Please turn on Location/GPS on your phone.');
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      // Reverse-geocode the coordinates into a readable address - uses the
      // phone's built-in geocoding, no Google Maps billing needed.
      String readableAddress = '';
      String cityName = '';
      try {
        final placemarks = await placemarkFromCoordinates(position.latitude, position.longitude);
        if (placemarks.isNotEmpty) {
          final p = placemarks.first;
          readableAddress = [p.street, p.subLocality, p.locality]
              .where((s) => s != null && s.isNotEmpty)
              .join(', ');
          cityName = p.locality ?? p.subAdministrativeArea ?? '';
        }
      } catch (_) {
        // Geocoding can fail (e.g. no internet) - coordinates are still
        // saved even if we can't auto-fill the readable address.
      }

      if (!mounted) return;
      setState(() {
        _latitude = position.latitude;
        _longitude = position.longitude;
        if (readableAddress.isNotEmpty) _address.text = readableAddress;
        if (cityName.isNotEmpty) _city.text = cityName;
        _isFetchingLocation = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Location captured. Please check the address below.')),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isFetchingLocation = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    if (_latitude == null || _longitude == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please tap "Use Current Location" first, so followers can find this masjid.')),
      );
      return;
    }

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
      latitude: _latitude!,
      longitude: _longitude!,
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
            const SizedBox(height: 4),
            OutlinedButton.icon(
              icon: _isFetchingLocation
                  ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.my_location),
              label: Text(_isFetchingLocation
                  ? 'Getting location...'
                  : _latitude == null
                      ? 'Use Current Location'
                      : 'Location captured ✓ (tap to refresh)'),
              onPressed: _isFetchingLocation ? null : _useCurrentLocation,
            ),
            const SizedBox(height: 12),
            _field(_city, 'City', Icons.location_city),
            _field(_address, 'Address', Icons.home),
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
