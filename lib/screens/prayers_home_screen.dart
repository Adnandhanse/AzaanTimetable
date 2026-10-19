import 'package:flutter/material.dart';

import '../data/ibadat_content.dart';
import '../services/app_strings.dart';
import '../theme/app_theme.dart';
import 'pillar_detail_screen.dart';
import 'dua_home_screen.dart';
import 'namaz_home_screen.dart';
import 'zakat_home_screen.dart';
import 'prophet_stories_screen.dart';

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
          'guide': IbadatContent.shahadah,
        },
        {
          'title': S.namaz,
          'subtitle': S.isUrdu ? 'پانچ وقت کی نماز' : 'The Five Daily Prayers',
          'description': S.isUrdu
              ? 'نماز کا صحیح طریقہ اور اس کی اہمیت پر احادیث۔'
              : 'The correct way to pray, and hadith on the importance of Namaz.',
          'icon': Icons.mosque_outlined,
          // Opens a fork: the prayer itself, janaza, and eidain. All three are
          // prayers, so they belong under Namaz rather than beside Umrah.
          'namaz': true,
          'guide': IbadatContent.namaz,
        },
        {
          'title': S.roza,
          'subtitle': S.isUrdu ? 'روزہ' : 'Fasting',
          'description': S.isUrdu
              ? 'روزے کی دعائیں، اہمیت اور فضیلت پر احادیث۔'
              : 'Duas for fasting, its importance and rewards, and related hadith.',
          'icon': Icons.nightlight_outlined,
          'guide': IbadatContent.roza,
        },
        {
          'title': S.zakat,
          'subtitle': S.isUrdu ? 'زکوٰۃ' : 'Almsgiving',
          'description': S.isUrdu
              ? 'زکوٰۃ کیلکولیٹر اور زکوٰۃ نہ دینے کے نتائج پر احادیث۔'
              : 'Zakat calculator and hadith on the consequences of not giving Zakat.',
          'icon': Icons.calculate_outlined,
          // Zakat opens a fork: the calculator, or the hadith. It is the only
          // pillar with two halves that do not belong on one screen.
          'zakat': true,
          'guide': IbadatContent.zakat,
        },
        {
          'title': S.hajjUmrah,
          'subtitle': S.isUrdu ? 'حج و عمرہ' : 'Pilgrimage',
          'description': S.isUrdu
              ? 'حج اور عمرہ کا صحیح طریقہ اور متعلقہ احادیث۔'
              : 'The correct way to perform Hajj and Umrah, with related hadith.',
          'icon': Icons.flight_takeoff,
          'guide': IbadatContent.hajj,
        },
      ];

  /// Umrah, deliberately outside the pillars list. It is not one of the five,
  /// and putting it in a grid headed "Five Pillars" would say it is.
  static List<Map<String, dynamic>> get _also => [
        {
          'title': S.isUrdu ? 'عمرہ' : 'Umrah',
          'subtitle': S.isUrdu ? 'عمرہ کا طریقہ' : 'Step by step',
          'description': S.isUrdu
              ? 'عمرہ کا طریقہ اور متعلقہ احادیث۔'
              : 'How to perform Umrah, with related hadith.',
          'icon': Icons.travel_explore,
          'guide': IbadatContent.umrah,
        },
        {
          'title': S.isUrdu ? 'دعائیں' : 'Duas',
          'subtitle': S.isUrdu ? 'روزمرہ کی دعائیں' : 'Everyday supplications',
          'description': S.isUrdu
              ? 'حصن المسلم سے 132 باب، عربی اور ترجمے کے ساتھ۔'
              : '132 chapters from Hisn al-Muslim, with Arabic and translation.',
          'icon': Icons.menu_book_outlined,
          // Opens the duas library, which already existed in the codebase but
          // nothing navigated to and whose asset was never declared.
          'duas': true,
        },
      ];

  @override
  Widget build(BuildContext context) {
    final items = [..._pillars, ..._also,
      <String, dynamic>{
        'title': S.isUrdu ? 'انبیاء کے واقعات' : 'Prophet Stories',
        'subtitle': S.isUrdu ? 'نبیوں کی کہانیاں' : 'Nabiyon ki kahaniyan',
        'stories': true,
      },
    ];
    const images = ['shahada', 'namaz', 'roza', 'zakat', 'hajj',
      'umrah', 'duas', 'stories'];
    // Keep the existing destinations; only the presentation changes.
    items[6]['title'] = S.isUrdu ? 'روزمرہ کی دعائیں' : 'Daily Duas';
    return Scaffold(
      appBar: AppBar(title: Text(S.prayers)),
      body: SafeArea(
        top: false,
        child: LayoutBuilder(builder: (context, constraints) {
          final scale = MediaQuery.textScalerOf(context).scale(1);
          final columns = constraints.maxWidth >= 720 ? 3
              : constraints.maxWidth < 340 || scale > 1.5 ? 1 : 2;
          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
            child: Column(children: [
              Text(S.isUrdu ? 'سیکھیں، سمجھیں، عمل کریں'
                  : 'Seekhein, samjhein, amal karein',
                textAlign: TextAlign.center,
                style: (S.isUrdu ? AppText.urduText : AppText.body)
                    .copyWith(color: AppColors.textMuted)),
              const SizedBox(height: 20),
              // Rows size naturally to their longest title, including Urdu and
              // accessibility text sizes, instead of clipping a fixed grid.
              for (var row = 0; row < items.length; row += columns)
                Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: IntrinsicHeight(child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      for (var col = 0; col < columns; col++) ...[
                        if (col > 0) const SizedBox(width: 12),
                        Expanded(child: row + col < items.length
                          ? _LearningCard(item: items[row + col],
                              image: images[row + col])
                          : const SizedBox.shrink()),
                      ],
                    ],
                  )),
                ),
            ]),
          );
        }),
      ),
    );
  }
}

