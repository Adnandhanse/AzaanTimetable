import 'dart:io';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:latlong2/latlong.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../models/masjid.dart';
import '../services/masjid_repository.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import '../theme/app_theme_controller.dart';
import 'admin_dashboard_screen.dart';
import 'otp_screen.dart';
import 'map_picker_screen.dart';

class RegisterMasjidScreen extends StatefulWidget {
  const RegisterMasjidScreen({super.key});

  @override
  State<RegisterMasjidScreen> createState() => _RegisterMasjidScreenState();
}

class _RegisterMasjidScreenState extends State<RegisterMasjidScreen> {
  final _formKey = GlobalKey<FormState>();
  final _masjidName = TextEditingController();
  final _registrationNo = TextEditingController();
  final _landmark = TextEditingController();
  final _city = TextEditingController();
  final _address = TextEditingController();
  final _adminName = TextEditingController();
  final _mobile = TextEditingController();
  final _email = TextEditingController();
  final _capacity = TextEditingController();
  final _about = TextEditingController();

  // Photos are picked HERE, during registration, but not uploaded until
  // _saveMasjidAfterVerification - the masjid does not have a real ID
  // (Firestore assigns one on creation) until registration + OTP both
  // succeed, and the Storage path needs that ID. Held as local Files in
  // the meantime; nothing touches the network for these until then.
  static const int _maxPhotos = 3;
  static const int _maxPhotoBytes = 2 * 1024 * 1024; // 2 MB, per spec
  final List<File> _pickedPhotos = [];
  bool _isSavingPhotos = false;

  bool _isSendingOtp = false;
  bool _isFetchingLocation = false;
  bool _isCheckingDuplicate = false;
  double? _latitude;
  double? _longitude;

  /// Set once a Verified masjid is found under the same registration number.
  /// Shows the error card and the "previous admin left" checkbox below the
  /// registration number field.
  Masjid? _duplicateOf;
  bool _previousAdminLeft = false;

