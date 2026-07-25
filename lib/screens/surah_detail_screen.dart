import 'package:flutter/material.dart';
import '../models/quran.dart';

class SurahDetailScreen extends StatelessWidget {
  final Surah surah;
  const SurahDetailScreen({super.key, required this.surah});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${surah.number}. ${surah.transliteration}'),
        backgroundColor: const Color(0xFF14532D),
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            color: const Color(0xFFF0FDF4),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Text(surah.arabicName, style: const TextStyle(fontSize: 32, fontFamily: 'serif')),
                  const SizedBox(height: 4),
                  Text(
                    '${surah.englishMeaning} • ${surah.type[0].toUpperCase()}${surah.type.substring(1)} • ${surah.totalVerses} verses',
                    style: const TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          ...surah.verses.map((verse) => Card(
                margin: const EdgeInsets.only(bottom: 10),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 12,
                            backgroundColor: const Color(0xFF14532D),
                            child: Text('${verse.number}', style: const TextStyle(fontSize: 11, color: Colors.white)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        verse.arabicText,
                        textAlign: TextAlign.right,
                        textDirection: TextDirection.rtl,
                        style: const TextStyle(fontSize: 22, height: 1.8, fontFamily: 'serif'),
                      ),
                      const SizedBox(height: 8),
                      const Divider(),
                      const SizedBox(height: 4),
                      Text(verse.translation, style: const TextStyle(fontSize: 15, color: Colors.black87)),
                    ],
                  ),
                ),
              )),
        ],
      ),
    );
  }
}
