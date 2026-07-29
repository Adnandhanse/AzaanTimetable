import 'package:flutter/material.dart';
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
        backgroundColor: const Color(0xFF14532D),
        foregroundColor: Colors.white,
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
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF14532D).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'Hadith No. ${hadith.hadithNumber}',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF14532D)),
                        ),
                      ),
                      if (hadith.arabicNumber != null) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFD4AF37).withOpacity(0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'Book Ref. ${hadith.arabicNumber}',
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF8A6D1E)),
                          ),
                        ),
                      ],
                      const Spacer(),
                      IconButton(
                        icon: Icon(
                          isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                          color: isBookmarked ? const Color(0xFFD4AF37) : Colors.grey,
                        ),
                        onPressed: () => _toggleBookmark(hadith.hadithNumber),
                      ),
                    ],
                  ),
                  if (hadith.arabicText.isNotEmpty) ...[
                    Text(
                      hadith.arabicText,
                      textAlign: TextAlign.right,
                      textDirection: TextDirection.rtl,
                      style: const TextStyle(fontSize: 18, height: 1.8, fontFamily: 'serif'),
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
                                backgroundColor: const Color(0xFFF0FDF4),
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
