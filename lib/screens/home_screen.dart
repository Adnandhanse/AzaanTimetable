import 'package:flutter/material.dart';
import '../models/masjid.dart';
import '../services/masjid_repository.dart';
import '../services/user_repository.dart';
import '../services/notification_service.dart';
import 'masjid_search_screen.dart';
import 'prayer_times_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String? _selectedMasjidId;
  bool _loading = true;
  String? _lastScheduledSignature;

  @override
  void initState() {
    super.initState();
    _loadSelectedMasjid();
  }

  Future<void> _loadSelectedMasjid() async {
    final id = await UserRepository.getSelectedMasjidId();
    if (!mounted) return;
    setState(() {
      _selectedMasjidId = id;
      _loading = false;
    });
  }

  void _maybeScheduleNotifications(Masjid masjid) {
    final t = masjid.prayerTimes;
    final signature = '${masjid.id}|${t.fajr}|${t.dhuhr}|${t.asr}|${t.maghrib}|${t.isha}|${t.juma}';
    if (signature == _lastScheduledSignature) return;
    _lastScheduledSignature = signature;
    NotificationService.scheduleForMasjid(masjid);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Masjid Namaz Alarm'),
        backgroundColor: const Color(0xFF14532D),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const SettingsScreen()),
            ),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _selectedMasjidId == null
              ? _buildNoMasjidSelected()
              : StreamBuilder<Masjid?>(
                  stream: MasjidRepository.streamById(_selectedMasjidId!),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final masjid = snapshot.data;
                    if (masjid == null) return _buildNoMasjidSelected();
                    _maybeScheduleNotifications(masjid);
                    return _buildSelectedMasjidView(masjid);
                  },
                ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFF14532D),
        icon: const Icon(Icons.search, color: Colors.white),
        label: const Text('Change Masjid', style: TextStyle(color: Colors.white)),
        onPressed: () async {
          final result = await Navigator.of(context).push<Masjid>(
            MaterialPageRoute(builder: (_) => const MasjidSearchScreen()),
          );
          if (result != null) {
            await UserRepository.setSelectedMasjid(result.id);
            setState(() => _selectedMasjidId = result.id);
          }
        },
      ),
    );
  }

  Widget _buildNoMasjidSelected() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(24.0),
        child: Text(
          'No masjid selected yet.\nTap "Change Masjid" below to follow one.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
      ),
    );
  }

  Widget _buildSelectedMasjidView(Masjid masjid) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            color: const Color(0xFFF0FDF4),
            child: ListTile(
              leading: const Icon(Icons.mosque, color: Color(0xFF14532D), size: 36),
              title: Text(masjid.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              subtitle: Text('${masjid.address}\n${masjid.city}'),
              isThreeLine: true,
              trailing: masjid.verificationStatus == 'Verified'
                  ? const Icon(Icons.verified, color: Colors.green)
                  : const Icon(Icons.hourglass_top, color: Colors.orange),
            ),
          ),
          const SizedBox(height: 16),
          const Text("Today's Prayer Times", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                children: [
                  _prayerRow('Fajr', masjid.prayerTimes.fajr),
                  _prayerRow('Dhuhr', masjid.prayerTimes.dhuhr),
                  _prayerRow('Asr', masjid.prayerTimes.asr),
                  _prayerRow('Maghrib', masjid.prayerTimes.maghrib),
                  _prayerRow('Isha', masjid.prayerTimes.isha),
                  _prayerRow('Juma', masjid.prayerTimes.juma),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            icon: const Icon(Icons.calendar_month),
            label: const Text('View Full Prayer Schedule'),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => PrayerTimesScreen(masjid: masjid)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _prayerRow(String name, String time) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(name, style: const TextStyle(fontSize: 16)),
          Text(time, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
