import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_core/firebase_core.dart';
import 'screens/splash_screen.dart';
import 'screens/azan_ringing_screen.dart';
import 'services/notification_service.dart';
import 'services/app_language.dart';
import 'theme/app_theme.dart';

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

  // Arm alarms from the DEVICE CACHE before anything touches the network.
  //
  // Previously alarms were only armed when Home's Firestore stream emitted, so
  // opening the app on a bad connection scheduled nothing at all. Firestore
  // updates prayer times; it must never be what decides whether an alarm
  // exists. Failures here are swallowed on purpose — a scheduling problem must
  // not stop the app from opening.
  // Errors are recorded rather than swallowed. Startup must not be blocked by
  // a scheduling problem, but an alarm app that loses its alarms without
  // leaving a trace is worse than one that crashes — the diagnostics land on
  // Settings > Alarm health.
  // Ask for everything the alarm needs, once, on first launch.
  // A prayer alarm missing one permission is not partly working, it is broken
  // — so there is nothing to gain by asking for them lazily.
  try {
    final prefs = await SharedPreferences.getInstance();
    if (!(prefs.getBool('permissions_requested_v1') ?? false)) {
      await NotificationService.requestAllPermissions();
      await prefs.setBool('permissions_requested_v1', true);
    }
  } catch (_) {}

  // Errors are recorded rather than swallowed. Startup must not be blocked by
  // a scheduling problem, but an alarm app that loses its alarms without
  // leaving a trace is worse than one that crashes — the diagnostics land on
  // Settings > Alarm health.
  try {
    await NotificationService.scheduleFromCache();
  } catch (e) {
    debugPrint('Alarm scheduling failed at startup: $e');
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
    return ListenableBuilder(
      listenable: AppLanguageController.instance,
      builder: (context, _) {
        return MaterialApp(
          navigatorKey: navigatorKey,
          title: 'Masjid Namaz Alarm',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light(),
          home: const SplashScreen(),
        );
      },
    );
  }
}
