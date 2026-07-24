import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/masjid.dart';

class MasjidDetailsScreen extends StatelessWidget {
  final Masjid masjid;
  const MasjidDetailsScreen({super.key, required this.masjid});

  Future<void> _openDirections(BuildContext context) async {
    if (masjid.latitude == 0.0 && masjid.longitude == 0.0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('This masjid has no location set yet.')),
      );
      return;
    }
    final url = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=${masjid.latitude},${masjid.longitude}',
    );
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open maps app.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(masjid.name),
        backgroundColor: const Color(0xFF14532D),
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.location_on, color: Colors.grey),
                const SizedBox(width: 8),
                Expanded(child: Text(masjid.address)),
              ],
            ),
            const SizedBox(height: 6),
            InkWell(
              onTap: () => _openDirections(context),
              child: const Padding(
                padding: EdgeInsets.only(left: 28),
                child: Row(
                  children: [
                    Icon(Icons.directions, size: 18, color: Color(0xFF14532D)),
                    SizedBox(width: 6),
                    Text(
                      'Get Directions',
                      style: TextStyle(color: Color(0xFF14532D), fontWeight: FontWeight.w600, decoration: TextDecoration.underline),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(
                  masjid.verificationStatus == 'Verified' ? Icons.verified : Icons.hourglass_top,
                  color: masjid.verificationStatus == 'Verified' ? Colors.green : Colors.orange,
                ),
                const SizedBox(width: 8),
                Text(masjid.verificationStatus),
              ],
            ),
            const SizedBox(height: 24),
            const Text('Prayer Times', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            _row('Fajr', masjid.prayerTimes.fajr),
            _row('Dhuhr', masjid.prayerTimes.dhuhr),
            _row('Asr', masjid.prayerTimes.asr),
            _row('Maghrib', masjid.prayerTimes.maghrib),
            _row('Isha', masjid.prayerTimes.isha),
            _row('Juma', masjid.prayerTimes.juma),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF14532D)),
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text(
                  'Follow This Masjid',
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _row(String label, String time) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [Text(label), Text(time, style: const TextStyle(fontWeight: FontWeight.w600))],
        ),
      );
}
