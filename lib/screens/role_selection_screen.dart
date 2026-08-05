import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/app_strings.dart';
import '../theme/app_theme.dart';
import '../widgets/ornaments.dart';
import 'admin_login_screen.dart';
import 'home_screen.dart';

/// Asked once, at the start: are you here to pray, or to run a masjid?
///
/// The two audiences want completely different things. Someone following a
/// masjid wants prayer times and an alarm. Someone running one wants to
/// register it and keep its times up to date. Previously the admin route was
/// reachable only from the fifth tab, which meant every imam had to be told
/// where to look, and every ordinary user carried a tab they will never open.
///
/// The choice is REMEMBERED but not permanent — both routes remain reachable
/// afterwards, because someone can be both, and because a wrong tap here should
/// not lock anyone out of half the app.
class RoleSelectionScreen extends StatelessWidget {
  const RoleSelectionScreen({super.key});

  static const _key = 'user_role_v1';

  /// 'user', 'admin', or null if never asked.
  static Future<String?> savedRole() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_key);
    } catch (_) {
      return null;
    }
  }

  static Future<void> _save(String role) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_key, role);
    } catch (_) {}
  }

  Future<void> _choose(BuildContext context, String role) async {
    await _save(role);
    if (!context.mounted) return;
    final NavigatorState nav = Navigator.of(context);

    if (role == 'admin') {
      // PUSHED, NOT REPLACED, so back returns HERE.
      //
      // This used to pushReplacement, which left nothing beneath the admin
      // login: pressing back exited the app. Someone who tapped the wrong card
      // had to kill the app and reopen it to change their mind.
      //
      // Pushing keeps this screen underneath, so the login's AppBar gets a real
      // back arrow and it comes back to the choice.
      await nav.push(
        MaterialPageRoute<void>(builder: (_) => const AdminLoginScreen()),
      );
      return;
    }

    nav.pushAndRemoveUntil(
      MaterialPageRoute<void>(builder: (_) => const HomeScreen()),
      (Route<dynamic> route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool urdu = S.isUrdu;

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 40, 24, 32),
          children: <Widget>[
            const Center(child: Medallion(icon: Icons.mosque_outlined, size: 62)),
            const SizedBox(height: 22),
            Text(
              urdu ? 'خوش آمدید' : 'Welcome',
              textAlign: TextAlign.center,
              style: AppText.displayName
                  .copyWith(fontSize: 27, color: AppColors.emerald),
            ),
            const SizedBox(height: 8),
            Text(
              urdu
                  ? 'آپ ایپ کیسے استعمال کرنا چاہتے ہیں؟'
                  : 'How will you be using the app?',
              textAlign: TextAlign.center,
              style: AppText.body.copyWith(color: AppColors.textMuted),
            ),
            const SizedBox(height: 26),
            const DiamondRule(),
            const SizedBox(height: 22),

            _RoleCard(
              icon: Icons.person_outline,
              title: urdu ? 'میں نمازی ہوں' : 'I am here to pray',
              lines: <String>[
                urdu ? 'مسجد منتخب کریں اور نماز کے اوقات دیکھیں' : 'Follow a masjid and see its prayer times',
                urdu ? 'اذان کا الارم' : 'Azan alarm at every prayer',
                urdu ? 'قرآن، حدیث اور قبلہ' : 'Quran, Hadith and Qibla',
              ],
              onTap: () => _choose(context, 'user'),
            ),
            const SizedBox(height: 14),
            _RoleCard(
              icon: Icons.admin_panel_settings_outlined,
              title: urdu ? 'میں مسجد کا ذمہ دار ہوں' : 'I manage a masjid',
              lines: <String>[
                urdu ? 'اپنی مسجد رجسٹر کریں' : 'Register your masjid',
                urdu ? 'نماز کے اوقات اپ ڈیٹ کریں' : 'Update its prayer times',
                urdu ? 'اپنی اذان اپ لوڈ کریں' : 'Upload your own azan',
              ],
              onTap: () => _choose(context, 'admin'),
            ),

            const SizedBox(height: 22),
            Text(
              urdu
                  ? 'آپ بعد میں دونوں حصے استعمال کر سکتے ہیں۔'
                  : 'You can use both later — this only decides where you start.',
              textAlign: TextAlign.center,
              style: AppText.caption.copyWith(color: AppColors.textFaint),
            ),
            const SizedBox(height: 10),
            // So this screen is not a dead end either. Reachable again from
            // Settings if someone changes their mind later.
            TextButton(
              onPressed: () => _choose(context, 'user'),
              style: TextButton.styleFrom(foregroundColor: AppColors.textMuted),
              child: Text(
                urdu ? 'ابھی چھوڑ دیں' : 'Skip for now',
                style: AppText.caption.copyWith(color: AppColors.textMuted),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  const _RoleCard({
    required this.icon,
    required this.title,
    required this.lines,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final List<String> lines;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.white,
      borderRadius: BorderRadius.circular(4),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(4),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: AppColors.goldRule),
          ),
          padding: const EdgeInsets.fromLTRB(16, 16, 14, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Medallion(icon: icon, size: 40),
                  const SizedBox(width: 13),
                  Expanded(
                    child: Text(title,
                        style: AppText.rowTitle
                            .copyWith(fontSize: 18, color: AppColors.text)),
                  ),
                  const Icon(Icons.chevron_right,
                      size: 18, color: AppColors.chevron),
                ],
              ),
              const SizedBox(height: 12),
              for (final String l in lines)
                Padding(
                  padding: const EdgeInsets.only(bottom: 5),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      const Padding(
                        padding: EdgeInsets.only(top: 4),
                        child: Icon(Icons.check, size: 13, color: AppColors.gold),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(l,
                            style: AppText.caption
                                .copyWith(color: AppColors.textMuted)),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
