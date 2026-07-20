import 'package:flutter/material.dart';
import 'screens/splash_screen.dart';

void main() {
  runApp(const MasjidAlarmApp());
}

class MasjidAlarmApp extends StatelessWidget {
  const MasjidAlarmApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Masjid Namaz Alarm',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: const Color(0xFF14532D),
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF14532D)),
        useMaterial3: true,
      ),
      home: const SplashScreen(),
    );
  }
}
