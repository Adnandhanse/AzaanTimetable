import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';

/// Shown when a prayer time alarm fires - plays the masjid's Azan audio
/// (their custom upload if they have one, otherwise the phone vibrates
/// with a visual reminder only, since we don't bundle a default Azan
/// recording - that would need a properly licensed audio file).
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

  Future<void> _startPlayback() async {
    if (widget.audioUrl == null) return;
    try {
      await _player.play(UrlSource(widget.audioUrl!));
      if (mounted) setState(() => _isPlaying = true);
    } catch (_) {
      // If playback fails (e.g. no internet right now), the screen still
      // shows so the user knows it's prayer time, just silently.
    }
  }

  Future<void> _stop() async {
    await _player.stop();
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
        backgroundColor: const Color(0xFF0B1F14),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.mosque, size: 72, color: Color(0xFFD4AF37)),
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
