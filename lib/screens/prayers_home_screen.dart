import 'package:flutter/material.dart';
import '../services/app_strings.dart';
import 'pillar_detail_screen.dart';

class PrayersHomeScreen extends StatelessWidget {
  const PrayersHomeScreen({super.key});

  static List<Map<String, dynamic>> get _pillars => [
    {
      'title': S.shahada,
      'subtitle': S.isUrdu ? 'ایمان کا اقرار' : 'The Declaration of Faith',
      'description': S.isUrdu ? 'شہادت کی اہمیت بیان کرنے والی احادیث۔' : 'Hadith explaining the value and meaning of Shahada.',
      'icon': Icons.star_outline,
    },
    {
      'title': S.namaz,
      'subtitle': S.isUrdu ? 'پانچ وقت کی نماز' : 'The Five Daily Prayers',
      'description': S.isUrdu ? 'نماز کا صحیح طریقہ اور اس کی اہمیت پر احادیث۔' : 'The correct way to pray, and hadith on the importance of Namaz.',
      'icon': Icons.mosque,
    },
    {
      'title': S.roza,
      'subtitle': S.isUrdu ? 'روزہ' : 'Fasting',
      'description': S.isUrdu ? 'روزے کی دعائیں، اہمیت اور فضیلت پر احادیث۔' : 'Duas for fasting, its importance and rewards, and related hadith.',
      'icon': Icons.nightlight_round,
    },
    {
      'title': S.zakat,
      'subtitle': S.isUrdu ? 'زکوٰۃ' : 'Almsgiving',
      'description': S.isUrdu ? 'زکوٰۃ کیلکولیٹر اور زکوٰۃ نہ دینے کے نتائج پر احادیث۔' : 'Zakat calculator and hadith on the consequences of not giving Zakat.',
      'icon': Icons.calculate_outlined,
    },
    {
      'title': S.hajjUmrah,
      'subtitle': S.isUrdu ? 'حج و عمرہ' : 'Pilgrimage',
      'description': S.isUrdu ? 'حج اور عمرہ کا صحیح طریقہ اور متعلقہ احادیث۔' : 'The correct way to perform Hajj and Umrah, with related hadith.',
      'icon': Icons.flight_takeoff,
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
          Text(
            S.fivePillars,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF1F5E4A)),
          ),
          const SizedBox(height: 14),
          ..._pillars.map((pillar) => Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFCFAF5),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: const Color(0xFFD8BE8A).withOpacity(0.4)),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 3)),
                  ],
                ),
                child: InkWell(
                  borderRadius: BorderRadius.circular(18),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => PillarDetailScreen(
                        title: pillar['title']!,
                        description: pillar['description']!,
                      ),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            color: const Color(0xFF1F5E4A).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Icon(pillar['icon'] as IconData, color: const Color(0xFFC8A86B), size: 26),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(pillar['title']!,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: Color(0xFF2F3A35))),
                              const SizedBox(height: 2),
                              Text(pillar['subtitle']!,
                                  style: const TextStyle(fontSize: 13, color: Color(0xFF1F5E4A), fontWeight: FontWeight.w600)),
                              const SizedBox(height: 4),
                              Text(pillar['description']!,
                                  style: const TextStyle(fontSize: 13, color: Color(0xFF7A7A7A))),
                            ],
                          ),
                        ),
                        const Icon(Icons.chevron_right, color: Color(0xFF7A7A7A)),
                      ],
                    ),
                  ),
                ),
              )),
        ],
      ),
    );
  }
}
