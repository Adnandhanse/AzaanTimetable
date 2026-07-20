import 'package:flutter/material.dart';
import '../models/masjid.dart';

class PrayerTimesScreen extends StatelessWidget {
  final Masjid masjid;
  const PrayerTimesScreen({super.key, required this.masjid});

  @override
  Widget build(BuildContext context) {
    final times = masjid.prayerTimes;
    return Scaffold(
      appBar: AppBar(
        title: Text('${masjid.name} - Prayer Times'),
        backgroundColor: const Color(0xFF14532D),
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _tile('Fajr', times.fajr, Icons.wb_twilight),
          _tile('Dhuhr', times.dhuhr, Icons.wb_sunny),
          _tile('Asr', times.asr, Icons.wb_sunny_outlined),
          _tile('Maghrib', times.maghrib, Icons.nightlight_round),
          _tile('Isha', times.isha, Icons.dark_mode),
          _tile('Juma (Friday)', times.juma, Icons.groups),
          const SizedBox(height: 16),
          const Card(
            child: Padding(
              padding: EdgeInsets.all(12.0),
              child: Text(
                'You will receive an Azan alarm notification automatically '
                'when each prayer time arrives at this masjid.',
                style: TextStyle(color: Colors.grey),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _tile(String name, String time, IconData icon) {
    return Card(
      child: ListTile(
        leading: Icon(icon, color: const Color(0xFF14532D)),
        title: Text(name, style: const TextStyle(fontWeight: FontWeight.w600)),
        trailing: Text(time, style: const TextStyle(fontSize: 16)),
      ),
    );
  }
}
