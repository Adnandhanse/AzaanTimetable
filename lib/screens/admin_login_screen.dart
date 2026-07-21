import 'package:flutter/material.dart';
import 'register_masjid_screen.dart';
import 'admin_dashboard_screen.dart';
import 'super_admin_login_screen.dart';
import '../data/mock_masjids.dart';

class AdminLoginScreen extends StatefulWidget {
  const AdminLoginScreen({super.key});

  @override
  State<AdminLoginScreen> createState() => _AdminLoginScreenState();
}

class _AdminLoginScreenState extends State<AdminLoginScreen> {
  final TextEditingController _mobileController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  void _login() {
    if (!_formKey.currentState!.validate()) return;

    // Phase 3: mock login — matches against admin mobile numbers already
    // in mock data. Phase 2 will replace this with real Firebase Auth +
    // a check against the masjid_admins collection.
    final match = mockMasjids.where(
      (m) => m.adminMobile == _mobileController.text,
    ).toList();

    if (match.isNotEmpty) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => AdminDashboardScreen(managedMasjids: match),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No masjid found for this number. Register one below.'),
        ),
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
              const Text(
                'Admin Login',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'Enter the mobile number registered with your masjid',
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _mobileController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Mobile Number',
                  prefixIcon: Icon(Icons.phone),
                  border: OutlineInputBorder(),
                ),
                validator: (v) => (v == null || v.length < 10) ? 'Enter a valid mobile number' : null,
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF14532D)),
                  onPressed: _login,
                  child: const Text('Login', style: TextStyle(color: Colors.white, fontSize: 16)),
                ),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const RegisterMasjidScreen()),
                ),
                child: const Text('New masjid? Register here'),
              ),
              const SizedBox(height: 4),
              TextButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const SuperAdminLoginScreen()),
                ),
                child: const Text('Platform Admin Login', style: TextStyle(color: Colors.grey)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