  @override
  void initState() {
    super.initState();
    // Editing the registration number after seeing the duplicate error means
    // they may be correcting it or trying a different masjid - the old
    // error would otherwise sit there stale until they pressed submit again.
    _registrationNo.addListener(() {
      if (_duplicateOf != null) {
        setState(() {
          _duplicateOf = null;
          _previousAdminLeft = false;
        });
      }
    });
  }

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
        timeLimit: const Duration(seconds: 20),
      );

      if (!mounted) return;

      // Let the admin visually confirm/fine-tune the pin on a map -
      // this is where the real accuracy comes from (like Ola/Zomato),
      // not the automatic GPS reading alone.
      final confirmed = await Navigator.of(context).push<LatLng>(
        MaterialPageRoute(
          builder: (_) => MapPickerScreen(
            initialLatitude: position.latitude,
            initialLongitude: position.longitude,
          ),
        ),
      );
      if (confirmed == null) {
        // User backed out of the map screen without confirming.
        setState(() => _isFetchingLocation = false);
        return;
      }
      final finalLat = confirmed.latitude;
      final finalLng = confirmed.longitude;

      // Reverse-geocode the CONFIRMED coordinates into a readable address -
      // uses the phone's built-in geocoding, no Google Maps billing needed.
      // This is still just a starting point for the address text - the
      // admin should check and correct it below.
      String readableAddress = '';
      String cityName = '';
      try {
        final placemarks = await placemarkFromCoordinates(finalLat, finalLng);
        if (placemarks.isNotEmpty) {
          final p = placemarks.first;
          readableAddress = [
            if (p.subThoroughfare != null && p.subThoroughfare!.isNotEmpty) p.subThoroughfare,
            p.thoroughfare,
            p.subLocality,
            p.locality,
            if (p.postalCode != null && p.postalCode!.isNotEmpty) p.postalCode,
          ].where((s) => s != null && s.isNotEmpty).join(', ');
          cityName = p.locality ?? p.subAdministrativeArea ?? '';
        }
      } catch (_) {
        // Geocoding can fail (e.g. no internet) - coordinates are still
        // saved even if we can't auto-fill the readable address.
      }

      if (!mounted) return;
      setState(() {
        _latitude = finalLat;
        _longitude = finalLng;
        if (readableAddress.isNotEmpty) _address.text = readableAddress;
        if (cityName.isNotEmpty) _city.text = cityName;
        _isFetchingLocation = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Location captured. GPS can be off by a block - please check and correct the address below.'),
          duration: Duration(seconds: 4),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isFetchingLocation = false);
      String message = e.toString();
      if (message.contains('TimeoutException') || message.toLowerCase().contains('timeout')) {
        message = 'Could not get a GPS lock in time. Please go outdoors or near a window and try again.';
      } else if (message.startsWith('Exception: ')) {
        message = message.substring('Exception: '.length);
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
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

    // DUPLICATE REGISTRATION-NUMBER CHECK.
    //
    // Same registration number, and an ACTIVE (Verified) masjid already
    // exists under it - almost certainly the same real-world masjid being
    // registered a second time, whether by mistake or by someone with no
    // real claim to it. Blocked by default. "Previous masjid admin left" is
    // the one deliberate way past this - and even then, this still goes
    // through the ordinary Pending Verification review below; checking the
    // box does not skip approval, it only gets past this specific block.
    if (!_previousAdminLeft) {
      setState(() => _isCheckingDuplicate = true);
      Masjid? existing;
      try {
        existing = await MasjidRepository.findActiveByRegistrationNo(
            _registrationNo.text.trim());
      } catch (e) {
        if (!mounted) return;
        setState(() => _isCheckingDuplicate = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not check registration number: $e')),
        );
        return;
      }
      if (!mounted) return;
      setState(() {
        _isCheckingDuplicate = false;
        _duplicateOf = existing;
      });
      if (existing != null) return; // Error card + checkbox now visible below.
    } else {
      setState(() => _duplicateOf = null);
    }

    setState(() => _isSendingOtp = true);

    await AuthService.sendOtp(
      phoneNumber: '+91${_mobile.text}',
      onCodeSent: (verificationId, resendToken) {
        if (!mounted) return;
        setState(() => _isSendingOtp = false);
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => OtpScreen(
              phoneNumber: _mobile.text,
              verificationId: verificationId,
              resendToken: resendToken,
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

  Future<void> _pickMasjidPhoto() async {
    if (_pickedPhotos.length >= _maxPhotos) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Up to 3 photos - remove one to add another.')),
      );
      return;
    }

    final result = await FilePicker.platform.pickFiles(type: FileType.image);
    if (result == null || result.files.isEmpty || result.files.first.path == null) return;

    final picked = result.files.first;

    // Checked from the picker's own metadata, before touching the file
    // itself - no need to read it off disk just to find out it is too big.
    if (picked.size > _maxPhotoBytes) {
      if (!mounted) return;
      final sizeMb = (picked.size / (1024 * 1024)).toStringAsFixed(1);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('That photo is ${sizeMb}MB - please choose one under 2MB.')),
      );
      return;
    }

    setState(() => _pickedPhotos.add(File(picked.path!)));
  }

  void _removeMasjidPhoto(int index) {
    setState(() => _pickedPhotos.removeAt(index));
  }

  /// Uploads whatever photos were picked, now that [masjidId] actually
  /// exists. Best-effort per photo: one failing does not stop the others
  /// or block the registration that already succeeded - a partially
  /// uploaded gallery is a much smaller problem than losing the whole
  /// registration over a single bad upload.
  Future<List<String>> _uploadPickedPhotos(String masjidId) async {
    final List<String> urls = [];
    for (final file in _pickedPhotos) {
      try {
        final fileName = file.path.split('/').last;
        final ref = FirebaseStorage.instance.ref(
            'masjid_photos/$masjidId/${DateTime.now().millisecondsSinceEpoch}_$fileName');
        await ref.putFile(file);
        urls.add(await ref.getDownloadURL());
      } catch (_) {
        // Best-effort, as above - skip this one, keep going.
      }
    }
    return urls;
  }

  Future<void> _saveMasjidAfterVerification() async {
    final combinedAddress = _landmark.text.trim().isEmpty
        ? _address.text
        : '${_landmark.text.trim()}, ${_address.text}';

    final newMasjid = Masjid(
      id: '',
      name: _masjidName.text,
      city: _city.text,
      address: combinedAddress,
      latitude: _latitude!,
      longitude: _longitude!,
      verificationStatus: 'Pending Verification',
      registrationNo: _registrationNo.text,
      adminName: _adminName.text,
      adminMobile: _mobile.text,
      adminEmail: _email.text,
      previousAdminLeftClaim: _previousAdminLeft ? true : null,
      capacity: _capacity.text.trim().isEmpty ? null : int.tryParse(_capacity.text.trim()),
      about: _about.text.trim().isEmpty ? null : _about.text.trim(),
      prayerTimes: PrayerTimes(fajr: '--:--', dhuhr: '--:--', asr: '--:--', maghrib: '--:--', isha: '--:--', juma: '--:--'),
    );

    final String newId = await MasjidRepository.register(newMasjid);
    if (!mounted) return;

    if (_pickedPhotos.isNotEmpty) {
      setState(() => _isSavingPhotos = true);
      final urls = await _uploadPickedPhotos(newId);
      if (urls.isNotEmpty) {
        await MasjidRepository.updatePhotos(newId, urls);
      }
      if (!mounted) return;
      setState(() => _isSavingPhotos = false);
    }

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
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _field(_masjidName, 'Masjid Name', Icons.mosque),
            _field(_registrationNo, 'Mosque Registration No.', Icons.badge),
            // DUPLICATE-REGISTRATION ERROR, only shown once a check has
            // actually found an active masjid under this number.
            if (_duplicateOf != null) ...[
              Card(
                // A fixed light-pink error card looked broken against a
                // black page in Black & Gold - a muted dark red instead of
                // pretending the page is still light underneath it.
                color: AppThemeController.instance.isDark
                    ? const Color(0xFF3A1A1A)
                    : const Color(0xFFFDECEC),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.error_outline, color: Colors.red),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              '"${_duplicateOf!.name}" is already active with this '
                              'registration number. You cannot register a duplicate.',
                              style: const TextStyle(fontSize: 13),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      CheckboxListTile(
                        value: _previousAdminLeft,
                        onChanged: (v) => setState(() => _previousAdminLeft = v ?? false),
                        controlAffinity: ListTileControlAffinity.leading,
                        contentPadding: EdgeInsets.zero,
                        dense: true,
                        title: const Text(
                          'The previous masjid admin left - I am taking over this masjid',
                          style: TextStyle(fontSize: 13),
                        ),
                      ),
                      if (_previousAdminLeft)
                        const Padding(
                          padding: EdgeInsets.only(left: 4, bottom: 4),
                          child: Text(
                            'You can submit now. This will still be reviewed by us before it goes live, same as any other registration.',
                            style: TextStyle(fontSize: 12, color: Colors.black54),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 4),
            ],
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
            _field(_landmark, 'Building Name / Landmark (helps accuracy)', Icons.apartment, required: false),
            _field(_address, 'Address', Icons.home),
            _field(_capacity, 'Capacity (approx. number of people)', Icons.groups_outlined,
                keyboardType: TextInputType.number, required: false),
            _field(_about, 'About the Masjid', Icons.info_outline,
                required: false, maxLines: 4),
            const SizedBox(height: 4),
            const Text('Masjid Photos (optional)', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text(
              'Up to $_maxPhotos photos, 2MB each. Shown when someone opens this masjid from Nearby Masjids.',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            if (_pickedPhotos.isNotEmpty)
              SizedBox(
                height: 90,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _pickedPhotos.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, index) => Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.file(_pickedPhotos[index],
                            width: 90, height: 90, fit: BoxFit.cover),
                      ),
                      Positioned(
                        top: 2,
                        right: 2,
                        child: GestureDetector(
                          onTap: () => _removeMasjidPhoto(index),
                          child: const CircleAvatar(
                            radius: 12,
                            backgroundColor: Colors.black54,
                            child: Icon(Icons.close, size: 14, color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            if (_pickedPhotos.isNotEmpty) const SizedBox(height: 8),
            OutlinedButton.icon(
              icon: const Icon(Icons.add_photo_alternate_outlined),
              label: Text('Add Photo (${_pickedPhotos.length}/$_maxPhotos)'),
              onPressed: _pickedPhotos.length >= _maxPhotos ? null : _pickMasjidPhoto,
            ),
            const SizedBox(height: 12),
            const Divider(height: 32),
            const Text('Admin Details', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 12),
            _field(_adminName, 'Admin Name (Imam/Trustee)', Icons.person),
            _field(_mobile, 'Mobile Number', Icons.phone, keyboardType: TextInputType.phone),
            _field(_email, 'Email', Icons.email, keyboardType: TextInputType.emailAddress),
            const SizedBox(height: 8),
            Card(
              color: AppColors.cream,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: AppColors.emerald),
                    const SizedBox(width: 8),
                    const Expanded(
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
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.emerald),
                onPressed: (_isSendingOtp || _isCheckingDuplicate || _isSavingPhotos) ? null : _submit,
                child: (_isSendingOtp || _isCheckingDuplicate)
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('Verify Mobile & Register', style: TextStyle(color: Colors.white, fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _field(TextEditingController c, String label, IconData icon,
      {TextInputType? keyboardType, bool required = true, int maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: c,
        keyboardType: keyboardType,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: maxLines > 1
              ? Padding(
                  padding: const EdgeInsets.only(bottom: 60),
                  child: Icon(icon),
                )
              : Icon(icon),
          border: const OutlineInputBorder(),
        ),
        validator: required ? (v) => (v == null || v.isEmpty) ? 'Required' : null : null,
      ),
    );
  }
}
