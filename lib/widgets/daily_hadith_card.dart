import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/daily_hadith.dart';
import '../services/app_strings.dart';
import '../services/hadith_link.dart';
import '../theme/app_theme.dart';

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
    // Both languages come from the app's own data. An Urdu reader gets Urdu.
    final String body = urdu ? hadith.textUr : hadith.text;
    final String theme = urdu ? hadith.themeUr : hadith.theme;

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 26),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          // TRANSLUCENT, and small.
          //
          // The first version was a tall opaque card that covered the home
          // screen — it read as an interruption. At 92% opacity the app stays
          // visible behind it, so it reads as something laid on top of the app
          // rather than something replacing it.
          //
          // Held to the saying itself, two or three lines, with the chain of
          // narrators removed. Nobody reads a paragraph on a card that appeared
          // uninvited.
          Container(
            decoration: BoxDecoration(
              color: AppColors.ivory.withOpacity(0.92),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.gold.withOpacity(0.7)),
              boxShadow: const <BoxShadow>[
                BoxShadow(
                    color: Color(0x33000000),
                    blurRadius: 26,
                    offset: Offset(0, 10)),
              ],
            ),
            padding: const EdgeInsets.fromLTRB(18, 12, 10, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        urdu ? 'آج کی حدیث' : 'Hadith of the day',
                        style: AppText.eyebrow.copyWith(
                            letterSpacing: 1.5, color: AppColors.gold),
                      ),
                    ),
                    // The red X, and the largest tap target on the card. The
                    // first thing anyone looks for when something appears
                    // unbidden is the way out of it.
                    IconButton(
                      icon: const Icon(Icons.close, size: 21),
                      color: const Color(0xFFB3261E),
                      visualDensity: VisualDensity.compact,
                      tooltip: urdu ? 'بند کریں' : 'Close',
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(theme,
                          style: AppText.rowTitle.copyWith(
                              fontSize: 15, color: AppColors.emerald)),
                      const SizedBox(height: 8),
                      Directionality(
                        textDirection:
                            urdu ? TextDirection.rtl : TextDirection.ltr,
                        child: Text(
                          body,
                          textAlign: urdu ? TextAlign.right : TextAlign.left,
                          style: urdu
                              ? AppText.translation.copyWith(
                                  fontSize: 16, height: 1.9,
                                  color: AppColors.text)
                              : AppText.translation
                                  .copyWith(color: AppColors.text),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: <Widget>[
                          Expanded(
                            child: Text(hadith.ref.label,
                                style: AppText.caption
                                    .copyWith(color: AppColors.textMuted)),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.of(context).pop();
                              HadithLink.open(context, hadith.ref);
                            },
                            style: TextButton.styleFrom(
                              foregroundColor: AppColors.emerald,
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 8),
                              minimumSize: Size.zero,
                              tapTargetSize:
                                  MaterialTapTargetSize.shrinkWrap,
                            ),
                            child: Text(urdu ? 'مکمل پڑھیں' : 'Read in full',
                                style: AppText.caption
                                    .copyWith(color: AppColors.emerald)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
