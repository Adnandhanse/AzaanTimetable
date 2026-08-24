import 'package:flutter/material.dart';

import '../models/hadith.dart';
import '../services/app_strings.dart';
import '../services/quran_local_data_service.dart';
import '../theme/app_theme.dart';
import '../widgets/ornaments.dart';
import 'hadith_chapters_screen.dart';
import 'hadith_bookmarks_screen.dart';

/// Arabic title, volume count, and how many hadith the app actually holds.
///
/// The hadith figures are the count of entries WITH TEXT in this app's own data
/// files, not the nominal totals — Sahih Muslim's file has 7,563 entries but 203
/// of them are empty and are filtered out before display. Printing 7,563 next to
/// a book that shows 7,360 would be a number the app itself contradicts.
const Map<HadithBook, (String, int, int)> _bookMeta =
    <HadithBook, (String, int, int)>{
  HadithBook.bukhari: ('صحيح البخاري', 9, 7580),
  HadithBook.muslim: ('صحيح مسلم', 7, 7360),
  HadithBook.abudawud: ('سنن أبي داود', 4, 5272),
  HadithBook.tirmidhi: ('جامع الترمذي', 6, 3926),
  HadithBook.nasai: ('سنن النسائي', 6, 5679),
  HadithBook.ibnmajah: ('سنن ابن ماجه', 5, 4340),
};

class HadithHomeScreen extends StatefulWidget {
  const HadithHomeScreen({super.key});

  @override
  State<HadithHomeScreen> createState() => _HadithHomeScreenState();
}

class _HadithHomeScreenState extends State<HadithHomeScreen> {
  /// Urdu by default. Loaded from storage, so a switch to English persists.
  HadithLanguage _language = HadithLanguage.urdu;

  @override
  void initState() {
    super.initState();
    _loadLanguage();
  }

  Future<void> _loadLanguage() async {
    final bool urdu = await QuranLocalDataService.getHadithUrdu();
    if (!mounted) return;
    setState(
        () => _language = urdu ? HadithLanguage.urdu : HadithLanguage.english);
  }

  Future<void> _setLanguage(HadithLanguage lang) async {
    setState(() => _language = lang);
    await QuranLocalDataService.setHadithUrdu(lang == HadithLanguage.urdu);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(S.hadithBooks),
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.bookmark_border, size: 20),
            tooltip: S.myBookmarks,
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                  builder: (_) => const HadithBookmarksScreen()),
            ),
          ),
        ],
        // Directly visible, not a translate-icon popup menu that gave no
        // hint it was even there - same fix as the Qur'an section's language
        // bar, and for the same reason.
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(44),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
            child: Row(
              children: <Widget>[
                _LangSegment(
                  label: 'English',
                  selected: _language == HadithLanguage.english,
                  onTap: () => _setLanguage(HadithLanguage.english),
                ),
                _LangSegment(
                  label: '\u0627\u0631\u062F\u0648',
                  selected: _language == HadithLanguage.urdu,
                  onTap: () => _setLanguage(HadithLanguage.urdu),
                ),
              ],
            ),
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        children: <Widget>[
          SectionRule(label: S.sixAuthenticBooks, trailingDiamond: true),
          const SizedBox(height: 14),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: EdgeInsets.zero,
            itemCount: HadithBook.values.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              // 0.86, up from 0.74.
              //
              // The cards were far taller than their contents, so each one had
              // an empty band across the bottom half — the single thing that
              // made this screen look unfinished.
              //
              // Measured: medallion 38 + 10 + a fixed 38pt name block + 4 +
              // Arabic 22 + 8 + rule + 8 + two lines of counts 28, inside 26pt
              // of padding, is about 184pt in a 158pt-wide card. 0.86 gives 184.
              childAspectRatio: 0.86,
            ),
            itemBuilder: (BuildContext context, int index) {
              final HadithBook book = HadithBook.values[index];
              final (String, int, int)? meta = _bookMeta[book];
              return _BookCard(
                number: index + 1,
                name: book.localName,
                arabicName: meta?.$1 ?? '',
                volumes: meta?.$2 ?? 0,
                hadithCount: meta?.$3 ?? 0,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) =>
                        HadithChaptersScreen(book: book, language: _language),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 18),
          Row(
            children: <Widget>[
              Expanded(
                child: _FooterTile(
                  icon: Icons.bookmark_border,
                  label: S.myBookmarks,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                        builder: (_) => const HadithBookmarksScreen()),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Source: hadith-api (Unlicense / Public Domain) · Works fully offline',
            textAlign: TextAlign.center,
            style: AppText.caption.copyWith(color: AppColors.textFaint),
          ),
        ],
      ),
    );
  }
}

