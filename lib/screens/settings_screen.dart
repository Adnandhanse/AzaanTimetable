import 'package:flutter/material.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart' as overlay;
import '../services/notification_service.dart';
import '../services/auth_service.dart';
import '../services/app_language.dart';

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
          ListTile(
            leading: const Icon(Icons.language, color: Color(0xFF14532D)),
            title: const Text('App Language'),
            subtitle: Text(AppLanguageController.instance.isUrdu ? 'اردو (Urdu)' : 'English'),
            trailing: DropdownButton<AppLanguage>(
              value: AppLanguageController.instance.language,
              underline: const SizedBox(),
              items: const [
                DropdownMenuItem(value: AppLanguage.english, child: Text('English')),
                DropdownMenuItem(value: AppLanguage.urdu, child: Text('اردو')),
              ],
              onChanged: (lang) {
                if (lang != null) {
                  AppLanguageController.instance.setLanguage(lang);
                  setState(() {});
                }
              },
            ),
          ),
          const Divider(),
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
            leading: const Icon(Icons.picture_in_picture_alt, color: Colors.orange),
            title: const Text('Enable Guaranteed Azan Popup'),
            subtitle: const Text('Important: makes the Azan screen appear even while using your phone'),
            onTap: () async {
              await overlay.FlutterOverlayWindow.requestPermission();
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.battery_alert, color: Colors.orange),
            title: const Text('Disable Battery Optimization'),
            subtitle: const Text('Important: needed for alarms to fire reliably'),
            onTap: () => NotificationService.requestIgnoreBatteryOptimizations(),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.notifications_active, color: Colors.grey),
            title: const Text('Send Test Notification Now'),
            subtitle: const Text('Debug: checks if notifications work at all on this phone'),
            onTap: () async {
              await NotificationService.showTestNotificationNow();
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Test notification sent - check your notification shade now.')),
              );
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.fingerprint, color: Colors.grey),
            title: const Text('Show My Account ID'),
            subtitle: const Text('Debug: check if this changes after a phone restart'),
            onTap: () {
              final uid = AuthService.currentUser?.uid ?? 'Not signed in';
              showDialog(
                context: context,
                builder: (_) => AlertDialog(
                  title: const Text('Account ID'),
                  content: SelectableText(uid),
                  actions: [TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Close'))],
                ),
              );
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.bug_report, color: Colors.grey),
            title: const Text('Check Scheduled Alarms'),
            subtitle: const Text('Debug: see what alarms are currently set'),
            onTap: () async {
              final pending = await NotificationService.getPendingAlarms();
              if (!context.mounted) return;
              showDialog(
                context: context,
                builder: (_) => AlertDialog(
                  title: const Text('Scheduled Alarms'),
                  content: SingleChildScrollView(
                    child: Text(pending.isEmpty ? 'Nothing is currently scheduled.' : pending.join('\n')),
                  ),
                  actions: [
                    TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Close')),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
