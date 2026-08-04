import 'package:flutter/material.dart';
import '../models/hadith.dart';
import '../services/app_strings.dart';
import '../services/quran_local_data_service.dart';
import '../theme/app_theme.dart';
import '../widgets/ornaments.dart';
import 'hadith_chapters_screen.dart';
import 'hadith_bookmarks_screen.dart';

/// Arabic titles and volume counts, keyed off the existing enum. Kept here
/// rather than added to the model so nothing in the data layer changes.
const Map<HadithBook, (String, int)> _bookMeta = <HadithBook, (String, int)>{
  HadithBook.bukhari: ('صحيح البخاري', 9),
  HadithBook.muslim: ('صحيح مسلم', 7),
  HadithBook.abudawud: ('سنن أبي داود', 4),
  HadithBook.tirmidhi: ('جامع الترمذي', 6),
  HadithBook.nasai: ('سنن النسائي', 6),
  HadithBook.ibnmajah: ('سنن ابن ماجه', 5),
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
    final urdu = await QuranLocalDataService.getHadithUrdu();
    if (!mounted) return;
    setState(() => _language = urdu ? HadithLanguage.urdu : HadithLanguage.english);
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
        actions: [
          IconButton(
            icon: const Icon(Icons.bookmark_border, size: 20),
            tooltip: S.myBookmarks,
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const HadithBookmarksScreen()),
            ),
          ),
          PopupMenuButton<HadithLanguage>(
            icon: const Icon(Icons.translate, size: 20),
            onSelected: _setLanguage,
            itemBuilder: (_) => const [
              PopupMenuItem(value: HadithLanguage.english, child: Text('English')),
              PopupMenuItem(value: HadithLanguage.urdu, child: Text('اردو (Urdu)')),
            ],
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        children: [
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
              // Taller than it looks like it needs to be. At 0.80 the Arabic
              // title and the volume count were being clipped off the bottom
              // of the card on narrower phones — the content is medallion +
              // two lines of name + Arabic + rule + count, and it does not fit
              // in a shorter box.
              childAspectRatio: 0.70,
            ),
            itemBuilder: (context, index) {
              final book = HadithBook.values[index];
              final meta = _bookMeta[book];
              return _BookCard(
                number: index + 1,
                name: book.localName,
                arabicName: meta?.$1 ?? '',
                volumes: meta?.$2 ?? 0,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) =>
                        HadithChaptersScreen(book: book, language: _language),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: _FooterTile(
                  icon: Icons.bookmark_border,
                  label: S.myBookmarks,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
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
    required this.onTap,
  });

  final int number;
  final String name;
  final String arabicName;
  final int volumes;
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
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Medallion(label: '$number', size: 38, filled: true),
              const SizedBox(height: 12),
              Text(
                name,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppText.rowTitle.copyWith(color: AppColors.text),
              ),
              if (arabicName.isNotEmpty) ...[
                const SizedBox(height: 4),
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
              Text(
                volumes > 0 ? '$volumes volumes' : S.chapters,
                style: AppText.caption.copyWith(color: AppColors.textMuted),
              ),
            ],
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
          padding: const EdgeInsets.symmetric(vertical: 13),
          child: Column(
            children: [
              Icon(icon, size: 19, color: AppColors.gold),
              const SizedBox(height: 5),
              Text(
                label,
                style:
                    AppText.rowTitle.copyWith(fontSize: 15, color: AppColors.text),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
