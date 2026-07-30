import 'package:flutter/material.dart';
import '../services/app_strings.dart';
import 'pillar_detail_screen.dart';

class PrayersHomeScreen extends StatelessWidget {
  const PrayersHomeScreen({super.key});

  static List<Map<String, String>> get _pillars => [
    {
      'title': S.shahada,
      'subtitle': S.isUrdu ? 'ایمان کا اقرار' : 'The Declaration of Faith',
      'description': S.isUrdu ? 'شہادت کی اہمیت بیان کرنے والی احادیث۔' : 'Hadith explaining the value and meaning of Shahada.',
    },
    {
      'title': S.namaz,
      'subtitle': S.isUrdu ? 'پانچ وقت کی نماز' : 'The Five Daily Prayers',
      'description': S.isUrdu ? 'نماز کا صحیح طریقہ اور اس کی اہمیت پر احادیث۔' : 'The correct way to pray, and hadith on the importance of Namaz.',
    },
    {
      'title': S.roza,
      'subtitle': S.isUrdu ? 'روزہ' : 'Fasting',
      'description': S.isUrdu ? 'روزے کی دعائیں، اہمیت اور فضیلت پر احادیث۔' : 'Duas for fasting, its importance and rewards, and related hadith.',
    },
    {
      'title': S.zakat,
      'subtitle': S.isUrdu ? 'زکوٰۃ' : 'Almsgiving',
      'description': S.isUrdu ? 'زکوٰۃ کیلکولیٹر اور زکوٰۃ نہ دینے کے نتائج پر احادیث۔' : 'Zakat calculator and hadith on the consequences of not giving Zakat.',
    },
    {
      'title': S.hajjUmrah,
      'subtitle': S.isUrdu ? 'حج و عمرہ' : 'Pilgrimage',
      'description': S.isUrdu ? 'حج اور عمرہ کا صحیح طریقہ اور متعلقہ احادیث۔' : 'The correct way to perform Hajj and Umrah, with related hadith.',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(S.prayers),
        backgroundColor: const Color(0xFF1F5E4A),
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            S.fivePillars,
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF1F5E4A)),
          ),
          const SizedBox(height: 12),
          ..._pillars.map((pillar) => Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(14),
                  leading: const Icon(Icons.mosque, color: Color(0xFF1F5E4A), size: 32),
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
