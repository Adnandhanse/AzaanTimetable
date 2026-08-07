import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../data/sajdah_verses.dart';
import '../models/quran.dart';
import '../data/juz_boundaries.dart';
import '../widgets/mushaf_view.dart';
import '../services/quran_local_data_service.dart';

class JuzDetailScreen extends StatefulWidget {
  final int juzNumber;
  final List<Surah> allSurahs;

  /// Where to resume: the surah and verse the reader saved inside this juz.
  final int? initialSurahNumber;
  final int? initialVerse;

  const JuzDetailScreen({
    super.key,
    required this.juzNumber,
    required this.allSurahs,
    this.initialSurahNumber,
    this.initialVerse,
  });

  @override
  State<JuzDetailScreen> createState() => _JuzDetailScreenState();
}

class _JuzDetailScreenState extends State<JuzDetailScreen> {
  /// true = Arabic only (the default), false = verse by verse with translation.
  /// Shares the stored preference with the surah screen, so the reader sets it
  /// once and both screens respect it.
  bool _mushafMode = true;

  /// (surahNumber, verseNumber) saved inside this juz, if any.
  (int, int)? _marked;

  @override
  void initState() {
    super.initState();
    if (widget.initialSurahNumber != null && widget.initialVerse != null) {
      _marked = (widget.initialSurahNumber!, widget.initialVerse!);
    }
    _loadReadingMode();
  }

  /// Saves surah AND verse, not just a verse number. A juz spans several
  /// surahs, so "verse 12" on its own points at nothing — that ambiguity is
  /// why the Save button was missing here before, and storing the surah
  /// alongside it is the whole fix.
  Future<void> _markAt(Surah surah, QuranVerse verse) async {
    final bool unmark =
        _marked != null && _marked!.$1 == surah.number && _marked!.$2 == verse.number;
    setState(() => _marked = unmark ? null : (surah.number, verse.number));

    if (unmark) {
      await QuranLocalDataService.clearLastRead();
    } else {
      await QuranLocalDataService.saveLastRead(
        surahNumber: surah.number,
        surahName: surah.transliteration,
        verseNumber: verse.number,
        juzNumber: widget.juzNumber,
      );
    }
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(unmark
            ? 'Reading position cleared'
            : 'Saved \u2014 Juz ${widget.juzNumber}, ${surah.transliteration} ${verse.number}'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _loadReadingMode() async {
    final bool arabicOnly = await QuranLocalDataService.getArabicOnly();
    if (!mounted) return;
    setState(() => _mushafMode = arabicOnly);
  }

  Future<void> _setReadingMode(bool arabicOnly) async {
    setState(() => _mushafMode = arabicOnly);
    await QuranLocalDataService.setArabicOnly(arabicOnly);
  }

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
              onPressed: () => _setReadingMode(!_mushafMode),
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
              // A juz spans surahs, so each item carries its own surah and the
              // index is the only unambiguous handle — same reason the bookmark
              // works on indices.
              sajdahIndices: <int>{
                for (int i = 0; i < items.length; i++)
                  if (SajdahVerses.isSajdah(items[i].$1.number, items[i].$2.number))
                    i,
              },
              markedIndex: _marked == null
                  ? null
                  : items.indexWhere((e) =>
                      e.$1.number == _marked!.$1 && e.$2.number == _marked!.$2),
              initialVerseIndex: (widget.initialSurahNumber == null ||
                      widget.initialVerse == null)
                  ? null
                  : items.indexWhere((e) =>
                      e.$1.number == widget.initialSurahNumber &&
                      e.$2.number == widget.initialVerse),
              onMarkIndex: (int index) =>
                  _markAt(items[index].$1, items[index].$2),
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
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    '${surah.number}:${verse.number}',
                                    style: AppText.caption.copyWith(
                                      color: AppColors.emerald,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                InkWell(
                                  onTap: () => _markAt(surah, verse),
                                  child: Padding(
                                    padding: const EdgeInsets.all(4),
                                    child: Icon(
                                      (_marked != null &&
                                              _marked!.$1 == surah.number &&
                                              _marked!.$2 == verse.number)
                                          ? Icons.bookmark
                                          : Icons.bookmark_border,
                                      size: 18,
                                      color: (_marked != null &&
                                              _marked!.$1 == surah.number &&
                                              _marked!.$2 == verse.number)
                                          ? AppColors.emerald
                                          : AppColors.chevron,
                                    ),
                                  ),
                                ),
                              ],
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
