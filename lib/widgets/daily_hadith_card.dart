import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/daily_hadith.dart';
import '../data/daily_quran_ayah.dart';
import '../screens/surah_detail_screen.dart';
import '../services/quran_repository.dart';
import '../services/app_strings.dart';
import '../services/hadith_link.dart';
import '../theme/app_theme.dart';

/// One daily reminder: Quran and Hadith alternate on local calendar days.
///
/// ONCE. Not once per launch — someone who checks prayer times four times a day
/// would see it four times and start dismissing it without reading, which is
/// the failure mode for anything that appears uninvited.
class DailyHadithCard {
  DailyHadithCard._();

  static const _key = 'daily_reminder_quran_hadith_v1_shown';

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
    final dayIndex = DateTime.utc(now.year, now.month, now.day)
        .difference(DateTime.utc(2020, 1, 1)).inDays;
    final contentIndex = dayIndex ~/ 2;
    // Independent counters: neither collection skips every other entry.
    final _DailyReminder h = dayIndex.isEven
        ? _DailyReminder.quran(DailyQuranAyah.all[
            contentIndex % DailyQuranAyah.all.length])
        : _DailyReminder.hadith(DailyHadith.all[
            contentIndex % DailyHadith.all.length]);
    if (!context.mounted) return;

    // THE DIALOG RETURNS A REQUEST; THIS CALLER ACTS ON IT.
    //
    // "Read in full" used to pop the dialog and then call HadithLink.open with
    // the DIALOG'S context — which no longer existed by then. HadithLink shows
    // a blocking spinner on that context, so the spinner went up on a dead
    // route and never came down: your endless loading.
    //
    // Now the dialog pops with the reference it wants opened, and the screen
    // that opened the dialog — whose context is alive — does the navigating.
    final _Script? wanted = await showDialog<_Script>(
      context: context,
      // Dismissible by tapping outside as well as by the X. Something that
      // appears on its own should be easy to get rid of.
      barrierDismissible: true,
      builder: (ctx) => _DailyHadithDialog(hadith: h),
    );

    if (wanted != null && context.mounted) {
      if (!h.isQuran) {
        await HadithLink.open(context, h.hadith!.ref);
      } else {
        try {
          final language = wanted == _Script.english
              ? QuranLanguage.english : QuranLanguage.urdu;
          final surahs = await QuranRepository.loadSurahs(language);
          final surah = surahs.firstWhere((s) => s.number == h.ayah!.surah);
          if (!context.mounted) return;
          await Navigator.of(context).push(MaterialPageRoute<void>(
            builder: (_) => SurahDetailScreen(
              surah: surah, initialVerse: h.ayah!.ayah),
          ));
        } catch (_) {
          if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Could not open this Quran verse. Please try again.')));
        }
      }
    }
  }
}

class _DailyHadithDialog extends StatefulWidget {
  const _DailyHadithDialog({required this.hadith});

  final _DailyReminder hadith;

  @override
  State<_DailyHadithDialog> createState() => _DailyHadithDialogState();
}

enum _Script { urdu, roman, english }

class _DailyHadithDialogState extends State<_DailyHadithDialog> {
  late _Script _script;

  @override
  void initState() {
    super.initState();
    // ROMAN BY DEFAULT.
    //
    // It used to open on Urdu or English depending on the app language, which
    // meant an Urdu reader who is more comfortable with Latin script had to
    // switch every single day.
    //
    // Roman is the one script almost everyone here can read: Urdu speakers
    // because it is their language spelled out, and English readers because
    // they recognise the letters. The other two are one tap away.
    _script = widget.hadith.textHi.trim().isNotEmpty
        ? _Script.roman
        : (S.isUrdu ? _Script.urdu : _Script.english);
  }

