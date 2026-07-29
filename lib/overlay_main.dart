import 'package:flutter/material.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';
import 'package:audioplayers/audioplayers.dart';

/// This is a SEPARATE, minimal Flutter entry point that runs as a system
/// overlay - it draws directly on top of whatever the user is doing
/// (any app, or even the lock screen), the same technique used by
/// incoming-call screens and chat-head style apps. This is stronger and
/// more reliable than a notification's "full screen intent", which
/// Android only auto-launches when the phone is locked - this overlay
/// shows regardless of lock state.
@pragma('vm:entry-point')
void overlayMain() {
  runApp(const _OverlayAzanApp());
}

class _OverlayAzanApp extends StatefulWidget {
  const _OverlayAzanApp();

  @override
  State<_OverlayAzanApp> createState() => _OverlayAzanAppState();
}

class _OverlayAzanAppState extends State<_OverlayAzanApp> {
  String _prayerName = 'Prayer';
  String _masjidName = '';
  String? _audioUrl;
  final AudioPlayer _player = AudioPlayer();
  bool _isPlaying = false;

  @override
  void initState() {
    super.initState();
    FlutterOverlayWindow.overlayListener.listen((event) {
      if (event is Map) {
        setState(() {
          _prayerName = event['prayer'] ?? 'Prayer';
          _masjidName = event['masjid'] ?? '';
          _audioUrl = event['audioUrl'];
        });
        _startPlayback();
      }
    });
  }

  Future<void> _startPlayback() async {
    if (_audioUrl == null || _audioUrl!.isEmpty) return;
    try {
      await _player.play(UrlSource(_audioUrl!));
      setState(() => _isPlaying = true);
    } catch (_) {
      // Silently continue - the visual alert alone still serves its purpose.
    }
  }

  Future<void> _stop() async {
    await _player.stop();
    await FlutterOverlayWindow.closeOverlay();
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: const Color(0xFF0B1F14),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.mosque, size: 72, color: Color(0xFFD4AF37)),
                const SizedBox(height: 24),
                Text(_prayerName, style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text(_masjidName, style: const TextStyle(color: Colors.white70, fontSize: 16)),
                const SizedBox(height: 40),
                if (_isPlaying) const Icon(Icons.volume_up, color: Colors.white, size: 40),
                const SizedBox(height: 60),
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFD4AF37)),
                    onPressed: _stop,
                    child: const Text('Stop', style: TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.bold)),
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
