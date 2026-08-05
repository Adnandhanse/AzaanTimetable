import 'package:flutter/material.dart';

import '../data/ibadat_content.dart';
import '../services/app_strings.dart';
import '../theme/app_theme.dart';
import '../widgets/ornaments.dart';
import 'pillar_detail_screen.dart';
import 'zakat_calculator_screen.dart';

/// Zakat has two halves that do not belong on the same screen: the arithmetic,
/// and the reasons for it. This is the fork.
///
/// The other pillars open straight into their guide because they have only one
/// half. Making Zakat consistent with them would have meant either burying the
/// calculator inside a hadith list or dropping someone into a calculator with no
/// explanation of why they are filling it in.
class ZakatHomeScreen extends StatelessWidget {
  const ZakatHomeScreen({super.key, required this.description});

  final String description;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(S.zakat)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
        children: <Widget>[
          Text(description,
              style: AppText.body.copyWith(color: AppColors.textMuted)),
          const SizedBox(height: 20),
          const DiamondRule(),
          const SizedBox(height: 18),
          _Option(
            icon: Icons.calculate_outlined,
            title: S.zakatCalculator,
            subtitle: S.isUrdu
                ? 'سونا، چاندی اور نقد رقم سے واجب زکوٰۃ معلوم کریں'
                : 'Work out what is due from gold, silver and cash',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                  builder: (_) => const ZakatCalculatorScreen()),
            ),
          ),
          const SizedBox(height: 12),
          _Option(
            icon: Icons.auto_stories_outlined,
            title: S.isUrdu ? 'متعلقہ احادیث' : 'Related Hadith',
            subtitle: S.isUrdu
                ? 'زکوٰۃ کی اہمیت اور نہ دینے پر وعید'
                : 'Its importance, and the warning for withholding it',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => PillarDetailScreen(
                  title: S.zakat,
                  description: description,
                  guide: IbadatContent.zakat,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Option extends StatelessWidget {
  const _Option({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.white,
      borderRadius: BorderRadius.circular(4),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(4),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: AppColors.goldRule),
          ),
          padding: const EdgeInsets.fromLTRB(14, 16, 14, 16),
          child: Row(
            children: <Widget>[
              Medallion(icon: icon, size: 40),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(title,
                        style: AppText.rowTitle
                            .copyWith(fontSize: 17, color: AppColors.text)),
                    const SizedBox(height: 2),
                    Text(subtitle,
                        style: AppText.caption
                            .copyWith(color: AppColors.textMuted)),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right,
                  size: 18, color: AppColors.chevron),
            ],
          ),
        ),
      ),
    );
  }
}
