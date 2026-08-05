import 'dart:math';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/auth_service.dart';
import '../services/app_language.dart';
import 'home_screen.dart';
import 'admin_login_screen.dart';
import 'role_selection_screen.dart';
import 'language_selection_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat();

    Future.delayed(const Duration(seconds: 3), () async {
      // No OTP for regular users - sign in anonymously (free, instant) so
      // we can still remember which masjid they follow. OTP is reserved
      // only for masjid admins registering a masjid, to keep SMS costs down.
      try {
        await AuthService.signInAnonymouslyIfNeeded().timeout(const Duration(seconds: 10));
      } catch (_) {
        // If anonymous sign-in fails (e.g. not enabled in Firebase yet),
        // still let the user into the app rather than hanging forever -
        // masjid-following just won't persist until this is fixed.
      }
      if (!mounted) return;

      // Language, then role, then the app.
      //
      // Role comes AFTER language so the two choices are not both in a language
      // the user may not read. It is asked only once; after that the saved
      // answer decides where they land.
      final Widget nextScreen;
      if (!AppLanguageController.instance.hasChosenLanguage) {
        nextScreen = const LanguageSelectionScreen();
      } else {
        final String? role = await RoleSelectionScreen.savedRole();
        if (role == null) {
          nextScreen = const RoleSelectionScreen();
        } else if (role == 'admin') {
          nextScreen = const AdminLoginScreen();
        } else {
          nextScreen = const HomeScreen();
        }
      }
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => nextScreen),
      );
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.emerald, AppColors.emerald, AppColors.emerald],
          ),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return SizedBox(
                  width: 260,
                  height: 260,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        width: 70,
                        height: 70,
                        decoration: BoxDecoration(
                          color: const Color(0xFF1A1A1A),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: AppColors.gold, width: 2),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.gold.withOpacity(0.4),
                              blurRadius: 20,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: Center(
                          child: Container(width: 40, height: 6, color: AppColors.gold),
                        ),
                      ),
                      ...List.generate(8, (i) {
                        final baseAngle = (2 * pi / 8) * i;
                        final angle = baseAngle + (_controller.value * 2 * pi);
                        const radius = 110.0;
                        final dx = radius * cos(angle);
                        final dy = radius * sin(angle) * 0.55;
                        return Transform.translate(
                          offset: Offset(dx, dy),
                          child: _Pilgrim(scale: 0.7 + 0.3 * ((dy + 60) / 120)),
                        );
                      }),
                    ],
                  ),
                );
              },
            ),
            const Positioned(
              bottom: 90,
              child: Column(
                children: [
                  Text(
                    'Masjid Namaz Alarm',
                    style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                  ),
                  SizedBox(height: 6),
                  Text('Never miss a prayer time', style: TextStyle(color: Colors.white70, fontSize: 14)),
                ],
              ),
            ),
            const Positioned(
              bottom: 40,
              child: SizedBox(width: 28, height: 28, child: CircularProgressIndicator(color: Colors.white54, strokeWidth: 2)),
            ),
          ],
        ),
      ),
    );
  }
}

class _Pilgrim extends StatelessWidget {
  final double scale;
  const _Pilgrim({required this.scale});

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: 0.55 + 0.45 * scale,
      child: Transform.scale(
        scale: scale,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 8, height: 8, decoration: const BoxDecoration(color: Color(0xFFF5E9D3), shape: BoxShape.circle)),
            const SizedBox(height: 1),
            ClipPath(clipper: _RobeClipper(), child: Container(width: 16, height: 20, color: Colors.white)),
          ],
        ),
      ),
    );
  }
}

class _RobeClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.moveTo(size.width / 2, 0);
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}
