import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'screens/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
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
