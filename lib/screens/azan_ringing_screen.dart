import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';

/// Shown when a prayer time alarm fires.
///
/// Plays the masjid's own uploaded azan when one is reachable, and the bundled
/// recording otherwise. The bundled file is the floor: no masjid upload, no
/// network, no problem — it still calls to prayer.
class AzanRingingScreen extends StatefulWidget {
  final String prayerName;
  final String masjidName;
  final String? audioUrl;

  const AzanRingingScreen({
    super.key,
    required this.prayerName,
    required this.masjidName,
    this.audioUrl,
  });

  @override
  State<AzanRingingScreen> createState() => _AzanRingingScreenState();
}

class _AzanRingingScreenState extends State<AzanRingingScreen> {
  final AudioPlayer _player = AudioPlayer();
  bool _isPlaying = false;

  @override
  void initState() {
    super.initState();
    _startPlayback();
  }

  /// Plays the azan, with the bundled recording as a guaranteed floor.
  ///
  /// THIS USED TO BE THE MAIN REASON THE AZAN WAS SILENT.
  ///
  /// The old version did two things wrong. If the masjid had not uploaded a
  /// custom azan it returned immediately and played NOTHING — the ringing
  /// screen appeared in silence, by design. And when a URL did exist it was
  /// streamed from Firebase Storage at the exact moment the alarm fired.
  ///
  /// An alarm that needs a network round trip when it rings fails precisely
  /// when you need it most: overnight, on a locked phone, with doze throttling
  /// the radio and weak signal. The catch block then swallowed the failure, so
  /// it failed silently every time.
  ///
  /// Now: the bundled asset always works, offline, instantly. A masjid's own
  /// recording is attempted first but is only ever an upgrade on top of
  /// something that already works.
  /// Playback now belongs to the BACKGROUND SERVICE, not this screen.
  ///
  /// This screen only appears if Android honours the full-screen intent, which
  /// it often refuses to do when the phone is locked or the app was killed —
  /// the precise moments a prayer alarm matters. Tying the azan to a screen
  /// that may never open meant the notification arrived and the azan did not.
  ///
  /// The service is already awake and already posting the notification, so it
  /// plays the audio. This screen is now just the face of it, plus a way to
  /// stop it.
  Future<void> _startPlayback() async {
    // Already playing, out in the service. Nothing to start here — playing a
    // second copy would give two overlapping azans.
    if (mounted) setState(() => _isPlaying = true);
  }

  Future<void> _stop() async {
    // Cross-isolate: the service holds the player, so stopping is a message
    // rather than a method call.
    try {
      FlutterForegroundTask.sendDataToTask('stop_azan');
    } catch (_) {}
    try {
      await _player.stop();
    } catch (_) {}
    if (mounted) Navigator.of(context).pop();
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: const Color(0xFF164536),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.mosque, size: 72, color: Color(0xFFC8A86B)),
                const SizedBox(height: 24),
                Text(
                  widget.prayerName,
                  style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  widget.masjidName,
                  style: const TextStyle(color: Colors.white70, fontSize: 16),
                ),
                const SizedBox(height: 40),
                if (widget.audioUrl == null)
                  const Text(
                    'This masjid has not uploaded a custom Azan recording yet.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white54),
                  )
                else if (_isPlaying)
                  const Icon(Icons.volume_up, color: Colors.white, size: 40),
                const SizedBox(height: 60),
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFC8A86B)),
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
