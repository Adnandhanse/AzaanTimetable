import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import '../models/masjid.dart';
import '../services/masjid_repository.dart';

class SuperAdminMasjidDetailScreen extends StatefulWidget {
  final Masjid masjid;
  const SuperAdminMasjidDetailScreen({super.key, required this.masjid});

  @override
  State<SuperAdminMasjidDetailScreen> createState() => _SuperAdminMasjidDetailScreenState();
}

class _SuperAdminMasjidDetailScreenState extends State<SuperAdminMasjidDetailScreen> {
  final AudioPlayer _player = AudioPlayer();
  bool _isPlaying = false;
  bool _isUpdating = false;
  late String _currentStatus;

  @override
  void initState() {
    super.initState();
    _currentStatus = widget.masjid.verificationStatus;
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  Future<void> _togglePlayback() async {
    final url = widget.masjid.customAzanAudioUrl;
    if (url == null) return;
    if (_isPlaying) {
      await _player.stop();
      setState(() => _isPlaying = false);
    } else {
      await _player.play(UrlSource(url));
      setState(() => _isPlaying = true);
      _player.onPlayerComplete.listen((_) {
        if (mounted) setState(() => _isPlaying = false);
      });
    }
  }

  Future<void> _setStatus(String status) async {
    setState(() => _isUpdating = true);
    try {
      await MasjidRepository.updateVerificationStatus(widget.masjid.id, status);
      if (!mounted) return;
      setState(() {
        _currentStatus = status;
        _isUpdating = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Status updated to "$status".')),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isUpdating = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e')));
    }
  }

  Color get _statusColor {
    switch (_currentStatus) {
      case 'Verified':
        return Colors.green;
      case 'Rejected':
        return Colors.red;
      default:
        return Colors.orange;
    }
  }

  @override
  Widget build(BuildContext context) {
    final m = widget.masjid;
    return Scaffold(
      appBar: AppBar(
        title: Text(m.name),
        backgroundColor: const Color(0xFF0B1F14),
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(color: _statusColor.withOpacity(0.15), borderRadius: BorderRadius.circular(8)),
            child: Text(_currentStatus, style: TextStyle(color: _statusColor, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(height: 20),

          _sectionTitle('Masjid Details'),
          _row('Name', m.name),
          _row('Registration No.', m.registrationNo.isEmpty ? '—' : m.registrationNo),
          _row('City', m.city),
          _row('Address', m.address),
          _row('Coordinates', m.latitude == 0.0 && m.longitude == 0.0 ? 'Not captured' : '${m.latitude}, ${m.longitude}'),

          const SizedBox(height: 20),
          _sectionTitle('Admin Details'),
          _row('Admin Name', m.adminName),
          _row('Mobile', m.adminMobile),
          _row('Email', m.adminEmail),

          const SizedBox(height: 20),
          _sectionTitle('Prayer Times'),
          _row('Fajr', m.prayerTimes.fajr),
          _row('Dhuhr', m.prayerTimes.dhuhr),
          _row('Asr', m.prayerTimes.asr),
          _row('Maghrib', m.prayerTimes.maghrib),
          _row('Isha', m.prayerTimes.isha),
          _row('Juma', m.prayerTimes.juma),

          const SizedBox(height: 20),
          _sectionTitle('Custom Azan Audio'),
          if (m.customAzanAudioUrl == null)
            const Text('No custom audio uploaded.', style: TextStyle(color: Colors.grey))
          else
            Card(
              child: ListTile(
                leading: const Icon(Icons.audiotrack, color: Color(0xFF14532D)),
                title: Text(m.customAzanAudioName ?? 'Azan audio'),
                trailing: IconButton(
                  icon: Icon(_isPlaying ? Icons.stop_circle : Icons.play_circle, color: const Color(0xFF14532D), size: 32),
                  onPressed: _togglePlayback,
                ),
              ),
            ),

          const SizedBox(height: 28),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.close, color: Colors.red),
                  label: const Text('Reject', style: TextStyle(color: Colors.red)),
                  onPressed: _isUpdating || _currentStatus == 'Rejected' ? null : () => _setStatus('Rejected'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                  icon: const Icon(Icons.check, color: Colors.white),
                  label: const Text('Approve', style: TextStyle(color: Colors.white)),
                  onPressed: _isUpdating || _currentStatus == 'Verified' ? null : () => _setStatus('Verified'),
                ),
              ),
            ],
          ),
          if (_currentStatus == 'Verified')
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                'Already verified. Tap Reject if you need to revoke this later.',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                textAlign: TextAlign.center,
              ),
            ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(text, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
      );

  Widget _row(String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(width: 120, child: Text(label, style: const TextStyle(color: Colors.grey))),
            Expanded(child: Text(value, style: const TextStyle(fontWeight: FontWeight.w500))),
          ],
        ),
      );
}
