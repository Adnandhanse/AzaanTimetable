import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../models/masjid.dart';
import '../services/masjid_repository.dart';

class UpdatePrayerTimesScreen extends StatefulWidget {
  final Masjid masjid;
  const UpdatePrayerTimesScreen({super.key, required this.masjid});

  @override
  State<UpdatePrayerTimesScreen> createState() => _UpdatePrayerTimesScreenState();
}

class _UpdatePrayerTimesScreenState extends State<UpdatePrayerTimesScreen> {
  late String _fajr;
  late String _dhuhr;
  late String _asr;
  late String _maghrib;
  late String _isha;
  late String _juma;

  final AudioPlayer _player = AudioPlayer();
  bool _isPlaying = false;
  bool _isSaving = false;
  bool _isUploadingAudio = false;

  late String? _audioName;
  late String? _audioUrl;

  @override
  void initState() {
    super.initState();
    final t = widget.masjid.prayerTimes;
    _fajr = t.fajr;
    _dhuhr = t.dhuhr;
    _asr = t.asr;
    _maghrib = t.maghrib;
    _isha = t.isha;
    _juma = t.juma;
    _audioName = widget.masjid.customAzanAudioName;
    _audioUrl = widget.masjid.customAzanAudioUrl;
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  bool get _isVerified => widget.masjid.verificationStatus == 'Verified';

  /// Formats a picked TimeOfDay into a clean "5:15 AM" style string,
  /// so it's always unambiguous and never has garbled/free-typed text.
  String _formatTime(TimeOfDay t) {
    final hour = t.hourOfPeriod == 0 ? 12 : t.hourOfPeriod;
    final minute = t.minute.toString().padLeft(2, '0');
    final period = t.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour:$minute $period';
  }

  /// Tries to parse an existing "5:15 AM" style string back into a
  /// TimeOfDay, so the picker opens showing the current value.
  TimeOfDay? _parseExisting(String value) {
    try {
      if (value.trim() == '--:--' || value.trim().isEmpty) return null;
      final parts = value.trim().split(' ');
      final hm = parts[0].split(':');
      int hour = int.parse(hm[0]);
      final minute = int.parse(hm[1]);
      final isPM = parts.length > 1 && parts[1].toUpperCase() == 'PM';
      if (isPM && hour != 12) hour += 12;
      if (!isPM && hour == 12) hour = 0;
      return TimeOfDay(hour: hour, minute: minute);
    } catch (_) {
      return null;
    }
  }

  Future<void> _pickTime(String currentValue, void Function(String) onPicked) async {
    final initial = _parseExisting(currentValue) ?? TimeOfDay.now();
    final picked = await showTimePicker(
      context: context,
      initialTime: initial,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyOf(alwaysUse24HourFormat: false),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() => onPicked(_formatTime(picked)));
    }
  }

  Future<void> _saveTimes() async {
    setState(() => _isSaving = true);
    final times = PrayerTimes(fajr: _fajr, dhuhr: _dhuhr, asr: _asr, maghrib: _maghrib, isha: _isha, juma: _juma);
    try {
      await MasjidRepository.updatePrayerTimes(widget.masjid.id, times);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Prayer times updated for everyone following this masjid.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to save: $e')));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _pickAzanAudio() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.audio);
    if (result == null || result.files.isEmpty || result.files.first.path == null) return;

    final file = File(result.files.first.path!);
    final fileName = result.files.first.name;

    setState(() => _isUploadingAudio = true);
    try {
      final ref = FirebaseStorage.instance.ref('azan_audio/${widget.masjid.id}/$fileName');
      await ref.putFile(file);
      final url = await ref.getDownloadURL();
      await MasjidRepository.updateAzanAudio(widget.masjid.id, fileName, url);

      if (!mounted) return;
      setState(() {
        _audioName = fileName;
        _audioUrl = url;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Azan audio uploaded - now live for everyone following this masjid.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Upload failed: $e')));
    } finally {
      if (mounted) setState(() => _isUploadingAudio = false);
    }
  }

  Future<void> _togglePlayback() async {
    if (_audioUrl == null) return;
    if (_isPlaying) {
      await _player.stop();
      setState(() => _isPlaying = false);
    } else {
      await _player.play(UrlSource(_audioUrl!));
      setState(() => _isPlaying = true);
      _player.onPlayerComplete.listen((_) {
        if (mounted) setState(() => _isPlaying = false);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.masjid.name),
        backgroundColor: const Color(0xFF14532D),
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (!_isVerified)
            Card(
              color: const Color(0xFFFFF7ED),
              child: const Padding(
                padding: EdgeInsets.all(12),
                child: Row(
                  children: [
                    Icon(Icons.hourglass_top, color: Colors.orange),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'This masjid is still Pending Verification. Changes are saved '
                        'but followers will only see this masjid once it is verified.',
                      ),
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 16),
          const Text('Prayer Times', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const Text('Tap any prayer to set its time', style: TextStyle(color: Colors.grey, fontSize: 13)),
          const SizedBox(height: 8),
          _timeTile('Fajr', _fajr, (v) => _fajr = v),
          _timeTile('Dhuhr', _dhuhr, (v) => _dhuhr = v),
          _timeTile('Asr', _asr, (v) => _asr = v),
          _timeTile('Maghrib', _maghrib, (v) => _maghrib = v),
          _timeTile('Isha', _isha, (v) => _isha = v),
          _timeTile('Juma (Friday)', _juma, (v) => _juma = v),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF14532D)),
              onPressed: _isSaving ? null : _saveTimes,
              child: _isSaving
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text('Save Prayer Times', style: TextStyle(color: Colors.white)),
            ),
          ),
          const Divider(height: 40),
          const Text('Custom Azan Audio', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          const Text(
            'Upload your own Azan recording - it will play for everyone following this masjid.',
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 12),
          if (_audioName != null)
            Card(
              child: ListTile(
                leading: const Icon(Icons.audiotrack, color: Color(0xFF14532D)),
                title: Text(_audioName!),
                trailing: IconButton(
                  icon: Icon(_isPlaying ? Icons.stop_circle : Icons.play_circle, color: const Color(0xFF14532D), size: 32),
                  onPressed: _togglePlayback,
                ),
              ),
            ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            icon: _isUploadingAudio
                ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.mic),
            label: Text(_isUploadingAudio ? 'Uploading...' : (_audioName == null ? 'Upload Azan Recording' : 'Replace Recording')),
            onPressed: _isUploadingAudio ? null : _pickAzanAudio,
          ),
        ],
      ),
    );
  }

  Widget _timeTile(String label, String value, void Function(String) onPicked) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        title: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              value.trim() == '--:--' || value.trim().isEmpty ? 'Not set' : value,
              style: TextStyle(
                fontSize: 16,
                color: value.trim() == '--:--' || value.trim().isEmpty ? Colors.grey : const Color(0xFF14532D),
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 6),
            const Icon(Icons.access_time, color: Color(0xFF14532D)),
          ],
        ),
        onTap: () => _pickTime(value, onPicked),
      ),
    );
  }
}
