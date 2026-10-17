import 'package:flutter/material.dart';
import '../services/azan_stop_controller.dart';

/// Prayer reminder screen. The background service owns playback; this screen
/// sends the same persisted stop command as the notification action.
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

  bool _stopping = false;

  Future<void> _stop() async {
    if (_stopping) return;
    setState(() => _stopping = true);
    await AzanStopController.stop();
    if (mounted) {
      Navigator.of(context).pop();
    }
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
                const Icon(Icons.graphic_eq, color: Color(0xFFC8A86B), size: 46),
                const SizedBox(height: 12),
                const Text('Prayer reminder', style: TextStyle(color: Colors.white70, fontSize: 16)),
                const SizedBox(height: 60),
                SizedBox(
                  width: double.infinity,
                  height: 64,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFC8A86B),
                      foregroundColor: const Color(0xFF123D2D),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                    ),
                    onPressed: _stopping ? null : _stop,
                    icon: const Icon(Icons.stop_circle_rounded, size: 28),
                    label: Text(_stopping ? 'STOPPING…' : 'STOP AZAAN',
                      style: const TextStyle(fontSize: 19, fontWeight: FontWeight.bold, letterSpacing: 0.8)),
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
