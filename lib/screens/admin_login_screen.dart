import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'register_masjid_screen.dart';
import 'admin_dashboard_screen.dart';
import 'super_admin_login_screen.dart';
import '../services/masjid_repository.dart';

class AdminLoginScreen extends StatefulWidget {
  const AdminLoginScreen({super.key});

  @override
  State<AdminLoginScreen> createState() => _AdminLoginScreenState();
}

class _AdminLoginScreenState extends State<AdminLoginScreen> {
  final TextEditingController _mobileController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
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
            await MasjidRepository.streamByAdminMobile(saved).first;
        if (matches.isNotEmpty && mounted) {
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

  // Note: this is a simple mobile-number lookup against Firestore, not a
  // full Firebase Auth login for admins yet. Good enough for now since
  // only someone who registered the masjid would know this number, but
  // a future phase should add real OTP verification here too.
  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isChecking = true);

    final matches = await MasjidRepository.streamByAdminMobile(_mobileController.text).first;

    if (!mounted) return;
    setState(() => _isChecking = false);

    if (matches.isNotEmpty) {
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_key, _mobileController.text.trim());
      } catch (_) {}
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => AdminDashboardScreen(adminMobile: _mobileController.text)),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No masjid found for this number. Register one below.')),
      );
    }
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
      body: Padding(
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
              const Text('Enter the mobile number registered with your masjid', style: TextStyle(color: Colors.grey)),
              const SizedBox(height: 24),
              TextFormField(
                controller: _mobileController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(labelText: 'Mobile Number', prefixIcon: Icon(Icons.phone), border: OutlineInputBorder()),
                validator: (v) => (v == null || v.length < 10) ? 'Enter a valid mobile number' : null,
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
      ),
    );
  }
}
