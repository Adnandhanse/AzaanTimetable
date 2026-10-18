import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../models/hadith.dart';
import '../services/app_strings.dart';
import '../services/quran_local_data_service.dart';
import '../theme/app_theme.dart';
import 'hadith_grade_sections_screen.dart';
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

  String _query = '';

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
    final books = HadithBook.values.where((book) {
      final query = _query.trim().toLowerCase();
      return '${book.displayName} ${book.urduName} ${_bookMeta[book]?.$1 ?? ''}'
          .toLowerCase().contains(query);
    }).toList();
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: dark ? const Color(0xFF14221E) : const Color(0xFFFCFAF6),
      appBar: AppBar(
        title: Text(S.hadithBooks,
            style: const TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w700)),
        centerTitle: true,
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
          Text(
            S.isUrdu ? 'پڑھیے اور غور کیجیے' : 'Read and reflect',
            textAlign: TextAlign.center,
            style: TextStyle(fontFamily: 'Inter', fontSize: 14,
                color: dark ? Colors.white70 : const Color(0xFF80796E)),
          ),
          const SizedBox(height: 20),
          TextField(
            onChanged: (value) => setState(() => _query = value),
            style: const TextStyle(fontFamily: 'Inter'),
            decoration: InputDecoration(
              hintText: S.isUrdu ? 'کتاب تلاش کریں' : 'Search books',
              prefixIcon: const Icon(Icons.search_rounded),
              filled: true,
              fillColor: dark ? const Color(0xFF20332B) : Colors.white,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: Color(0xFFE8E3D9))),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: Color(0xFFE8E3D9))),
            ),
          ),
          const SizedBox(height: 24),
          Text(S.sixAuthenticBooks,
              style: const TextStyle(fontFamily: 'Inter', fontSize: 18,
                  fontWeight: FontWeight.w700)),
          const SizedBox(height: 16),
          if (books.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 40),
              child: Text(S.isUrdu ? 'کوئی کتاب نہیں ملی' : 'No books found',
                  textAlign: TextAlign.center),
            ),
          LayoutBuilder(builder: (context, constraints) {
            // Keep readable, natural-height cards even with large system text.
            final columns = constraints.maxWidth < 280 ? 1 : 2;
            final width = (constraints.maxWidth - (columns - 1) * 16) / columns;
            return Wrap(
              spacing: 16,
              runSpacing: 18,
              children: books.map((book) => SizedBox(
                width: width,
                child: _BookCard(
                  book: book,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(builder: (_) =>
                        HadithGradeSectionsScreen(book: book, language: _language)),
                  ),
                ),
              )).toList(),
            );
          }),
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

// Covers are vector artwork: no image downloads or new pubspec assets.
const _coverColours = <Color>[
  Color(0xFFDCE6CE), Color(0xFFD5E4F2), Color(0xFFF6DDCD),
  Color(0xFFE5DCF1), Color(0xFFF8EBBD), Color(0xFFF2D8D9),
];
const _coverInk = <Color>[
  Color(0xFF34583E), Color(0xFF335977), Color(0xFF985C43),
  Color(0xFF665080), Color(0xFF846229), Color(0xFF8F4D51),
];

