import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/hadith.dart';
import '../services/quran_local_data_service.dart';

class HadithListScreen extends StatefulWidget {
  final HadithCollection collection;
  final HadithChapter chapter;
  final String bookKey;
  final String language;

  const HadithListScreen({
    super.key,
    required this.collection,
    required this.chapter,
    required this.bookKey,
    required this.language,
  });

  @override
  State<HadithListScreen> createState() => _HadithListScreenState();
}

class _HadithListScreenState extends State<HadithListScreen> {
  Set<String> _bookmarks = {};

  @override
  void initState() {
    super.initState();
    _loadBookmarks();
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
        padding: const EdgeInsets.all(16),
        itemCount: hadiths.length,
        itemBuilder: (context, index) {
          final hadith = hadiths[index];
          final isBookmarked = _isBookmarked(hadith.hadithNumber);
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
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
