import 'package:flutter/material.dart';

import '../data/ibadat_content.dart';
import '../services/hadith_link.dart';
import '../theme/app_theme.dart';
import '../widgets/ornaments.dart';

/// Step-by-step guide for an act of worship, with the hadith cited beneath each
/// step and every citation tappable straight into the hadith reader.
class PillarDetailScreen extends StatelessWidget {
  final String title;
  final String description;

  /// Null for pillars with no guide written yet.
  final IbadatGuide? guide;

  const PillarDetailScreen({
    super.key,
    required this.title,
    required this.description,
    this.guide,
  });

  @override
  Widget build(BuildContext context) {
    final IbadatGuide? g = guide;

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: g == null ? _buildEmpty(context) : _buildGuide(context, g),
    );
  }

  Widget _buildEmpty(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
      children: <Widget>[
        Text(description,
            style: AppText.body.copyWith(color: AppColors.textMuted)),
        const SizedBox(height: 30),
        Center(
          child: Column(
            children: <Widget>[
              const Medallion(icon: Icons.menu_book_outlined, size: 52),
              const SizedBox(height: 14),
              Text(
                'The step-by-step guide for $title has not been written yet.',
                textAlign: TextAlign.center,
                style: AppText.body.copyWith(color: AppColors.textMuted),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildGuide(BuildContext context, IbadatGuide g) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
      children: <Widget>[
        // Said plainly, at the top, while it is true. A worship guide that
        // looks authoritative before anyone qualified has checked it is worse
        // than one that admits what it is — people act on this.
        if (!g.reviewed)
          Container(
            decoration: BoxDecoration(
              color: AppColors.warningBg,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: AppColors.gold),
            ),
            padding: const EdgeInsets.all(13),
            margin: const EdgeInsets.only(bottom: 18),
            child: Row(
              children: <Widget>[
                const Icon(Icons.info_outline,
                    size: 19, color: AppColors.warningFg),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Draft. This guide and its references have not yet been checked by a scholar. Please verify before relying on it.',
                    style:
                        AppText.caption.copyWith(color: AppColors.warningFg),
                  ),
                ),
              ],
            ),
          ),

        Text(description,
            style: AppText.body.copyWith(color: AppColors.textMuted)),
        const SizedBox(height: 20),

        for (final IbadatSection section in g.sections) ...<Widget>[
          SectionRule(label: section.title, trailingDiamond: true),
          const SizedBox(height: 6),
          for (int i = 0; i < section.steps.length; i++)
            _StepCard(step: section.steps[i], number: i + 1),
          const SizedBox(height: 16),
        ],
      ],
    );
  }
}

class _StepCard extends StatelessWidget {
  const _StepCard({required this.step, required this.number});

  final IbadatStep step;
  final int number;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: AppColors.goldRule),
      ),
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Medallion(label: '$number', size: 34),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(step.title,
                        style: AppText.rowTitle
                            .copyWith(fontSize: 17, color: AppColors.text)),
                    const SizedBox(height: 3),
                    Text(step.instruction,
                        style: AppText.body.copyWith(color: AppColors.text)),
                  ],
                ),
              ),
            ],
          ),

          if (step.arabic != null) ...<Widget>[
            const SizedBox(height: 12),
            Container(height: 1, color: AppColors.goldRuleFaint),
            const SizedBox(height: 10),
            Directionality(
              textDirection: TextDirection.rtl,
              child: Text(
                step.arabic!,
                textAlign: TextAlign.right,
                style: AppText.arabicVerse.copyWith(color: AppColors.emerald),
              ),
            ),
            if (step.transliteration != null)
              Text(step.transliteration!,
                  style: AppText.caption.copyWith(color: AppColors.textMuted)),
          ],

          if (step.practiceDiffers != null) ...<Widget>[
            const SizedBox(height: 10),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const Padding(
                  padding: EdgeInsets.only(top: 1),
                  child: Icon(Icons.compare_arrows,
                      size: 15, color: AppColors.gold),
                ),
                const SizedBox(width: 7),
                Expanded(
                  child: Text(
                    step.practiceDiffers!,
                    style: AppText.caption.copyWith(color: AppColors.textMid),
                  ),
                ),
              ],
            ),
          ],

          if (step.refs.isNotEmpty) ...<Widget>[
            const SizedBox(height: 12),
            Container(height: 1, color: AppColors.goldRuleFaint),
            const SizedBox(height: 6),
            Text(
              'EVIDENCE',
              style: AppText.eyebrow
                  .copyWith(letterSpacing: 1.4, color: AppColors.textMuted),
            ),
            for (final HadithRef r in step.refs) HadithRefChip(ref: r),
          ],
        ],
      ),
    );
  }
}
