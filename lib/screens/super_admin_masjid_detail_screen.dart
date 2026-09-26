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
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(color: _statusColor.withOpacity(0.15), borderRadius: BorderRadius.circular(8)),
            child: Text(_currentStatus, style: TextStyle(color: _statusColor, fontWeight: FontWeight.bold)),
          ),
          // FLAGGED FOR EXTRA SCRUTINY: this registration only got past the
          // duplicate-registration-number block because the registrant
          // checked "the previous admin left" - worth actually confirming
          // before approving, not just rubber-stamping like an ordinary new
          // registration.
          if (m.previousAdminLeftClaim == true) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF3E0),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.shade200),
              ),
              child: const Row(
                children: [
                  Icon(Icons.warning_amber_rounded, color: Colors.orange),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'This registration number already had an active masjid. '
                      'The registrant claimed the previous admin left - worth '
                      'confirming before approving.',
                      style: TextStyle(fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 20),

          _sectionTitle('Masjid Details'),
          _row('Name', m.name),
          _row('Registration No.', m.registrationNo.isEmpty ? '—' : m.registrationNo),
          _row('City', m.city),
          _row('Address', m.address),
          _row('Coordinates', m.latitude == 0.0 && m.longitude == 0.0 ? 'Not captured' : '${m.latitude}, ${m.longitude}'),
          if (m.capacity != null) _row('Capacity', '${m.capacity}'),
          if (m.about != null && m.about!.trim().isNotEmpty) _row('About', m.about!),

          // PHOTOS - this was the actual gap. The registration form and
          // model both carried photoUrls already; this screen (the one a
          // platform admin actually reviews submissions on) never rendered
          // them at all, so an uploaded photo existed in the data with
          // nowhere for an admin to see it.
          if (m.photoUrls.isNotEmpty) ...[
            const SizedBox(height: 12),
            const Text('Photos', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            SizedBox(
              height: 110,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: m.photoUrls.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, index) => GestureDetector(
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => _AdminPhotoViewer(
                        photoUrls: m.photoUrls,
                        initialIndex: index,
                      ),
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      m.photoUrls[index],
                      width: 110,
                      height: 110,
                      fit: BoxFit.cover,
                      // A broken/expired URL should show as a broken tile,
                      // not silently vanish and leave the admin thinking
                      // no photo was ever uploaded at all.
                      errorBuilder: (context, error, stackTrace) => Container(
                        width: 110,
                        height: 110,
                        color: Colors.grey.shade300,
                        child: const Icon(Icons.broken_image_outlined, color: Colors.grey),
                      ),
                      loadingBuilder: (context, child, progress) {
                        if (progress == null) return child;
                        return Container(
                          width: 110,
                          height: 110,
                          color: Colors.grey.shade200,
                          child: const Center(
                            child: SizedBox(
                              width: 20, height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
          ],

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
                leading: const Icon(Icons.audiotrack, color: Color(0xFF1F5E4A)),
                title: Text(m.customAzanAudioName ?? 'Azan audio'),
                trailing: IconButton(
                  icon: Icon(_isPlaying ? Icons.stop_circle : Icons.play_circle, color: const Color(0xFF1F5E4A), size: 32),
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

/// Same full-screen swipeable viewer pattern as the public masjid details
/// screen - tap a thumbnail, get a proper look at it.
class _AdminPhotoViewer extends StatefulWidget {
  const _AdminPhotoViewer({required this.photoUrls, required this.initialIndex});

  final List<String> photoUrls;
  final int initialIndex;

  @override
  State<_AdminPhotoViewer> createState() => _AdminPhotoViewerState();
}

class _AdminPhotoViewerState extends State<_AdminPhotoViewer> {
  late final PageController _controller =
      PageController(initialPage: widget.initialIndex);
  late int _currentIndex = widget.initialIndex;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          '${_currentIndex + 1} / ${widget.photoUrls.length}',
          style: const TextStyle(color: Colors.white),
        ),
      ),
      body: PageView.builder(
        controller: _controller,
        itemCount: widget.photoUrls.length,
        onPageChanged: (index) => setState(() => _currentIndex = index),
        itemBuilder: (context, index) => InteractiveViewer(
          minScale: 1,
          maxScale: 4,
          child: Center(
            child: Image.network(widget.photoUrls[index], fit: BoxFit.contain),
          ),
        ),
      ),
    );
  }
}
