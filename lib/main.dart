import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:google_fonts/google_fonts.dart';
import 'screens/splash_screen.dart';
import 'screens/azan_ringing_screen.dart';
import 'services/notification_service.dart';
import 'services/app_language.dart';

/// Lets code outside the widget tree (the notification tap callback) push
/// a new screen - used to open the Azan ringing screen when an alarm fires.
final navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  String? initError;
  try {
    await Firebase.initializeApp();
  } catch (e) {
    initError = e.toString();
  }

  await AppLanguageController.instance.load();

  await NotificationService.init(
    onTapPayload: (payload) {
      if (payload == null) return;
      final (prayer, masjidName, audioUrl) = NotificationService.parsePayload(payload);
      navigatorKey.currentState?.push(
        MaterialPageRoute(
          builder: (_) => AzanRingingScreen(prayerName: prayer, masjidName: masjidName, audioUrl: audioUrl),
        ),
      );
    },
  );

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
    return ListenableBuilder(
      listenable: AppLanguageController.instance,
      builder: (context, _) {
        return MaterialApp(
          navigatorKey: navigatorKey,
          title: 'Masjid Namaz Alarm',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            scaffoldBackgroundColor: const Color(0xFFF8F5EE),
            primaryColor: const Color(0xFF1F5E4A),
            colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1F5E4A)).copyWith(
              surface: const Color(0xFFFCFAF5),
            ),
            cardColor: const Color(0xFFFCFAF5),
            fontFamily: GoogleFonts.inter().fontFamily,
            textTheme: GoogleFonts.interTextTheme().apply(
              bodyColor: const Color(0xFF2F3A35),
              displayColor: const Color(0xFF2F3A35),
            ),
            useMaterial3: true,
          ),
          home: const SplashScreen(),
        );
      },
    );
  }
}
