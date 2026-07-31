import 'dart:ui' show LineMetrics;

import 'package:flutter/material.dart';

import '../models/quran.dart';
import '../theme/app_theme.dart';

/// Arabic-only continuous reading, paginated so a whole number of lines fits
/// each screen and nothing is ever cut in half.
///
/// WHAT THIS IS NOT
///
/// This is not a Madani Mushaf. A real Mushaf page is a fixed typographic
/// object: specific words on specific lines of specific pages, in the Uthmani
/// glyph set, identical in every printed copy. Reproducing it needs two things
/// this app does not have — a page-and-line layout table mapping every word to
/// its position, and the QCF/Uthmani font that table is measured against. The
/// bundled quran-json has verse text only.
///
/// That distinction matters: people who memorise do it by page position, and a
/// view that looks like a Mushaf but breaks lines somewhere else is worse than
/// one that plainly does not pretend. So this flows the text continuously and
/// paginates it to the reader's screen. Line and page breaks will not match a
/// printed Mushaf, and the view does not claim to.
///
/// If you want the real thing later, it needs a licensed Madani layout dataset
/// plus the matching fonts — a data problem, not a UI one.
class MushafView extends StatefulWidget {
  const MushafView({
    super.key,
    required this.surah,
    this.fontSize = 26,
    this.targetLines = 15,
  });

  final Surah surah;

  /// Arabic reading size. Larger than the translation view on purpose — this
  /// mode exists to be read from the Arabic alone.
  final double fontSize;

  /// Lines per page, if the screen is tall enough. Falls back to whatever
  /// actually fits, so text is never clipped.
  final int targetLines;

  @override
  State<MushafView> createState() => _MushafViewState();
}

class _MushafViewState extends State<MushafView> {
  final PageController _controller = PageController();
  int _page = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Western digits to Arabic-Indic, for the verse-end markers.
  static String _arabicDigits(int n) {
    const List<String> d = <String>[
      '\u0660', '\u0661', '\u0662', '\u0663', '\u0664',
      '\u0665', '\u0666', '\u0667', '\u0668', '\u0669',
    ];
    return n.toString().split('').map((String c) => d[int.parse(c)]).join();
  }

  /// The whole surah as one flowing string, each verse closed by the end-of-ayah
  /// mark with its number.
  String _flowText() {
    final StringBuffer b = StringBuffer();
    for (final QuranVerse v in widget.surah.verses) {
      b.write(v.arabicText.trim());
      b.write(' \u06DD');
      b.write(_arabicDigits(v.number));
      b.write('  ');
    }
    return b.toString().trim();
  }

  /// Split [text] so each page holds exactly [linesPerPage] rendered lines.
  ///
  /// Lays the full text out ONCE and reads its line metrics, rather than
  /// re-laying-out the remainder for every page. Al-Baqarah is 286 verses; the
  /// naive repeated-layout approach is quadratic and visibly janky on it.
  List<String> _paginate({
    required String text,
    required TextStyle style,
    required double maxWidth,
    required int linesPerPage,
  }) {
    final TextPainter tp = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.rtl,
      textAlign: TextAlign.justify,
    )..layout(maxWidth: maxWidth);

    final List<LineMetrics> lines = tp.computeLineMetrics();
    if (lines.length <= linesPerPage) return <String>[text];

    final List<String> pages = <String>[];
    int startChar = 0;

    for (int first = linesPerPage; first < lines.length; first += linesPerPage) {
      // A point just inside the first line of the next page. RTL, so lines
      // start at the right edge.
      final double y = lines[first].baseline - lines[first].ascent + 2;
      final int breakAt = tp
          .getPositionForOffset(Offset(maxWidth - 1, y))
          .offset;
      if (breakAt <= startChar) continue; // degenerate, keep going
      pages.add(text.substring(startChar, breakAt).trim());
      startChar = breakAt;
    }
    if (startChar < text.length) {
      pages.add(text.substring(startChar).trim());
    }
    return pages;
  }

  @override
  Widget build(BuildContext context) {
    final TextStyle style = AppText.arabicVerse.copyWith(
      fontSize: widget.fontSize,
      height: 2.05,
      color: AppColors.text,
    );

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints c) {
        const double hPad = 22;
        const double vPad = 18;
        final double maxWidth = c.maxWidth - hPad * 2;
        final double maxHeight = c.maxHeight - vPad * 2 - 34; // 34 = page footer

        final double lineHeight = widget.fontSize * 2.05;
        // Never promise more lines than actually fit, or the last one clips.
        final int fits = (maxHeight / lineHeight).floor();
        final int linesPerPage = fits.clamp(6, widget.targetLines);

        final List<String> pages = _paginate(
          text: _flowText(),
          style: style,
          maxWidth: maxWidth,
          linesPerPage: linesPerPage,
        );

        return Column(
          children: <Widget>[
            Expanded(
              child: PageView.builder(
                controller: _controller,
                // Right to left, the way a Mushaf is turned.
                reverse: true,
                itemCount: pages.length,
                onPageChanged: (int i) => setState(() => _page = i),
                itemBuilder: (BuildContext context, int i) => Container(
                  margin: const EdgeInsets.fromLTRB(14, 10, 14, 6),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: AppColors.goldRule),
                  ),
                  padding: const EdgeInsets.symmetric(
                      horizontal: hPad, vertical: vPad),
                  child: Directionality(
                    textDirection: TextDirection.rtl,
                    child: Text(
                      pages[i],
                      textAlign: TextAlign.justify,
                      style: style,
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 10, top: 2),
              child: Text(
                'Page ${_page + 1} of ${pages.length}   \u00b7   $linesPerPage lines',
                style: AppText.caption.copyWith(color: AppColors.textMuted),
              ),
            ),
          ],
        );
      },
    );
  }
}
