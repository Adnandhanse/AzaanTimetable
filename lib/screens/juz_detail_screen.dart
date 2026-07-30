import 'package:flutter/material.dart';
import '../models/quran.dart';
import '../data/juz_boundaries.dart';

class JuzDetailScreen extends StatelessWidget {
  final int juzNumber;
  final List<Surah> allSurahs;

  const JuzDetailScreen({super.key, required this.juzNumber, required this.allSurahs});

  @override
  Widget build(BuildContext context) {
    final startIndex = juzBoundaries.indexWhere((j) => j.$1 == juzNumber);
    final (_, startSurah, startVerse) = juzBoundaries[startIndex];
    final hasNext = startIndex + 1 < juzBoundaries.length;
    final (int, int)? end = hasNext ? (juzBoundaries[startIndex + 1].$2, juzBoundaries[startIndex + 1].$3) : null;

    // Build the list of (surah, verse) items that fall within this Juz.
    final items = <(Surah, QuranVerse)>[];
    for (final surah in allSurahs) {
      if (surah.number < startSurah) continue;
      if (end != null && surah.number > end.$1) break;
      for (final verse in surah.verses) {
        if (surah.number == startSurah && verse.number < startVerse) continue;
        if (end != null && surah.number == end.$1 && verse.number >= end.$2) break;
        if (end != null && surah.number > end.$1) break;
        items.add((surah, verse));
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Juz $juzNumber'),
        backgroundColor: const Color(0xFF1F5E4A),
        foregroundColor: Colors.white,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: items.length,
        itemBuilder: (context, index) {
          final (surah, verse) = items[index];
          final isNewSurah = index == 0 || items[index - 1].$1.number != surah.number;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (isNewSurah)
                Padding(
                  padding: const EdgeInsets.only(top: 12, bottom: 8),
                  child: Text(
                    '${surah.transliteration} (${surah.arabicName})',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF1F5E4A)),
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
                        style: const TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        verse.arabicText,
                        textAlign: TextAlign.right,
                        textDirection: TextDirection.rtl,
                        style: const TextStyle(fontSize: 22, height: 1.8, fontFamily: 'serif'),
                      ),
                      const SizedBox(height: 8),
                      const Divider(),
                      Text(verse.translation, style: const TextStyle(fontSize: 15)),
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
