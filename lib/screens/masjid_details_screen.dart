import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
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
                    Icon(Icons.directions, size: 18, color: AppColors.emerald),
                    SizedBox(width: 6),
                    Text(
                      'Get Directions',
                      style: TextStyle(color: AppColors.emerald, fontWeight: FontWeight.w600, decoration: TextDecoration.underline),
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
            // AZAN AND JAMAT, matching everywhere else.
            //
            // This screen showed azan only. Someone browsing nearby masjids is
            // choosing between them — and the jamat time is usually the deciding
            // factor, since that is the one they have to be there for.
            if (masjid.prayerTimes.hasAnyJamat)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  children: [
                    const Spacer(flex: 4),
                    Expanded(
                      flex: 3,
                      child: Text('AZAN',
                          textAlign: TextAlign.center,
                          style: AppText.eyebrow.copyWith(
                              fontSize: 9, color: AppColors.textFaint)),
                    ),
                    Expanded(
                      flex: 3,
                      child: Text('JAMAT',
                          textAlign: TextAlign.center,
                          style: AppText.eyebrow.copyWith(
                              fontSize: 9, color: AppColors.champagneGold)),
                    ),
                  ],
                ),
              ),
            _row('Fajr', masjid.prayerTimes.fajr, masjid.prayerTimes.fajrJamat),
            _row('Dhuhr', masjid.prayerTimes.dhuhr, masjid.prayerTimes.dhuhrJamat),
            _row('Asr', masjid.prayerTimes.asr, masjid.prayerTimes.asrJamat),
            _row('Maghrib', masjid.prayerTimes.maghrib, masjid.prayerTimes.maghribJamat),
            _row('Isha', masjid.prayerTimes.isha, masjid.prayerTimes.ishaJamat),
            _row('Juma', masjid.prayerTimes.juma, masjid.prayerTimes.jumaJamat),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.emerald),
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

  Widget _row(String label, String azan, String jamat) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Row(
          children: [
            Expanded(flex: 4, child: Text(label)),
            Expanded(
              flex: 3,
              child: Text(azan,
                  textAlign: TextAlign.center,
                  // Deep emerald, same weight as jamat below - see the note
                  // on home_screen.dart's list rows for why weight no longer
                  // carries the distinction between the two columns.
                  style: const TextStyle(
                      fontWeight: FontWeight.w600, color: AppColors.emerald)),
            ),
            if (jamat.trim().isNotEmpty || true)
              Expanded(
                flex: 3,
                child: Text(
                  jamat.trim().isEmpty ? '\u2014' : jamat,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: jamat.trim().isEmpty
                        ? AppColors.textFaint
                        : AppColors.champagneGold,
                  ),
                ),
              ),
          ],
        ),
      );
}
