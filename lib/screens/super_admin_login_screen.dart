import 'package:flutter/material.dart';
import 'super_admin_dashboard_screen.dart';

class SuperAdminLoginScreen extends StatefulWidget {
  const SuperAdminLoginScreen({super.key});

  @override
  State<SuperAdminLoginScreen> createState() => _SuperAdminLoginScreenState();
}

class _SuperAdminLoginScreenState extends State<SuperAdminLoginScreen> {
  final TextEditingController _username = TextEditingController();
  final TextEditingController _password = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  String? _error;

  // Phase 3: hardcoded credentials for testing only.
  // Phase 2 (Firebase) will replace this with a real, securely stored
  // platform-admin account (Firebase Auth + a custom claim/role check).
  static const String _mockUsername = 'admin';
  static const String _mockPassword = 'admin123';

  void _login() {
    if (!_formKey.currentState!.validate()) return;
    if (_username.text == _mockUsername && _password.text == _mockPassword) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const SuperAdminDashboardScreen()),
      );
    } else {
      setState(() => _error = 'Invalid username or password');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B1F14),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.shield, size: 56, color: Color(0xFFD4AF37)),
                const SizedBox(height: 12),
                const Text(
                  'Platform Admin',
                  style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 24),
                TextFormField(
                  controller: _username,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'Username',
                    labelStyle: TextStyle(color: Colors.white70),
                    enabledBorder: OutlineInputBorder(),
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _password,
                  obscureText: true,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'Password',
                    labelStyle: TextStyle(color: Colors.white70),
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
                ),
                if (_error != null) ...[
                  const SizedBox(height: 10),
                  Text(_error!, style: const TextStyle(color: Colors.redAccent)),
                ],
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFD4AF37)),
                    onPressed: _login,
                    child: const Text('Login', style: TextStyle(color: Colors.black, fontSize: 16)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
