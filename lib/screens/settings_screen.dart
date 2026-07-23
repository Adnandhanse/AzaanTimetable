import 'package:flutter/material.dart';
import 'admin_login_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool azanEnabled = true;
  bool vibrateEnabled = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: const Color(0xFF14532D),
        foregroundColor: Colors.white,
      ),
      body: ListView(
        children: [
          SwitchListTile(
            title: const Text('Azan Sound Alarm'),
            subtitle: const Text('Play Azan when prayer time arrives'),
            value: azanEnabled,
            onChanged: (v) => setState(() => azanEnabled = v),
          ),
          SwitchListTile(
            title: const Text('Vibrate'),
            subtitle: const Text('Vibrate along with notification'),
            value: vibrateEnabled,
            onChanged: (v) => setState(() => vibrateEnabled = v),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.admin_panel_settings, color: Color(0xFF14532D)),
            title: const Text('Masjid Admin / Register a Masjid'),
            subtitle: const Text('For imams and masjid trustees'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const AdminLoginScreen()),
            ),
          ),
        ],
      ),
    );
  }
}
