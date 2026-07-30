import 'package:flutter/material.dart';
import '../services/app_strings.dart';
import '../theme/app_theme.dart';
import '../widgets/ornaments.dart';
import 'pillar_detail_screen.dart';

class PrayersHomeScreen extends StatelessWidget {
  const PrayersHomeScreen({super.key});

  static List<Map<String, dynamic>> get _pillars => [
        {
          'title': S.shahada,
          'subtitle': S.isUrdu ? 'ایمان کا اقرار' : 'The Declaration of Faith',
          'description': S.isUrdu
              ? 'شہادت کی اہمیت بیان کرنے والی احادیث۔'
              : 'Hadith explaining the value and meaning of Shahada.',
          'icon': Icons.star_border,
        },
        {
          'title': S.namaz,
          'subtitle': S.isUrdu ? 'پانچ وقت کی نماز' : 'The Five Daily Prayers',
          'description': S.isUrdu
              ? 'نماز کا صحیح طریقہ اور اس کی اہمیت پر احادیث۔'
              : 'The correct way to pray, and hadith on the importance of Namaz.',
          'icon': Icons.mosque_outlined,
        },
        {
          'title': S.roza,
          'subtitle': S.isUrdu ? 'روزہ' : 'Fasting',
          'description': S.isUrdu
              ? 'روزے کی دعائیں، اہمیت اور فضیلت پر احادیث۔'
              : 'Duas for fasting, its importance and rewards, and related hadith.',
          'icon': Icons.nightlight_outlined,
        },
        {
          'title': S.zakat,
          'subtitle': S.isUrdu ? 'زکوٰۃ' : 'Almsgiving',
          'description': S.isUrdu
              ? 'زکوٰۃ کیلکولیٹر اور زکوٰۃ نہ دینے کے نتائج پر احادیث۔'
              : 'Zakat calculator and hadith on the consequences of not giving Zakat.',
          'icon': Icons.calculate_outlined,
        },
        {
          'title': S.hajjUmrah,
          'subtitle': S.isUrdu ? 'حج و عمرہ' : 'Pilgrimage',
          'description': S.isUrdu
              ? 'حج اور عمرہ کا صحیح طریقہ اور متعلقہ احادیث۔'
              : 'The correct way to perform Hajj and Umrah, with related hadith.',
          'icon': Icons.flight_takeoff,
        },
      ];

  @override
  Widget build(BuildContext context) {
    final pillars = _pillars;

    return Scaffold(
      appBar: AppBar(title: Text(S.prayers)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
        children: [
          SectionRule(label: S.fivePillars, trailingDiamond: true),
          const SizedBox(height: 4),
          for (int i = 0; i < pillars.length; i++)
            _PillarRow(
              pillar: pillars[i],
              index: i + 1,
              showDivider: i > 0,
            ),
        ],
      ),
    );
  }
}

class _PillarRow extends StatelessWidget {
  const _PillarRow({
    required this.pillar,
    required this.index,
    required this.showDivider,
  });

  final Map<String, dynamic> pillar;
  final int index;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => PillarDetailScreen(
            title: pillar['title'] as String,
            description: pillar['description'] as String,
          ),
        ),
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          border: showDivider
              ? const Border(top: BorderSide(color: AppColors.goldRuleFaint))
              : null,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Medallion(icon: pillar['icon'] as IconData, size: 38),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    pillar['title'] as String,
                    style: AppText.rowTitle
                        .copyWith(fontSize: 18, color: AppColors.text),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    pillar['subtitle'] as String,
                    style: AppText.caption.copyWith(color: AppColors.emerald),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    pillar['description'] as String,
                    style: AppText.caption.copyWith(color: AppColors.textMuted),
                  ),
                ],
              ),
            ),
            const Padding(
              padding: EdgeInsets.only(top: 8, left: 6),
              child: Icon(Icons.chevron_right,
                  size: 18, color: AppColors.chevron),
            ),
          ],
        ),
      ),
    );
  }
}
