import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/hadith.dart';
import '../services/hadith_repository.dart';
import '../services/hadith_section_titles.dart';
import '../widgets/ornaments.dart';
import 'hadith_list_screen.dart';
import 'hadith_single_screen.dart';
import 'hadith_search_screen.dart';

/// The hadith numbers a chapter covers, and how many it holds.
class _ChapterRange {
  const _ChapterRange({
    required this.first,
    required this.last,
    required this.count,
  });

  final int first;
  final int last;
  final int count;

  bool contains(int n) => n >= first && n <= last;

  /// "222-385" or just "222" for a single-hadith chapter.
  String get label => first == last ? '$first' : '$first\u2013$last';
}

class HadithChaptersScreen extends StatefulWidget {
  final HadithBook book;
  final HadithLanguage language;

  const HadithChaptersScreen({
    super.key,
    required this.book,
    required this.language,
  });

  @override
  State<HadithChaptersScreen> createState() => _HadithChaptersScreenState();
}

class _HadithChaptersScreenState extends State<HadithChaptersScreen> {
  HadithCollection? _collection;
  String? _error;
  String _query = '';

  /// Chapter number -> range. Computed once when the book loads. Doing this
  /// per-row inside the ListView would rescan every hadith in the book on
  /// every frame of every scroll.
  final Map<int, _ChapterRange> _ranges = <int, _ChapterRange>{};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      await HadithSectionTitles.load();
      final collection =
          await HadithRepository.loadCollection(widget.book, widget.language);
      if (!mounted) return;

      _ranges.clear();
      for (final HadithChapter c in collection.chapters) {
        final List<HadithItem> items = collection.hadithsInChapter(c.number);
        if (items.isEmpty) continue;
        int lo = items.first.hadithNumber;
        int hi = items.first.hadithNumber;
        for (final HadithItem h in items) {
          if (h.hadithNumber < lo) lo = h.hadithNumber;
          if (h.hadithNumber > hi) hi = h.hadithNumber;
        }
        _ranges[c.number] =
            _ChapterRange(first: lo, last: hi, count: items.length);
      }

