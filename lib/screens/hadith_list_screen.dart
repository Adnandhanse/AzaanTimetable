import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/hadith.dart';
import '../services/quran_local_data_service.dart';

class HadithListScreen extends StatefulWidget {
  final HadithCollection collection;
  final HadithChapter chapter;
  final String bookKey;
  final String language;

  /// Scroll to and highlight this hadith on open. Used when someone searches
  /// for a number and wants the hadith itself, not the chapter it lives in.
  final int? highlightHadithNumber;

  const HadithListScreen({
    super.key,
    required this.collection,
    required this.chapter,
    required this.bookKey,
    required this.language,
    this.highlightHadithNumber,
  });

  @override
  State<HadithListScreen> createState() => _HadithListScreenState();
}

class _HadithListScreenState extends State<HadithListScreen> {
  Set<String> _bookmarks = {};
  final ScrollController _scroll = ScrollController();
  final GlobalKey _targetKey = GlobalKey();
  int? _highlight;

  @override
  void initState() {
    super.initState();
    _highlight = widget.highlightHadithNumber;
    _loadBookmarks();
    if (_highlight != null) _jumpToTarget();
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  /// Bring the searched hadith into view.
  ///
  /// Two passes, because a ListView.builder only builds what is on screen: an
  /// estimated jump to get the target into the build window, then
  /// ensureVisible to land on it exactly. A single ensureVisible would fail for
  /// anything far down the list, since the widget would not exist yet.
  Future<void> _jumpToTarget() async {
    final hadiths = widget.collection.hadithsInChapter(widget.chapter.number);
    final int index =
        hadiths.indexWhere((h) => h.hadithNumber == _highlight);
    if (index < 0) return;

    await WidgetsBinding.instance.endOfFrame;
    if (!mounted || !_scroll.hasClients) return;

    // Rough card height. Only needs to be close enough to put the target in
    // the build window; the second pass corrects it.
    const double estimate = 430;
    final double target =
        (index * estimate).clamp(0.0, _scroll.position.maxScrollExtent);
    _scroll.jumpTo(target);

    await WidgetsBinding.instance.endOfFrame;
    if (!mounted) return;
    final ctx = _targetKey.currentContext;
    if (ctx != null) {
      await Scrollable.ensureVisible(
        ctx,
        duration: const Duration(milliseconds: 300),
        alignment: 0.1,
      );
    }
  }

  Future<void> _loadBookmarks() async {
    final bookmarks = await QuranLocalDataService.getHadithBookmarks();
    if (!mounted) return;
    setState(() => _bookmarks = bookmarks);
  }

  Future<void> _toggleBookmark(int hadithNumber) async {
    await QuranLocalDataService.toggleHadithBookmark(widget.bookKey, widget.language, hadithNumber);
    _loadBookmarks();
  }

  bool _isBookmarked(int hadithNumber) =>
      _bookmarks.contains('${widget.bookKey}|${widget.language}|$hadithNumber');

  @override
  Widget build(BuildContext context) {
    final hadiths = widget.collection.hadithsInChapter(widget.chapter.number);
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.chapter.title, overflow: TextOverflow.ellipsis),
      ),
      body: ListView.builder(
        controller: _scroll,
        padding: const EdgeInsets.all(16),
        itemCount: hadiths.length,
        itemBuilder: (context, index) {
          final hadith = hadiths[index];
          final isBookmarked = _isBookmarked(hadith.hadithNumber);
          final bool isTarget = _highlight == hadith.hadithNumber;
          return Card(
            key: isTarget ? _targetKey : null,
            margin: const EdgeInsets.only(bottom: 12),
            // The searched hadith gets a gold border so it is obvious which
            // one the search meant, once several are on screen together.
            shape: isTarget
                ? RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4),
                    side: const BorderSide(color: AppColors.gold, width: 2),
                  )
                : null,
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Badges WRAP, bookmark is pinned.
                  //
                  // These were three items in a plain Row with a Spacer. Once
                  // hadith numbers reached three and four digits the badges
                  // outgrew the width, the Spacer collapsed to nothing, and the
                  // bookmark got pushed off the right edge — which is exactly
                  // what you saw past hadith 100. Expanded + Wrap lets the
                  // badges take a second line instead of shoving the icon out.
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.emerald.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                'Hadith ${hadith.hadithNumber}',
                                style: AppText.caption.copyWith(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.emerald,
                                ),
                              ),
                            ),
                            if (hadith.arabicNumber != null)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppColors.gold.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  'Arabic ed. ${hadith.arabicNumber}',
                                  style: AppText.caption.copyWith(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFF8A6D1E),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 4),
                      SizedBox(
                        width: 40,
                        child: IconButton(
                          padding: EdgeInsets.zero,
                          visualDensity: VisualDensity.compact,
                          icon: Icon(
                            isBookmarked
                                ? Icons.bookmark
                                : Icons.bookmark_border,
                            color: isBookmarked
                                ? AppColors.gold
                                : AppColors.chevron,
                          ),
                          tooltip: 'Bookmark',
                          onPressed: () => _toggleBookmark(hadith.hadithNumber),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  if (hadith.arabicText.isNotEmpty) ...[
                    Text(
                      hadith.arabicText,
                      textAlign: TextAlign.right,
                      textDirection: TextDirection.rtl,
                      style: AppText.arabicVerse.copyWith(fontSize: 21, color: AppColors.text),
                    ),
                    const SizedBox(height: 10),
                    const Divider(),
                    const SizedBox(height: 4),
                  ],
                  Text(hadith.text, style: const TextStyle(fontSize: 15, height: 1.5)),
                  if (hadith.grades.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      children: hadith.grades
                          .map((g) => Chip(
                                label: Text(g, style: const TextStyle(fontSize: 11)),
                                backgroundColor: AppColors.white,
                              ))
                          .toList(),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
