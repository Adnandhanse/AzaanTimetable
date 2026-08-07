import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/daily_hadith.dart';
import '../services/app_strings.dart';
import '../services/hadith_link.dart';
import '../theme/app_theme.dart';
import '../widgets/ornaments.dart';

/// The hadith of the day, shown once per day on opening the app.
///
/// ONCE. Not once per launch — someone who checks prayer times four times a day
/// would see it four times and start dismissing it without reading, which is
/// the failure mode for anything that appears uninvited.
class DailyHadithCard {
  DailyHadithCard._();

  static const _key = 'daily_hadith_shown';

  /// Shows the card if it has not been shown today.
  ///
  /// The date is written BEFORE the dialog opens, so a crash or a fast dismissal
  /// cannot cause it to reappear on the next launch.
  static Future<void> maybeShow(BuildContext context) async {
    final now = DateTime.now();
    final today = '${now.year}-${now.month}-${now.day}';

    try {
      final prefs = await SharedPreferences.getInstance();
      if (prefs.getString(_key) == today) return;
      await prefs.setString(_key, today);
    } catch (_) {
      return;
    }

    if (!context.mounted) return;
    final h = DailyHadith.forDate(now);

    await showDialog<void>(
      context: context,
      // Dismissible by tapping outside as well as by the X. Something that
      // appears on its own should be easy to get rid of.
      barrierDismissible: true,
      builder: (ctx) => _DailyHadithDialog(hadith: h),
    );
  }
}

class _DailyHadithDialog extends StatelessWidget {
  const _DailyHadithDialog({required this.hadith});

  final DailyHadith hadith;

  @override
  Widget build(BuildContext context) {
    final bool urdu = S.isUrdu;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 22, vertical: 40),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.ivory,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: AppColors.gold, width: 1.4),
          boxShadow: const <BoxShadow>[
            BoxShadow(color: Color(0x40000000), blurRadius: 24, offset: Offset(0, 8)),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            // Header strip with the X. Red as asked, and deliberately the most
            // obvious control on the card — the first thing someone looks for
            // when something appears unbidden is the way out.
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 8, 0),
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: Text(
                      urdu ? 'آج کی حدیث' : 'Hadith of the day',
                      style: AppText.eyebrow
                          .copyWith(letterSpacing: 1.6, color: AppColors.gold),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 22),
                    color: const Color(0xFFB3261E),
                    tooltip: urdu ? 'بند کریں' : 'Close',
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  const Medallion(icon: Icons.auto_stories_outlined, size: 44),
                  const SizedBox(height: 14),
                  Text(
                    hadith.theme,
                    style: AppText.rowTitle
                        .copyWith(fontSize: 17, color: AppColors.emerald),
                  ),
                  const SizedBox(height: 12),
                  const DiamondRule(),
                  const SizedBox(height: 14),
                  Text(
                    hadith.text,
                    textAlign: TextAlign.center,
                    style: AppText.translation.copyWith(color: AppColors.text),
                  ),
                  const SizedBox(height: 14),
                  const DiamondRule(),
                  const SizedBox(height: 10),
                  Text(
                    hadith.ref.label,
                    style: AppText.caption.copyWith(color: AppColors.textMuted),
                  ),
                  const SizedBox(height: 16),
                  // Opens the real entry, with its chapter and gradings. The
                  // card is an invitation to read, not a replacement for it.
                  OutlinedButton.icon(
                    onPressed: () {
                      Navigator.of(context).pop();
                      HadithLink.open(context, hadith.ref);
                    },
                    icon: const Icon(Icons.open_in_new, size: 16),
                    label: Text(urdu ? 'مکمل پڑھیں' : 'Read in full'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.emerald,
                      side: const BorderSide(color: AppColors.gold),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 18, vertical: 10),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4)),
                      textStyle: AppText.body,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
