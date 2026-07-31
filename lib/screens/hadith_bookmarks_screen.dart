import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/hadith.dart';
import '../services/hadith_repository.dart';
import '../services/quran_local_data_service.dart';

class HadithBookmarksScreen extends StatefulWidget {
  const HadithBookmarksScreen({super.key});

  @override
  State<HadithBookmarksScreen> createState() => _HadithBookmarksScreenState();
}

class _HadithBookmarksScreenState extends State<HadithBookmarksScreen> {
  List<(String bookName, HadithItem item)> _bookmarkedItems = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final bookmarks = await QuranLocalDataService.getHadithBookmarks();
    final items = <(String, HadithItem)>[];

    for (final id in bookmarks) {
      final parts = id.split('|');
      if (parts.length != 3) continue;
      final bookKey = parts[0];
      final lang = parts[1];
      final hadithNumber = int.tryParse(parts[2]);
      if (hadithNumber == null) continue;

      final book = HadithBook.values.firstWhere((b) => b.fileKey == bookKey, orElse: () => HadithBook.bukhari);
      final language = lang == 'eng' ? HadithLanguage.english : HadithLanguage.urdu;

      try {
        final collection = await HadithRepository.loadCollection(book, language);
        final item = collection.hadiths.firstWhere((h) => h.hadithNumber == hadithNumber);
        items.add(('${book.displayName} ($lang)', item));
      } catch (_) {
        // Skip if not found - dataset shouldn't change, but stay safe.
      }
    }

    if (!mounted) return;
    setState(() {
      _bookmarkedItems = items;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Bookmarked Hadiths'),
        backgroundColor: AppColors.emerald,
        foregroundColor: Colors.white,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _bookmarkedItems.isEmpty
              ? const Center(
                  child: Text('No bookmarks yet.\nTap the bookmark icon on any hadith to save it here.',
                      textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _bookmarkedItems.length,
                  itemBuilder: (context, index) {
                    final (bookName, hadith) = _bookmarkedItems[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 10),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('$bookName • Hadith ${hadith.hadithNumber}',
                                style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.emerald, fontSize: 12)),
                            const SizedBox(height: 6),
                            Text(hadith.text, style: const TextStyle(fontSize: 14)),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