  @override
  Widget build(BuildContext context) {
    final _DailyReminder hadith = widget.hadith;
    final bool urdu = _script == _Script.urdu;
    final String body = switch (_script) {
      _Script.urdu => hadith.textUr,
      _Script.roman => hadith.textHi,
      _Script.english => hadith.previewEnglish,
    };
    final String theme = S.isUrdu ? hadith.themeUr : hadith.theme;

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 26),
      child: SingleChildScrollView(
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
              color: AppColors.ivory.withOpacity(0.96),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.gold.withOpacity(0.7)),
              boxShadow: const <BoxShadow>[
                BoxShadow(
                    color: Color(0x33000000),
                    blurRadius: 26,
                    offset: Offset(0, 10)),
              ],
            ),
            padding: const EdgeInsets.fromLTRB(20, 12, 12, 18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        hadith.isQuran
                            ? (urdu ? 'آج کی قرآنی آیت' : 'Quran ayat of the day')
                            : (urdu ? 'آج کی حدیث' : 'Hadith of the day'),
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
                  padding: const EdgeInsets.only(right: 8, bottom: 4),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(theme,
                          style: AppText.rowTitle.copyWith(
                              fontSize: 15, color: AppColors.emerald)),
                      const SizedBox(height: 12),

                      // ARABIC FIRST, then the translation beneath it.
                      //
                      // Every other screen in this app leads with the Arabic.
                      // A daily card that showed only an English sentence was
                      // the odd one out, and looked like a fortune cookie
                      // rather than a hadith.
                      Directionality(
                        textDirection: TextDirection.rtl,
                        child: Text(
                          hadith.previewArabic,
                          textAlign: TextAlign.right,
                          style: (hadith.isQuran ? AppText.quranAyah : AppText.arabicVerse).copyWith(
                              fontSize: 20, height: 1.95, color: AppColors.text),
                        ),
                      ),
                      const SizedBox(height: 12),
                      // A short gold rule between the two, rather than a full
                      // divider: it separates them without cutting the card in
                      // half.
                      Container(width: 38, height: 1, color: AppColors.gold),
                      const SizedBox(height: 12),

                      Directionality(
                        textDirection:
                            urdu ? TextDirection.rtl : TextDirection.ltr,
                        child: Text(
                          body,
                          textAlign: urdu ? TextAlign.right : TextAlign.left,
                          style: urdu
                              ? AppText.urduText
                                  .copyWith(color: AppColors.textMid)
                              : AppText.translation
                                  .copyWith(color: AppColors.textMid),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        hadith.isQuran
                            ? (_script == _Script.roman
                                ? 'Roman Urdu meaning · Complete Quran verse'
                                : (urdu ? 'مکمل آیت · سورت میں سیاق پڑھیں' : 'Complete verse · Open Surah for context'))
                            : (_script == _Script.roman
                                ? 'Roman Urdu meaning · Read in full for context'
                                : (urdu ? 'مختصر اقتباس — مکمل سیاق کے لیے پوری حدیث پڑھیں' : 'Short hadith · Read in full for context')),
                        style: AppText.caption.copyWith(color: AppColors.textMuted)),
                      const SizedBox(height: 12),
                      // Urdu / Roman / English.
                      //
                      // Roman Urdu is there because a great many readers speak
                      // Urdu but read Latin script more easily than Nastaliq.
                      // The selected short text has a simple Roman Urdu meaning.
                      // Original source text stays available in the full reader.
                      Row(
                        children: <Widget>[
                          for (final (_Script sc, String label) in <(_Script, String)>[
                            (_Script.urdu, 'اردو'),
                            if (hadith.textHi.trim().isNotEmpty)
                              (_Script.roman, 'Roman'),
                            (_Script.english, 'English'),
                          ])
                            Padding(
                              padding: const EdgeInsets.only(right: 6),
                              child: GestureDetector(
                                onTap: () => setState(() => _script = sc),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: _script == sc
                                        ? AppColors.emerald
                                        : Colors.transparent,
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                        color: _script == sc
                                            ? AppColors.emerald
                                            : AppColors.goldRule),
                                  ),
                                  child: Text(
                                    label,
                                    style: AppText.caption.copyWith(
                                      fontSize: 11.5,
                                      color: _script == sc
                                          ? Colors.white
                                          : AppColors.textMuted,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: <Widget>[
                          Expanded(
                            child: Text(hadith.referenceLabel,
                                style: AppText.caption
                                    .copyWith(color: AppColors.textMuted)),
                          ),
                          TextButton(
                            // Returns the reference rather than navigating
                            // from inside a route that is about to close.
                            onPressed: () =>
                                Navigator.of(context).pop(_script),
                            style: TextButton.styleFrom(
                              foregroundColor: AppColors.emerald,
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 8),
                              minimumSize: Size.zero,
                              tapTargetSize:
                                  MaterialTapTargetSize.shrinkWrap,
                            ),
                            child: Text(hadith.isQuran
                                ? (urdu ? 'سورت کھولیں' : 'Open Surah')
                                : (urdu ? 'مکمل پڑھیں' : 'Read in full'),
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
      ),
    );
  }
}

/// Typed wrapper keeps Quran citations out of the Hadith reference model.
class _DailyReminder {
  const _DailyReminder.hadith(DailyHadith entry) : hadith = entry, ayah = null;
  const _DailyReminder.quran(DailyQuranAyah entry) : ayah = entry, hadith = null;
  final DailyHadith? hadith;
  final DailyQuranAyah? ayah;
  bool get isQuran => ayah != null;
  String get textUr => ayah?.urdu ?? hadith!.textUr;
  String get textHi => ayah?.roman ?? hadith!.textHi;
  String get previewEnglish => ayah?.english ?? hadith!.previewEnglish;
  String get previewArabic => ayah?.arabic ?? hadith!.previewArabic;
  String get theme => isQuran ? 'A moment with the Quran' : hadith!.theme;
  String get themeUr => isQuran ? 'قرآن سے ایک یاد دہانی' : hadith!.themeUr;
  String get referenceLabel => isQuran
      ? 'Quran · ${S.isUrdu ? ayah!.surahNameUr : ayah!.surahName} ${ayah!.surah}:${ayah!.ayah}'
      : hadith!.ref.label;
}
