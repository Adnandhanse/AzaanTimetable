import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
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

class _SplashScreenState extends State<SplashScreen> {
  VideoPlayerController? _video;

  @override
  void initState() {
    super.initState();
    _initVideo();

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
      bool pushAdminOnTop = false;
      if (!AppLanguageController.instance.hasChosenLanguage) {
        nextScreen = const LanguageSelectionScreen();
      } else {
        final String? role = await RoleSelectionScreen.savedRole();
        if (role == null) {
          nextScreen = const RoleSelectionScreen();
        } else if (role == 'admin') {
          // Home underneath, admin login on top - same reason as in the role
          // screen: an admin landing directly on a login with nothing beneath it
          // had no way back except closing the app.
          nextScreen = const HomeScreen();
          pushAdminOnTop = true;
        } else {
          nextScreen = const HomeScreen();
        }
      }
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => nextScreen),
      );
      if (pushAdminOnTop) {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const AdminLoginScreen()),
        );
      }
    });
  }

  Future<void> _initVideo() async {
    try {
      final c = VideoPlayerController.asset('assets/video/intro.mp4');
      await c.initialize();
      await c.setVolume(0);
      await c.setLooping(true);
      await c.play();
      if (!mounted) {
        await c.dispose();
        return;
      }
      setState(() => _video = c);
    } catch (_) {
      // Falls back to the plain background. Never blocks startup.
    }
  }

  @override
  void dispose() {
    _video?.dispose();
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
            // The supplied tawaf clip, replacing the drawn animation.
            //
            // MUTED, ALWAYS. It has an audio track, and a prayer app that makes
            // noise the instant it opens is a prayer app people close in a
            // mosque. Looped, because it is 2.4 seconds and startup can take
            // longer than that on a cold start.
            //
            // If the video fails for any reason — codec, decoder busy, a device
            // that cannot play it — the screen falls back to the plain emerald
            // background rather than showing an error. Startup must never be
            // blocked by decoration.
            if (_video != null && _video!.value.isInitialized)
              // Fills the screen.
              //
              // The clip is now PORTRAIT (478x850), which is why this works
              // properly. The previous landscape clip lost about 75% of its
              // width to the crop — everything but a narrow centre strip. This
              // one loses under 20%, so the framing survives.
              //
              // The video is 5 seconds and the splash lasts 3, so it is cut
              // short rather than looping. That is fine, and better than a
              // visible restart mid-splash.
              SizedBox.expand(
                child: FittedBox(
                  fit: BoxFit.cover,
                  clipBehavior: Clip.hardEdge,
                  child: SizedBox(
                    width: _video!.value.size.width,
                    height: _video!.value.size.height,
                    child: VideoPlayer(_video!),
                  ),
                ),
              ),

            const Positioned(
              bottom: 90,
              child: Column(
                children: [
                  Text(
                    'Islam Connect',
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


