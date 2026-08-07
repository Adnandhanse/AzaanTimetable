import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'screens/setup_wizard_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'screens/splash_screen.dart';
import 'screens/azan_ringing_screen.dart';
import 'services/notification_service.dart';
import 'services/app_language.dart';
import 'services/follower_service.dart';
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
  // One counter increment per device per day. No user record, no timestamp
  // against anybody — just "how many devices opened the app today".
  try {
    await FollowerService.markActiveToday();
  } catch (_) {}

  // Errors are recorded rather than swallowed. Startup must not be blocked by
  // a scheduling problem, but an alarm app that loses its alarms without
  // leaving a trace is worse than one that crashes — the diagnostics land on
  // Settings > Alarm health.
  // Has the user been through alarm setup yet? If not, the wizard is shown
  // instead of the splash screen. A prayer alarm missing one permission is not
  // partly working, it is broken, so this comes before anything else.
  // Show the setup wizard on first launch, AND AGAIN whenever something it
  // asked for has gone missing.
  //
  // It used to appear only if 'alarm_setup_done_v1' was false, so tapping
  // through it once silenced it forever. That is wrong for permissions: the
  // user can revoke them, an OS update can reset them, and Samsung can quietly
  // re-restrict the app. The one thing the app cannot afford to be quiet about
  // is a prayer alarm that will not fire.
  //
  // 'alarm_setup_dismissed_v1' is the escape hatch — if the user chooses not to
  // be asked again, it stops for good.
  bool needsSetup = false;
  try {
    final prefs = await SharedPreferences.getInstance();
    final bool done = prefs.getBool('alarm_setup_done_v1') ?? false;
    final bool dismissed = prefs.getBool('alarm_setup_dismissed_v1') ?? false;

    if (!done) {
      needsSetup = true;
    } else if (!dismissed) {
      final health = await NotificationService.alarmHealth();
      needsSetup = health.values.any((bool ok) => !ok);
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

    runApp(initError == null
      ? MasjidAlarmApp(needsSetup: needsSetup)
      : _FirebaseErrorApp(error: initError));
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
  const MasjidAlarmApp({super.key, this.needsSetup = false});

  final bool needsSetup;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: AppLanguageController.instance,
      builder: (context, _) {
        return MaterialApp(
          navigatorKey: navigatorKey,
          title: 'Islam Connect',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light(),
          home: needsSetup
              ? const _SetupGate()
              : const SplashScreen(),
        );
      },
    );
  }
}

/// Shows the alarm setup wizard once, then hands over to the normal app.
class _SetupGate extends StatefulWidget {
  const _SetupGate();

  @override
  State<_SetupGate> createState() => _SetupGateState();
}

class _SetupGateState extends State<_SetupGate> {
  bool _done = false;

  @override
  Widget build(BuildContext context) {
    if (_done) return const SplashScreen();
    return SetupWizardScreen(
      onFinished: () async {
        try {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setBool('alarm_setup_done_v1', true);
        } catch (_) {}
        if (mounted) setState(() => _done = true);
      },
    );
  }
}
