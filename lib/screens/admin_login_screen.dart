import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/admin_contact.dart';
import '../services/email_admin_verification.dart';
import '../widgets/admin_country_picker.dart';
import '../widgets/international_account_dialog.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'register_masjid_screen.dart';
import 'admin_dashboard_screen.dart';
import 'super_admin_login_screen.dart';
import '../services/masjid_repository.dart';
import '../services/auth_service.dart';
import 'otp_screen.dart';

class AdminLoginScreen extends StatefulWidget {
  const AdminLoginScreen({super.key});

  @override
  State<AdminLoginScreen> createState() => _AdminLoginScreenState();
}

class _AdminLoginScreenState extends State<AdminLoginScreen> {
  final TextEditingController _mobileController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  AdminCountry _country = AdminCountry.india;
  bool _isChecking = false;

  /// Set while checking for a saved session, so the login form does not flash
  /// up for a second before being replaced by the dashboard.
  bool _restoring = true;

  static const _key = 'admin_mobile';

  @override
  void initState() {
    super.initState();
    _restoreSession();
  }

  /// STAY LOGGED IN.
  ///
  /// The number was being asked for on every single launch, even though the app
  /// already knew it. An imam updating his times twice a day was typing his
  /// mobile number twice a day for no reason.
  ///
  /// The number is stored on this device only, and cleared on logout. It is not
  /// a credential — this screen is a lookup, not authentication — so nothing
  /// secret is being kept.
  Future<void> _restoreSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString(_key);
      if (saved != null && saved.trim().isNotEmpty) {
        // Confirm the masjid still exists and this number still administers it,
        // so a removed admin is not let straight back in.
        final matches =
            await MasjidRepository.streamByAdminMobile(saved).first.timeout(const Duration(seconds: 15));
        if (matches.isNotEmpty && mounted && matches.any((m) => AdminContact.matchesAccount(m, AuthService.currentUser))) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
                builder: (_) => AdminDashboardScreen(adminMobile: saved)),
          );
          return;
        }
        // No longer an admin — forget it rather than failing on every launch.
        await prefs.remove(_key);
      }
    } catch (_) {}
    if (mounted) setState(() => _restoring = false);
  }

  Future<void> _openDashboard(String mobile) async {
    final matches = await MasjidRepository.streamByAdminMobile(mobile).first.timeout(const Duration(seconds: 15));
    if (matches.isEmpty) throw StateError('No masjid is linked to this account yet. Register your masjid or contact the Platform Admin.');
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, matches.first.adminMobile);
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(
      builder: (_) => AdminDashboardScreen(adminMobile: matches.first.adminMobile)), (route) => false);
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    final mobile = _country.number(_mobileController.text.trim());
    setState(() => _isChecking = true);
    try {
      if (!_country.isIndia) {
        final verified = await openInternationalAccount(context, auth: FirebaseAuth.instance,
          email: _email.text, create: false);
        if (verified) await _openDashboard(mobile);
        return;
      }
      if (AuthService.currentUser?.phoneNumber == mobile) {
        await _openDashboard(mobile); return;
      }
      await AuthService.sendOtp(phoneNumber: mobile,
        onCodeSent: (id, token) {
          if (!mounted) return;
          Navigator.of(context).push(MaterialPageRoute(builder: (_) => OtpScreen(
            phoneNumber: mobile, verificationId: id, resendToken: token,
            onVerified: () => _openDashboard(mobile))));
        }, onError: (error) {
          if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
        });
    } on TimeoutException {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Could not load your masjid in time. Check your connection and try again.')));
    } catch (error) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(error is StateError ? '${error.message}' : EmailAdminVerification.friendly(error))));
    } finally { if (mounted) setState(() => _isChecking = false); }
  }

  @override
  void dispose() {
    _mobileController.dispose();
    _email.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_restoring) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text('Masjid Admin Login'),
      ),
      body: SingleChildScrollView(child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.admin_panel_settings, size: 56, color: Color(0xFF1F5E4A)),
              const SizedBox(height: 16),
              const Text('Admin Login', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text(_country.isIndia ? 'Verify your registered mobile number' : 'Sign in with your registered email and password', style: TextStyle(color: Colors.grey)),
              const SizedBox(height: 24),
              AdminCountryPicker(value: _country, enabled: !_isChecking,
                onChanged: (country) => setState(() { _country = country; _mobileController.clear(); })),
              if (_country.isIndia) TextFormField(
                controller: _mobileController, enabled: !_isChecking,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(labelText: 'Mobile number', prefixText: '${_country.dialCode} ', border: const OutlineInputBorder()),
                validator: _country.validate,
              ) else TextFormField(
                controller: _email, enabled: !_isChecking, keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(labelText: 'Registered email', border: OutlineInputBorder()),
                validator: (v) => !RegExp(r'^\S+@[^\s@]+\.[^\s@]+$').hasMatch((v ?? '').trim()) ? 'Enter a valid email address' : null,
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1F5E4A)),
                  onPressed: _isChecking ? null : _login,
                  child: _isChecking
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text('Login', style: TextStyle(color: Colors.white, fontSize: 16)),
                ),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const RegisterMasjidScreen())),
                child: const Text('New masjid? Register here'),
              ),
              const SizedBox(height: 4),
              TextButton(
                onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SuperAdminLoginScreen())),
                child: const Text('Platform Admin Login', style: TextStyle(color: Colors.grey)),
              ),
            ],
          ),
        ),
      )),
    );
  }
}
