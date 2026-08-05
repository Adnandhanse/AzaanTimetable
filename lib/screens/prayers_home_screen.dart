import 'package:flutter/material.dart';

import '../data/ibadat_content.dart';
import '../services/app_strings.dart';
import '../theme/app_theme.dart';
import '../widgets/ornaments.dart';
import 'pillar_detail_screen.dart';
import 'zakat_calculator_screen.dart';

class PrayersHomeScreen extends StatelessWidget {
  const PrayersHomeScreen({super.key});

  /// 'guide' is null for pillars with no step-by-step content yet, and the card
  /// says so rather than opening an empty page.
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
          'guide': IbadatContent.namaz,
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
          // Zakat opens the calculator rather than a step guide — its steps are
          // arithmetic, not actions.
          'calculator': true,
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
          const SizedBox(height: 14),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: EdgeInsets.zero,
            itemCount: pillars.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              // Room for the medallion, two lines of title and two of
              // subtitle. The Hadith grid clipped at 0.80 — no reason to
              // relearn that here.
              childAspectRatio: 0.82,
            ),
            itemBuilder: (context, i) => _PillarCard(pillar: pillars[i]),
          ),
        ],
      ),
    );
  }
}

class _PillarCard extends StatelessWidget {
  const _PillarCard({required this.pillar});

  final Map<String, dynamic> pillar;

  @override
  Widget build(BuildContext context) {
    final IbadatGuide? guide = pillar['guide'] as IbadatGuide?;

    return Material(
      color: AppColors.white,
      borderRadius: BorderRadius.circular(4),
      child: InkWell(
        borderRadius: BorderRadius.circular(4),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => pillar['calculator'] == true
                ? const ZakatCalculatorScreen()
                : PillarDetailScreen(
                    title: pillar['title'] as String,
                    description: pillar['description'] as String,
                    guide: guide,
                  ),
          ),
        ),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: AppColors.goldRule),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Medallion(icon: pillar['icon'] as IconData, size: 40),
              const SizedBox(height: 12),
              Text(
                pillar['title'] as String,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style:
                    AppText.rowTitle.copyWith(fontSize: 17, color: AppColors.text),
              ),
              const SizedBox(height: 4),
              Text(
                pillar['subtitle'] as String,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppText.caption.copyWith(color: AppColors.emerald),
              ),
              const SizedBox(height: 8),
              Container(width: 22, height: 1, color: AppColors.goldRule),
              const SizedBox(height: 8),
              Text(
                pillar['calculator'] == true
                    ? S.zakatCalculator
                    : guide == null
                        ? S.comingSoon
                        : S.stepByStep,
                style: AppText.caption.copyWith(
                  color: guide == null && pillar['calculator'] != true
                      ? AppColors.textFaint
                      : AppColors.gold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
