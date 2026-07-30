import 'package:flutter/material.dart';
import '../models/hadith.dart';
import '../services/app_strings.dart';
import 'hadith_chapters_screen.dart';
import 'hadith_bookmarks_screen.dart';

class HadithHomeScreen extends StatefulWidget {
  const HadithHomeScreen({super.key});

  @override
  State<HadithHomeScreen> createState() => _HadithHomeScreenState();
}

class _HadithHomeScreenState extends State<HadithHomeScreen> {
  HadithLanguage _language = HadithLanguage.english;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(S.hadithBooks),
        backgroundColor: const Color(0xFF1F5E4A),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.bookmark),
            tooltip: S.myBookmarks,
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const HadithBookmarksScreen()),
            ),
          ),
          PopupMenuButton<HadithLanguage>(
            icon: const Icon(Icons.translate),
            onSelected: (lang) => setState(() => _language = lang),
            itemBuilder: (_) => const [
              PopupMenuItem(value: HadithLanguage.english, child: Text('English')),
              PopupMenuItem(value: HadithLanguage.urdu, child: Text('اردو (Urdu)')),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              S.sixAuthenticBooks,
              style: const TextStyle(color: Color(0xFF7A7A7A), fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                childAspectRatio: 1.3,
              ),
              itemCount: HadithBook.values.length,
              itemBuilder: (context, index) {
                final book = HadithBook.values[index];
                return Card(
                  color: const Color(0xFFFCFAF5),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => HadithChaptersScreen(book: book, language: _language)),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.menu_book, color: Color(0xFF1F5E4A), size: 28),
                          const SizedBox(height: 8),
                          Text(
                            book.displayName,
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              'Source: hadith-api (Unlicense/Public Domain) • Works fully offline',
              style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
            ),
          ),
        ],
      ),
    );
  }
}