class _BookCard extends StatelessWidget {
  const _BookCard({required this.book, required this.onTap});
  final HadithBook book;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final index = book.index;
    final meta = _bookMeta[book]!;
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Semantics(
      button: true,
      label: book.localName,
      child: Material(
        color: dark ? const Color(0xFF20332B) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 16, 12, 16),
            child: Column(children: [
              ExcludeSemantics(
                child: AspectRatio(
                  aspectRatio: 0.72,
                  child: Container(
                    margin: const EdgeInsets.fromLTRB(3, 0, 3, 8),
                    decoration: BoxDecoration(
                      color: _coverColours[index],
                      borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(9), bottomLeft: Radius.circular(9),
                          topRight: Radius.circular(3), bottomRight: Radius.circular(3)),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.12),
                          offset: const Offset(0, 7), blurRadius: 10)],
                    ),
                    child: CustomPaint(
                      painter: _CoverOrnament(_coverInk[index]),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(24, 25, 14, 25),
                        child: Column(mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(meta.$1, textAlign: TextAlign.center,
                              textScaler: TextScaler.noScaling,
                              style: TextStyle(fontFamily: 'Amiri', fontSize: 17,
                                  height: 1.5, color: _coverInk[index])),
                            const SizedBox(height: 12),
                            Text(book.displayName, textAlign: TextAlign.center,
                              textScaler: TextScaler.noScaling,
                              style: TextStyle(fontFamily: 'Amiri', fontSize: 20,
                                  height: 1.15, fontWeight: FontWeight.w700,
                                  color: _coverInk[index])),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(book.localName, textAlign: TextAlign.center,
                style: TextStyle(fontFamily: S.isUrdu ? 'Amiri' : 'Inter',
                    fontSize: 14, height: 1.4, fontWeight: FontWeight.w600,
                    color: dark ? Colors.white : const Color(0xFF213B37))),
              const SizedBox(height: 8),
              Text(S.isUrdu ? 'کتاب پڑھیں ←' : 'Read book →',
                textAlign: TextAlign.center,
                style: TextStyle(fontFamily: S.isUrdu ? 'Amiri' : 'Inter',
                    fontSize: 13, fontWeight: FontWeight.w600,
                    color: dark ? const Color(0xFFABD1BB) : const Color(0xFF47755E))),
              const SizedBox(height: 6),
              Text('${meta.$3.toString().replaceAllMapped(RegExp(r"(\d)(?=(\d{3})+$)"), (m) => "${m[1]},")} ${S.isUrdu ? 'احادیث' : 'hadith'}',
                textAlign: TextAlign.center,
                style: TextStyle(fontFamily: 'Inter', fontSize: 10,
                    color: dark ? Colors.white60 : const Color(0xFF7A8079))),
            ]),
          ),
        ),
      ),
    );
  }
}

class _CoverOrnament extends CustomPainter {
  const _CoverOrnament(this.ink);
  final Color ink;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final gold = Paint()..color = const Color(0xFFB79D63)
      ..style = PaintingStyle.stroke..strokeWidth = 0.8;
    // Rounded spine with a softly highlighted edge.
    canvas.drawRect(Rect.fromLTWH(0, 0, 10, h),
        Paint()..color = ink.withOpacity(0.12));
    canvas.drawLine(Offset(11, 2), Offset(11, h - 2),
        Paint()..color = Colors.white.withOpacity(0.7)..strokeWidth = 1.2);
    for (final inset in [18.0, 22.0]) {
      canvas.drawRRect(RRect.fromRectAndRadius(
        Rect.fromLTRB(inset, 12 + inset - 18, w - inset + 8, h - 12 - inset + 18),
        const Radius.circular(2)), gold);
    }
    // Small geometric rosettes leave the title area unobstructed.
    for (final x in [30.0, w - 22]) {
      for (final y in [29.0, h - 29]) {
        for (var petal = 0; petal < 4; petal++) {
          canvas.save();
          canvas.translate(x, y);
          canvas.rotate(petal * math.pi / 2);
          canvas.drawOval(const Rect.fromLTWH(-2.5, -11, 5, 10), gold);
          canvas.restore();
        }
      }
    }
    for (final y in [h * 0.21, h * 0.79]) {
      final x = w / 2 + 4;
      final path = Path()..moveTo(x, y - 5)..lineTo(x + 4, y)
        ..lineTo(x, y + 5)..lineTo(x - 4, y)..close();
      canvas.drawPath(path, gold);
    }
    for (final y in [h * 0.16, h * 0.84]) {
      canvas.drawLine(Offset(1, y), Offset(9, y), gold);
      canvas.drawLine(Offset(1, y + 3), Offset(9, y + 3), gold);
    }
  }

  @override
  bool shouldRepaint(covariant _CoverOrnament oldDelegate) => oldDelegate.ink != ink;
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
