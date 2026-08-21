import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/notification_service.dart';
import 'alarm_health_screen.dart';
import 'hijri_calendar_screen.dart';
import 'role_selection_screen.dart';
import '../services/app_language.dart';
import '../services/app_strings.dart';

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
      ),
      body: ListView(
        children: [
          ListTile(
            leading: Icon(Icons.language, color: AppColors.emerald),
            title: Text(S.appLanguage),
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
            title: Text(S.azanSoundAlarm),
            subtitle: const Text('Play Azan when prayer time arrives'),
            value: azanEnabled,
            onChanged: (v) => setState(() => azanEnabled = v),
          ),
          SwitchListTile(
            title: Text(S.vibrate),
            subtitle: const Text('Vibrate along with notification'),
            value: vibrateEnabled,
            onChanged: (v) => setState(() => vibrateEnabled = v),
          ),
          const Divider(),
          // CREDITS AND LICENCES.
          //
          // Noto Nastaliq is OFL, which requires its copyright notice to
          // travel with the font. That doesn't demand a visible screen, but
          // an app that ships other people's work should say so — and if
          // anyone ever asks, the answer is already in the app.
          ListTile(
            leading: const Icon(Icons.info_outline, color: AppColors.emerald),
            title: Text(S.isUrdu ? 'ایپ کے بارے میں' : 'About & credits'),
            trailing: const Icon(Icons.chevron_right, size: 18),
            onTap: () => showDialog<void>(
              context: context,
              builder: (ctx) => AlertDialog(
                backgroundColor: AppColors.white,
                title: Text('Islam Connect',
                    style: AppText.rowTitle.copyWith(color: AppColors.emerald)),
                content: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('Fonts', style: AppText.eyebrow.copyWith(color: AppColors.gold)),
                      const SizedBox(height: 4),
                      Text(
                        'Qur\u2019an text is set in PDMS Saleem QuranFont.',
                        style: AppText.caption.copyWith(color: AppColors.textMid),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Urdu text is set in Noto Nastaliq Urdu, and Arabic '
                        'elsewhere in Amiri \u2014 both under the SIL Open Font License.',
                        style: AppText.caption.copyWith(color: AppColors.textMid),
                      ),
                      const SizedBox(height: 14),
                      Text('Text', style: AppText.eyebrow.copyWith(color: AppColors.gold)),
                      const SizedBox(height: 4),
                      Text(
                        'Hadith collections and dua text from published open '
                        'datasets. Qur\u2019an translations from public editions.\n\n'
                        'Prayer times are supplied by each masjid\u2019s own '
                        'administrators. Hijri dates are calculated and local '
                        'moon sighting may differ by a day.',
                        style: AppText.caption.copyWith(color: AppColors.textMid),
                      ),
                    ],
                  ),
                ),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.of(ctx).pop(),
                      child: const Text('Close')),
                ],
              ),
            ),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.calendar_month_outlined,
                color: AppColors.emerald),
            title: Text(S.isUrdu ? 'اسلامی کیلنڈر' : 'Hijri calendar'),
            subtitle: Text(S.isUrdu
                ? 'اسلامی اور عیسوی تاریخیں ساتھ ساتھ'
                : 'Hijri and Gregorian dates side by side'),
            trailing: const Icon(Icons.chevron_right, size: 18),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const HijriCalendarScreen()),
            ),
          ),
          const Divider(),
          // So the role choice is changeable. It is asked once at first launch;
          // without this, someone who picked wrong could only change it by
          // reinstalling.
          ListTile(
            leading: const Icon(Icons.switch_account_outlined,
                color: AppColors.emerald),
            title: Text(S.isUrdu ? 'استعمال کا طریقہ' : 'How you use the app'),
            subtitle: Text(S.isUrdu
                ? 'نمازی یا مسجد کا ذمہ دار'
                : 'Switch between worshipper and masjid admin'),
            trailing: const Icon(Icons.chevron_right, size: 18),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const RoleSelectionScreen()),
            ),
          ),
          const Divider(),
          // Put the diagnostics first. When alarms miss, this is the screen
          // that separates "a permission is off" from "the phone is killing
          // the app" — they look identical from the outside and need
          // completely different fixes.
          ListTile(
            leading: const Icon(Icons.health_and_safety_outlined,
                color: AppColors.emerald),
            title: const Text('Alarm health'),
            subtitle: const Text(
                'Check why alarms may not fire, and test one on this phone'),
            trailing: const Icon(Icons.chevron_right, size: 18),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const AlarmHealthScreen()),
            ),
          ),
          // "Enable Guaranteed Azan Popup" removed along with the overlay. It
          // asked for the one permission Google scrutinises hardest, to enable
          // something that turned out to be unnecessary.
          const Divider(),
          ListTile(
            leading: const Icon(Icons.battery_alert, color: Colors.orange),
            title: const Text('Disable Battery Optimization'),
            subtitle: const Text('Important: needed for alarms to fire reliably'),
            onTap: () => NotificationService.requestIgnoreBatteryOptimizations(),
          ),
          // The three debug entries that lived here are gone: Send Test
          // Notification Now, Show My Account ID, and Check Scheduled Alarms.
          //
          // They existed to diagnose the alarm problem, which is fixed. Leaving
          // them in ships a settings screen where three of eight rows are
          // labelled "Debug:" — which tells a user this is unfinished software.
          // Everything they did is still available in Alarm health.
        ],
      ),
    );
  }
}
