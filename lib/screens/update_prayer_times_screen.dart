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
  late TextEditingController _fajr;
  late TextEditingController _dhuhr;
  late TextEditingController _asr;
  late TextEditingController _maghrib;
  late TextEditingController _isha;
  late TextEditingController _juma;

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
    _fajr = TextEditingController(text: t.fajr);
    _dhuhr = TextEditingController(text: t.dhuhr);
    _asr = TextEditingController(text: t.asr);
    _maghrib = TextEditingController(text: t.maghrib);
    _isha = TextEditingController(text: t.isha);
    _juma = TextEditingController(text: t.juma);
    _audioName = widget.masjid.customAzanAudioName;
    _audioUrl = widget.masjid.customAzanAudioUrl;
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  bool get _isVerified => widget.masjid.verificationStatus == 'Verified';

  Future<void> _saveTimes() async {
    setState(() => _isSaving = true);
    final times = PrayerTimes(
      fajr: _fajr.text,
      dhuhr: _dhuhr.text,
      asr: _asr.text,
      maghrib: _maghrib.text,
      isha: _isha.text,
      juma: _juma.text,
    );
    try {
      await MasjidRepository.updatePrayerTimes(widget.masjid.id, times);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Prayer times updated for everyone following this masjid.')));
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
          const SizedBox(height: 8),
          _timeField(_fajr, 'Fajr'),
          _timeField(_dhuhr, 'Dhuhr'),
          _timeField(_asr, 'Asr'),
          _timeField(_maghrib, 'Maghrib'),
          _timeField(_isha, 'Isha'),
          _timeField(_juma, 'Juma (Friday)'),
          const SizedBox(height: 8),
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

  Widget _timeField(TextEditingController c, String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextField(
        controller: c,
        decoration: InputDecoration(labelText: label, border: const OutlineInputBorder(), suffixIcon: const Icon(Icons.access_time)),
      ),
    );
  }
}