class _LearningCard extends StatelessWidget {
  const _LearningCard({required this.item, required this.image});
  final Map<String, dynamic> item;
  final String image;

  void _open(BuildContext context) {
    final Widget destination;
    if (item['stories'] == true) {
      destination = const ProphetStoriesScreen();
    } else if (item['namaz'] == true) {
      destination = NamazHomeScreen(description: item['description'] as String);
    } else if (item['duas'] == true) {
      destination = const DuaHomeScreen();
    } else if (item['zakat'] == true) {
      destination = ZakatHomeScreen(description: item['description'] as String);
    } else {
      destination = PillarDetailScreen(title: item['title'] as String,
        description: item['description'] as String,
        guide: item['guide'] as IbadatGuide?);
    }
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => destination));
  }

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(20);
    return Semantics(
      button: true,
      child: Material(
        color: AppColors.white,
        shape: RoundedRectangleBorder(borderRadius: radius,
          side: BorderSide(color: AppColors.goldRule)),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => _open(context),
          child: Column(children: [
            ExcludeSemantics(child: AspectRatio(
              aspectRatio: 1.45,
              child: Ink.image(
                image: AssetImage('assets/learn_illustrations/$image.webp'),
                fit: BoxFit.cover,
              ),
            )),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 12, 10, 14),
              child: Column(children: [
                Text(item['title'] as String, textAlign: TextAlign.center,
                  style: (S.isUrdu ? AppText.urduText : AppText.rowTitle)
                    .copyWith(fontSize: S.isUrdu ? 20 : 22,
                      color: AppColors.text)),
                if (item['stories'] == true) ...[
                  const SizedBox(height: 5),
                  Text(item['subtitle'] as String, textAlign: TextAlign.center,
                    style: (S.isUrdu ? AppText.urduText : AppText.caption)
                      .copyWith(color: AppColors.textMuted)),
                ],
                const SizedBox(height: 9),
                Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Container(width: 22, height: 1, color: AppColors.goldRule),
                  Padding(padding: const EdgeInsets.symmetric(horizontal: 7),
                    child: Icon(Icons.diamond_outlined, size: 10,
                      color: AppColors.gold)),
                  Container(width: 22, height: 1, color: AppColors.goldRule),
                ]),
              ]),
            ),
          ]),
        ),
      ),
    );
  }
}
