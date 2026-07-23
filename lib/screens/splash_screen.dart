import 'dart:math';
import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'home_screen.dart';

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
      await AuthService.signInAnonymouslyIfNeeded();
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const HomeScreen()),
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
            colors: [Color(0xFF0B1F14), Color(0xFF14532D), Color(0xFF0B1F14)],
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
                          border: Border.all(color: const Color(0xFFD4AF37), width: 2),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFD4AF37).withOpacity(0.4),
                              blurRadius: 20,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: Center(
                          child: Container(width: 40, height: 6, color: const Color(0xFFD4AF37)),
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
