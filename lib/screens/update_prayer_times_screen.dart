import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:audioplayers/audioplayers.dart';
import '../models/masjid.dart';

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
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  bool get _isVerified => widget.masjid.verificationStatus == 'Verified';

  void _saveTimes() {
    final t = widget.masjid.prayerTimes;
    t.fajr = _fajr.text;
    t.dhuhr = _dhuhr.text;
    t.asr = _asr.text;
    t.maghrib = _maghrib.text;
    t.isha = _isha.text;
    t.juma = _juma.text;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Prayer times updated.')),
    );
  }

  Future<void> _pickAzanAudio() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.audio,
    );
    if (result != null && result.files.isNotEmpty) {
      setState(() {
        widget.masjid.customAzanAudioName = result.files.first.name;
        widget.masjid.customAzanAudioPath = result.files.first.path;
      });
      // Phase 3 note: this file lives only on the admin's own phone right
      // now. To actually reach the phones of everyone following this
      // masjid, it needs to be uploaded to cloud storage (e.g. Firebase
      // Storage) and referenced by a URL in Firestore — that's Phase 2 work.
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Audio selected. Note: this stays on this device until '
            'cloud storage is connected (Phase 2).',
          ),
        ),
      );
    }
  }

  Future<void> _togglePlayback() async {
    final path = widget.masjid.customAzanAudioPath;
    if (path == null) return;
    if (_isPlaying) {
      await _player.stop();
      setState(() => _isPlaying = false);
    } else {
      await _player.play(DeviceFileSource(path));
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
                        'This masjid is still Pending Verification. '
                        'Changes are saved for testing but will not go '
                        'live to followers until verified.',
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
              onPressed: _saveTimes,
              child: const Text('Save Prayer Times', style: TextStyle(color: Colors.white)),
            ),
          ),
          const Divider(height: 40),
          const Text('Custom Azan Audio', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          const Text(
            'Upload your own Azan recording to play for followers instead of the default sound.',
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 12),
          if (widget.masjid.customAzanAudioName != null)
            Card(
              child: ListTile(
                leading: const Icon(Icons.audiotrack, color: Color(0xFF14532D)),
                title: Text(widget.masjid.customAzanAudioName!),
                trailing: IconButton(
                  icon: Icon(_isPlaying ? Icons.stop_circle : Icons.play_circle, color: const Color(0xFF14532D), size: 32),
                  onPressed: _togglePlayback,
                ),
              ),
            ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            icon: const Icon(Icons.mic),
            label: Text(widget.masjid.customAzanAudioName == null ? 'Upload Azan Recording' : 'Replace Recording'),
            onPressed: _pickAzanAudio,
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
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          suffixIcon: const Icon(Icons.access_time),
        ),
      ),
    );
  }
}
