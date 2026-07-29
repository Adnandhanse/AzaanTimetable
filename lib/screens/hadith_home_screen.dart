import 'package:flutter/material.dart';
import '../models/hadith.dart';
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
        title: const Text('Hadith Books'),
        backgroundColor: const Color(0xFF14532D),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.bookmark),
            tooltip: 'My Bookmarks',
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
              'Kutub al-Sittah - The Six Authentic Books',
              style: TextStyle(color: Colors.grey.shade700, fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: HadithBook.values.map((book) {
                return Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  child: ListTile(
                    leading: const Icon(Icons.menu_book, color: Color(0xFF14532D)),
                    title: Text(book.displayName, style: const TextStyle(fontWeight: FontWeight.w600)),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => HadithChaptersScreen(book: book, language: _language)),
                    ),
                  ),
                );
              }).toList(),
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