class _BookCard extends StatelessWidget {
  const _BookCard({
    required this.number,
    required this.name,
    required this.arabicName,
    required this.volumes,
    required this.hadithCount,
    required this.onTap,
  });

  final int number;
  final String name;
  final String arabicName;
  final int volumes;
  final int hadithCount;
  final VoidCallback onTap;

  /// 7580 → "7,580". Read at a glance rather than counted digit by digit.
  static String _grouped(int n) => n.toString().replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+$)'), (Match m) => '${m[1]},');

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
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 13),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Medallion(label: '$number', size: 36, filled: true),
              const SizedBox(height: 10),

              // A FIXED-HEIGHT NAME BLOCK.
              //
              // Five of the six names wrap to two lines — "Sahih al-Bukhari",
              // "Sunan Abu Dawud", "Jami' at-Tirmidhi", "Sunan an-Nasa'i",
              // "Sunan Ibn Majah" — while "Sahih Muslim" fits on one. That made
              // every element below it sit at a different height in that one
              // card, which is what made the grid look untidy.
              //
              // Reserving two lines and centring within them keeps all six cards
              // aligned regardless of how the text falls.
              SizedBox(
                height: 38,
                child: Center(
                  child: Text(
                    name,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.rowTitle.copyWith(
                      fontSize: 14.5,
                      height: 1.25,
                      color: AppColors.text,
                    ),
                  ),
                ),
              ),

              if (arabicName.isNotEmpty) ...<Widget>[
                const SizedBox(height: 2),
                Text(
                  arabicName,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.arabic.copyWith(
                    fontSize: 15,
                    height: 1.4,
                    color: AppColors.gold,
                  ),
                ),
              ],

              const SizedBox(height: 8),
              Container(width: 22, height: 1, color: AppColors.goldRule),
              const SizedBox(height: 8),

              // HOW MANY HADITH, above the volume count.
              //
              // The empty half of the card was the obvious place for the one
              // fact a reader actually wants before opening a collection, and it
              // was nowhere in the app. Volumes describe the printed edition;
              // the hadith count describes what is in your hand.
              Text(
                '${_grouped(hadithCount)} ${S.isUrdu ? 'احادیث' : 'hadith'}',
                style: AppText.listTime.copyWith(
                  fontSize: 13,
                  color: AppColors.emerald,
                ),
              ),
              const SizedBox(height: 1),
              Text(
                volumes > 0 ? '$volumes volumes' : S.chapters,
                style: AppText.caption
                    .copyWith(fontSize: 10.5, color: AppColors.textMuted),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// English/Urdu bar at the top of the Hadith section, replacing what used
/// to be a hidden translate-icon popup menu.
class _LangSegment extends StatelessWidget {
  const _LangSegment({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 3),
        child: Material(
          color: selected ? AppColors.emerald : AppColors.white,
          borderRadius: BorderRadius.circular(8),
          child: InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: onTap,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: selected ? AppColors.emerald : AppColors.goldRule,
                ),
              ),
              padding: const EdgeInsets.symmetric(vertical: 8),
              alignment: Alignment.center,
              child: Text(
                label,
                style: AppText.caption.copyWith(
                  color: selected ? AppColors.white : AppColors.textMuted,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _FooterTile extends StatelessWidget {
  const _FooterTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
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
          padding: const EdgeInsets.symmetric(vertical: 14),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Icon(icon, size: 19, color: AppColors.gold),
              const SizedBox(width: 9),
              Text(
                label,
                style: AppText.rowTitle
                    .copyWith(fontSize: 14.5, color: AppColors.text),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
