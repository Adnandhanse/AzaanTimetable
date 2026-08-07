import 'package:flutter/material.dart';

import '../data/ibadat_content.dart';
import '../services/app_strings.dart';
import '../theme/app_theme.dart';
import '../widgets/ornaments.dart';
import 'pillar_detail_screen.dart';

/// Everything under Namaz, in one place.
///
/// Janaza and Eidain were sitting in the "Also" section beside Umrah and Duas,
/// as though they were separate acts of worship. They are not — they are
/// prayers, and someone looking for how to pray a janaza looks under Namaz.
/// Putting them at the top level also pushed the pillars grid to eight cards,
/// which made the five pillars harder to see rather than easier.
class NamazHomeScreen extends StatelessWidget {
  const NamazHomeScreen({super.key, required this.description});

  final String description;

  @override
  Widget build(BuildContext context) {
    final bool urdu = S.isUrdu;

    return Scaffold(
      appBar: AppBar(title: Text(S.namaz)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
        children: <Widget>[
          Text(description,
              style: AppText.body.copyWith(color: AppColors.textMuted)),
          const SizedBox(height: 20),
          const DiamondRule(),
          const SizedBox(height: 18),
          _Option(
            icon: Icons.mosque_outlined,
            title: urdu ? 'نماز کا طریقہ' : 'Namaz Ka Tareeqa',
            subtitle: urdu
                ? 'تکبیر سے سلام تک، مکمل دعاؤں کے ساتھ'
                : 'Takbeer to salam, with the complete duas',
            guide: IbadatContent.namaz,
          ),
          const SizedBox(height: 12),
          _Option(
            icon: Icons.volunteer_activism,
            title: urdu ? 'نمازِ جنازہ' : 'Namaz-e-Janaza',
            subtitle: urdu
                ? 'چار تکبیریں اور مکمل دعا'
                : 'The four takbirs and the full dua',
            guide: IbadatContent.janaza,
          ),
          const SizedBox(height: 12),
          _Option(
            icon: Icons.celebration_outlined,
            title: urdu ? 'نمازِ عیدین' : 'Namaz-e-Eidain',
            subtitle: urdu
                ? 'عید الفطر اور عید الاضحیٰ'
                : 'Eid al-Fitr and Eid al-Adha',
            guide: IbadatContent.eidain,
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
    required this.guide,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final IbadatGuide guide;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.white,
      borderRadius: BorderRadius.circular(4),
      child: InkWell(
        borderRadius: BorderRadius.circular(4),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => PillarDetailScreen(
              title: title,
              description: subtitle,
              guide: guide,
            ),
          ),
        ),
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
