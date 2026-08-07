import 'package:flutter/material.dart';

import '../models/masjid.dart';
import '../services/app_strings.dart';
import '../theme/app_theme.dart';

/// The full schedule for a masjid: azan times and, where the masjid publishes
/// them, jamat times beside them.
///
/// This screen was showing azan only. Someone opening "View full prayer
/// schedule" from the home screen — where both columns are visible — found
/// half the information missing, which makes the fuller view look like the
/// lesser one.
class PrayerTimesScreen extends StatelessWidget {
  final Masjid masjid;
  const PrayerTimesScreen({super.key, required this.masjid});

  @override
  Widget build(BuildContext context) {
    final t = masjid.prayerTimes;
    final bool showJamat = t.hasAnyJamat;

    final rows = <(String, String, String, IconData)>[
      (S.fajr, t.fajr, t.fajrJamat, Icons.wb_twilight),
      (S.dhuhr, t.dhuhr, t.dhuhrJamat, Icons.wb_sunny),
      (S.asr, t.asr, t.asrJamat, Icons.wb_sunny_outlined),
      (S.maghrib, t.maghrib, t.maghribJamat, Icons.nightlight_round),
      (S.isha, t.isha, t.ishaJamat, Icons.dark_mode),
      (S.juma, t.juma, t.jumaJamat, Icons.groups),
    ];

    return Scaffold(
      appBar: AppBar(title: Text(masjid.name)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
        children: [
          if (showJamat)
            Padding(
              padding: const EdgeInsets.only(left: 34, bottom: 8),
              child: Row(
                children: [
                  const Spacer(flex: 4),
                  Expanded(
                    flex: 3,
                    child: Text(S.azanLabel.toUpperCase(),
                        textAlign: TextAlign.right,
                        style: AppText.eyebrow.copyWith(
                            fontSize: 9,
                            letterSpacing: 1,
                            color: AppColors.textFaint)),
                  ),
                  Expanded(
                    flex: 3,
                    child: Text(S.jamatLabel.toUpperCase(),
                        textAlign: TextAlign.right,
                        style: AppText.eyebrow.copyWith(
                            fontSize: 9,
                            letterSpacing: 1,
                            color: AppColors.gold)),
                  ),
                ],
              ),
            ),
          for (int i = 0; i < rows.length; i++)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 13),
              decoration: BoxDecoration(
                border: i == 0
                    ? null
                    : const Border(
                        top: BorderSide(color: AppColors.goldRuleFaint)),
              ),
              // Same flex proportions as the home screen list, so the two read
              // as the same table rather than two different ones.
              child: Row(
                children: [
                  Icon(rows[i].$4, size: 18, color: AppColors.gold),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 4,
                    child: Text(
                      rows[i].$1,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppText.rowTitle
                          .copyWith(fontSize: 15, color: AppColors.text),
                    ),
                  ),
                  if (!showJamat)
                    Expanded(
                      flex: 6,
                      child: Text(rows[i].$2,
                          textAlign: TextAlign.right,
                          style: AppText.listTime.copyWith(
                              fontSize: 17, color: AppColors.text)),
                    )
                  else ...[
                    Expanded(
                      flex: 3,
                      child: Text(rows[i].$2,
                          textAlign: TextAlign.right,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppText.listTime.copyWith(
                              fontSize: 15, color: AppColors.textMuted)),
                    ),
                    Expanded(
                      flex: 3,
                      child: Text(
                        rows[i].$3.trim().isEmpty ? '\u2014' : rows[i].$3,
                        textAlign: TextAlign.right,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppText.listTime.copyWith(
                          fontSize: 17,
                          color: rows[i].$3.trim().isEmpty
                              ? AppColors.textFaint
                              : AppColors.text,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          const SizedBox(height: 22),
          Text(
            // Says which time the alarm uses. With two columns on screen that
            // is a real question, and guessing wrong means missing a prayer.
            showJamat
                ? (S.isUrdu
                    ? 'الارم اذان کے وقت پر بجتا ہے، جماعت کے وقت پر نہیں۔'
                    : 'The alarm sounds at the azan time, not the jamat time.')
                : (S.isUrdu
                    ? 'ہر نماز کے وقت اذان کا الارم خود بخود بجے گا۔'
                    : 'You will receive an azan alarm automatically at each prayer time.'),
            style: AppText.caption.copyWith(color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }
}
