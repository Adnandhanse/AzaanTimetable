import 'package:flutter/material.dart';
import 'pillar_detail_screen.dart';

class PrayersHomeScreen extends StatelessWidget {
  const PrayersHomeScreen({super.key});

  static const List<Map<String, String>> _pillars = [
    {
      'title': 'Shahada',
      'subtitle': 'The Declaration of Faith',
      'description': 'Hadith explaining the value and meaning of Shahada.',
    },
    {
      'title': 'Namaz (Salah)',
      'subtitle': 'The Five Daily Prayers',
      'description': 'The correct way to pray, and hadith on the importance of Namaz.',
    },
    {
      'title': 'Roza (Sawm)',
      'subtitle': 'Fasting',
      'description': 'Duas for fasting, its importance and rewards, and related hadith.',
    },
    {
      'title': 'Zakat',
      'subtitle': 'Almsgiving',
      'description': 'Zakat calculator and hadith on the consequences of not giving Zakat.',
    },
    {
      'title': 'Hajj / Umrah',
      'subtitle': 'Pilgrimage',
      'description': 'The correct way to perform Hajj and Umrah, with related hadith.',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Prayers'),
        backgroundColor: const Color(0xFF14532D),
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'The Five Pillars of Islam',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF14532D)),
          ),
          const SizedBox(height: 12),
          ..._pillars.map((pillar) => Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(14),
                  leading: const Icon(Icons.mosque, color: Color(0xFF14532D), size: 32),
                  title: Text(pillar['title']!, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text('${pillar['subtitle']}\n${pillar['description']}'),
                  ),
                  isThreeLine: true,
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => PillarDetailScreen(
                        title: pillar['title']!,
                        description: pillar['description']!,
                      ),
                    ),
                  ),
                ),
              )),
        ],
      ),
    );
  }
}
