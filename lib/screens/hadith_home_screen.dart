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
              childAspectRatio: 0.74,
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

  /// A distinct spine colour per book, so the six are recognisable at a glance
  /// rather than being six identical white rectangles with different words on
  /// them. Muted, drawn from the palette — this is a bookshelf, not a toy.
  /// A distinct spine per book, drawn ONLY from the app's own palette.
  ///
  /// The first version used blue, brown, purple and red to separate the six.
  /// They were distinguishable and completely wrong — introducing four hues the
  /// app does not use anywhere else, so the shelf looked like it belonged to a
  /// different application.
  ///
  /// These are all emerald, gold or charcoal, varied by DEPTH rather than hue:
  /// deep green through to pale sage, then champagne, then charcoal. Six shades
  /// of the same family still tell six books apart — a bookshelf of matched
  /// bindings is how a good set of volumes actually looks.
  static const List<Color> _spines = <Color>[
    Color(0xFF0A4229), // Bukhari    deepest emerald
    Color(0xFF0F5E3A), // Muslim     primary emerald
    Color(0xFF2C6653), // Abu Dawud  mid emerald
    Color(0xFF4E7C63), // Tirmidhi   sage
    Color(0xFFA8842A), // Nasa'i     deep champagne
    Color(0xFF3A3A38), // Ibn Majah  charcoal
  ];

  @override
  Widget build(BuildContext context) {
    final Color spine = _spines[(number - 1) % _spines.length];

    return Material(
      color: AppColors.white,
      borderRadius: BorderRadius.circular(10),
      elevation: 0,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.goldRule),
            // The book's own colour bleeding up from the base, so each card
            // carries some of its spine.
            gradient: LinearGradient(
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
              colors: <Color>[
                spine.withOpacity(0.10),
                AppColors.white,
              ],
              stops: const <double>[0.0, 0.55],
            ),
          ),
          child: Column(
            children: <Widget>[
              // A SPINE ACROSS THE TOP, the way a book faces you on a shelf.
              // Sixteen pixels of colour does more to distinguish six volumes
              // than any amount of text styling.
              Container(
                height: 6,
                decoration: BoxDecoration(
                  color: spine,
                  borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(9)),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(10, 12, 10, 10),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      // An open book with the volume number on it, rather than a
                      // bare numbered medallion.
                      SizedBox(
                        width: 46,
                        height: 46,
                        child: Stack(
                          alignment: Alignment.center,
                          children: <Widget>[
                            Icon(Icons.menu_book_rounded,
                                size: 42, color: spine.withOpacity(0.16)),
                            Container(
                              width: 22,
                              height: 22,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: spine,
                              ),
                              child: Text(
                                '$number',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                      if (arabicName.isNotEmpty) ...[
                        Text(
                          arabicName,
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppText.arabic.copyWith(
                            fontSize: 17,
                            height: 1.3,
                            color: spine,
                          ),
                        ),
                        const SizedBox(height: 3),
                      ],
                      Text(
                        name,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppText.rowTitle.copyWith(
                            fontSize: 13.5, color: AppColors.text),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: spine.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          volumes > 0 ? '$volumes vol' : S.chapters,
                          style: AppText.caption
                              .copyWith(fontSize: 10.5, color: spine),
                        ),
                      ),
                    ],
                  ),
                ),
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
