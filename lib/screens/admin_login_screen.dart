import 'package:flutter/material.dart';
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Masjid Admin Login'),
        backgroundColor: const Color(0xFF14532D),
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.admin_panel_settings, size: 56, color: Color(0xFF14532D)),
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
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF14532D)),
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
