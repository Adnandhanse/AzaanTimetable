import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/quran.dart';
import '../data/juz_boundaries.dart';
import '../widgets/mushaf_view.dart';

class JuzDetailScreen extends StatefulWidget {
  final int juzNumber;
  final List<Surah> allSurahs;

  const JuzDetailScreen({
    super.key,
    required this.juzNumber,
    required this.allSurahs,
  });

  @override
  State<JuzDetailScreen> createState() => _JuzDetailScreenState();
}

class _JuzDetailScreenState extends State<JuzDetailScreen> {
  /// false = verse by verse with translation, true = Arabic-only continuous.
  /// Same control as the surah screen — the two reading modes should be
  /// available wherever Qur'an is read, not just in one place.
  bool _mushafMode = false;

  /// The (surah, verse) pairs falling inside this juz.
  List<(Surah, QuranVerse)> _items() {
    final int startIndex =
        juzBoundaries.indexWhere((j) => j.$1 == widget.juzNumber);
    final (_, startSurah, startVerse) = juzBoundaries[startIndex];
    final bool hasNext = startIndex + 1 < juzBoundaries.length;
    final (int, int)? end = hasNext
        ? (juzBoundaries[startIndex + 1].$2, juzBoundaries[startIndex + 1].$3)
        : null;

    final items = <(Surah, QuranVerse)>[];
    for (final surah in widget.allSurahs) {
      if (surah.number < startSurah) continue;
      if (end != null && surah.number > end.$1) break;
      for (final verse in surah.verses) {
        if (surah.number == startSurah && verse.number < startVerse) continue;
        if (end != null && surah.number == end.$1 && verse.number >= end.$2) {
          break;
        }
        if (end != null && surah.number > end.$1) break;
        items.add((surah, verse));
      }
    }
    return items;
  }

  @override
  Widget build(BuildContext context) {
    final items = _items();

    return Scaffold(
      appBar: AppBar(
        title: Text('Juz ${widget.juzNumber}'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: TextButton.icon(
              onPressed: () => setState(() => _mushafMode = !_mushafMode),
              icon: Icon(
                _mushafMode ? Icons.list_alt_outlined : Icons.menu_book_outlined,
                size: 18,
                color: AppColors.emerald,
              ),
              label: Text(
                _mushafMode ? 'Translation' : 'Arabic only',
                style: AppText.caption.copyWith(color: AppColors.emerald),
              ),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
          ),
        ],
      ),
      body: _mushafMode
          ? MushafView(
              verses: items.map((e) => e.$2).toList(),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: items.length,
              itemBuilder: (context, index) {
                final (surah, verse) = items[index];
                final isNewSurah =
                    index == 0 || items[index - 1].$1.number != surah.number;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (isNewSurah)
                      Padding(
                        padding: const EdgeInsets.only(top: 12, bottom: 8),
                        child: Row(
                          children: [
                            Text(
                              surah.transliteration,
                              style: AppText.rowTitle.copyWith(
                                  fontSize: 17, color: AppColors.emerald),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              surah.arabicName,
                              style: AppText.arabic.copyWith(
                                  fontSize: 16,
                                  height: 1.3,
                                  color: AppColors.gold),
                            ),
                          ],
                        ),
                      ),
                    Card(
                      margin: const EdgeInsets.only(bottom: 10),
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${surah.number}:${verse.number}',
                              style: AppText.caption.copyWith(
                                color: AppColors.emerald,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              verse.arabicText,
                              textAlign: TextAlign.right,
                              textDirection: TextDirection.rtl,
                              style: AppText.arabicVerse
                                  .copyWith(color: AppColors.text),
                            ),
                            const SizedBox(height: 8),
                            Container(height: 1, color: AppColors.goldRuleFaint),
                            const SizedBox(height: 8),
                            Text(
                              verse.translation,
                              style: AppText.translation
                                  .copyWith(color: AppColors.text),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
    );
  }
}
