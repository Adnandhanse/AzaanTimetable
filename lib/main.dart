import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'screens/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  String? initError;
  try {
    await Firebase.initializeApp();
  } catch (e) {
    initError = e.toString();
  }
  runApp(initError == null ? const MasjidAlarmApp() : _FirebaseErrorApp(error: initError));
}

/// Shown instead of crashing silently if Firebase fails to initialize,
/// so we can actually see what went wrong.
class _FirebaseErrorApp extends StatelessWidget {
  final String error;
  const _FirebaseErrorApp({required this.error});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: Colors.red.shade50,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Firebase failed to start',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.red),
                ),
                const SizedBox(height: 12),
                const Text('Please screenshot this and send it back:'),
                const SizedBox(height: 12),
                Expanded(
                  child: SingleChildScrollView(
                    child: SelectableText(error, style: const TextStyle(fontFamily: 'monospace')),
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