      setState(() => _collection = collection);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    }
  }

  String get _langCode =>
      widget.language == HadithLanguage.english ? 'eng' : 'urd';

  @override
  Widget build(BuildContext context) {
    // Titles resolve through the Urdu override before filtering, so the filter
    // matches what the reader can actually see.
    String displayTitle(HadithChapter c) => HadithSectionTitles.resolve(
          book: widget.book,
          sectionNumber: c.number,
          language: widget.language,
          englishTitle: c.title,
        );

    final String q = _query.trim();
    final int? asNumber = int.tryParse(q);

    final List<HadithChapter> chapters = _collection == null
        ? <HadithChapter>[]
        : _collection!.chapters.where((HadithChapter c) {
            if (q.isEmpty) return true;
            // A number matches the chapter that CONTAINS that hadith, or the
            // chapter with that number. Typing 300 should take you to the
            // chapter holding hadith 300, which is the useful behaviour.
            if (asNumber != null) {
              final _ChapterRange? r = _ranges[c.number];
              return (r != null && r.contains(asNumber)) ||
                  c.number == asNumber;
            }
            return displayTitle(c).toLowerCase().contains(q.toLowerCase());
          }).toList();

    final bool urduTitlesMissing = widget.language == HadithLanguage.urdu &&
        HadithSectionTitles.overrideCount(widget.book) == 0;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.book.displayName),
        actions: [
          if (_collection != null)
            IconButton(
              icon: const Icon(Icons.search, size: 20),
              tooltip: 'Search hadith text',
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => HadithSearchScreen(
                    collection: _collection!,
                    bookKey: widget.book.fileKey,
                    language: _langCode,
                  ),
                ),
              ),
            ),
        ],
      ),
      body: _error != null
          ? _buildError()
          : _collection == null
              ? const Center(child: CircularProgressIndicator())
              : Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 14, 20, 10),
                      child: TextField(
                        keyboardType: TextInputType.text,
                        style: AppText.body.copyWith(color: AppColors.text),
                        decoration: InputDecoration(
                          hintText: 'Chapter name, or a hadith number',
                          hintStyle:
                              AppText.body.copyWith(color: AppColors.textFaint),
                          prefixIcon: const Icon(Icons.search,
                              size: 18, color: AppColors.textMuted),
                          suffixIcon: q.isEmpty
                              ? null
                              : IconButton(
                                  icon: const Icon(Icons.close, size: 17),
                                  color: AppColors.textMuted,
                                  onPressed: () => setState(() => _query = ''),
                                ),
                          filled: true,
                          fillColor: AppColors.white,
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 12),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(4),
                            borderSide:
                                const BorderSide(color: AppColors.goldRule),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(4),
                            borderSide:
                                const BorderSide(color: AppColors.goldRule),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(4),
                            borderSide: const BorderSide(color: AppColors.gold),
                          ),
                        ),
                        onChanged: (v) => setState(() => _query = v),
                      ),
                    ),
                    // A number search should hand back the HADITH, not a
                    // chapter to go hunting in. This is the direct answer:
                    // tapping it opens the chapter already scrolled to that
                    // hadith, with the card outlined in gold.
                    if (asNumber != null)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
                        child: chapters.isEmpty
                            ? Text(
                                'No hadith numbered $asNumber in this book.',
                                style: AppText.caption
                                    .copyWith(color: AppColors.textMuted),
                              )
                            : _DirectHit(
                                hadithNumber: asNumber,
                                chapterTitle: displayTitle(chapters.first),
                                // Opens the HADITH, not the chapter it lives
                                // in. Scrolling a variable-height list to an
                                // index cannot be done reliably — searching
                                // 789 landed on 756 — so there is no scrolling
                                // here to get wrong.
                                onOpen: () => Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => HadithSingleScreen(
                                      collection: _collection!,
                                      hadithNumber: asNumber,
                                      bookKey: widget.book.fileKey,
                                      bookName: widget.book.displayName,
                                      language: _langCode,
                                    ),
                                  ),
                                ),
                              ),
                      ),
                    if (urduTitlesMissing)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                        child: Text(
                          'Chapter names are shown in English \u2014 the offline hadith dataset does not include Urdu chapter names. The hadith text itself is in Urdu.',
                          style: AppText.caption
                              .copyWith(color: AppColors.textMuted),
                        ),
                      ),
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        itemCount: chapters.length,
                        itemBuilder: (context, index) {
                          final HadithChapter chapter = chapters[index];
                          final _ChapterRange? r = _ranges[chapter.number];
                          return Container(
                            decoration: BoxDecoration(
                              border: index == 0
                                  ? null
                                  : const Border(
                                      top: BorderSide(
                                          color: AppColors.goldRuleFaint)),
                            ),
                            child: ListTile(
                              contentPadding:
                                  const EdgeInsets.symmetric(vertical: 6),
                              leading: Medallion(label: '${chapter.number}'),
                              title: Text(
                                displayTitle(chapter),
                                style: AppText.rowTitle.copyWith(
                                    fontSize: 17, color: AppColors.text),
                              ),
                              subtitle: Padding(
                                padding: const EdgeInsets.only(top: 2),
                                child: r == null
                                    ? Text(
                                        'No hadith in this chapter',
                                        style: AppText.caption.copyWith(
                                            color: AppColors.textFaint),
                                      )
                                    : Row(
                                        children: [
                                          Text(
                                            'Hadith ${r.label}',
                                            style: AppText.caption.copyWith(
                                              color: AppColors.emerald,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                          Text(
                                            '  \u00b7  ${r.count} total',
                                            style: AppText.caption.copyWith(
                                                color: AppColors.textMuted),
                                          ),
                                        ],
                                      ),
                              ),
                              trailing: const Icon(Icons.chevron_right,
                                  size: 18, color: AppColors.chevron),
                              onTap: () => Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => HadithListScreen(
                                    collection: _collection!,
                                    chapter: chapter,
                                    bookKey: widget.book.fileKey,
                                    language: _langCode,
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Medallion(icon: Icons.error_outline, size: 52),
            const SizedBox(height: 14),
            Text(
              'Could not load this book:\n$_error',
              textAlign: TextAlign.center,
              style: AppText.body.copyWith(color: AppColors.textMuted),
            ),
            const SizedBox(height: 18),
            OutlinedButton(
              onPressed: () {
                setState(() => _error = null);
                _load();
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.emerald,
                side: const BorderSide(color: AppColors.gold),
                shape:
                    RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                textStyle: AppText.body,
              ),
              child: const Text('Try again'),
            ),
          ],
        ),
      ),
    );
  }
}

class _DirectHit extends StatelessWidget {
  const _DirectHit({
    required this.hadithNumber,
    required this.chapterTitle,
    required this.onOpen,
  });

  final int hadithNumber;
  final String chapterTitle;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.white,
      borderRadius: BorderRadius.circular(4),
      child: InkWell(
        onTap: onOpen,
        borderRadius: BorderRadius.circular(4),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: AppColors.gold, width: 1.4),
          ),
          padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
          child: Row(
            children: [
              Medallion(label: '$hadithNumber', size: 36, filled: true),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'GO TO HADITH $hadithNumber',
                      style: AppText.eyebrow
                          .copyWith(letterSpacing: 1.4, color: AppColors.gold),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      chapterTitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppText.rowTitle
                          .copyWith(fontSize: 16, color: AppColors.emerald),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward, size: 18, color: AppColors.emerald),
            ],
          ),
        ),
      ),
    );
  }
}
