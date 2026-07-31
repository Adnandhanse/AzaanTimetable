import 'dart:ui' show LineMetrics;

import 'package:flutter/material.dart';

import '../models/quran.dart';
import '../theme/app_theme.dart';

/// One paginated page: its text, and which verses fall on it.
class _MushafPage {
  const _MushafPage({
    required this.text,
    required this.firstVerse,
    required this.lastVerse,
  });

  final String text;
  final int firstVerse;
  final int lastVerse;
}

/// Arabic-only continuous reading, paginated so a whole number of lines fits
/// each screen and nothing is ever cut in half.
///
/// WHAT THIS IS NOT
///
/// This is not a Madani Mushaf. A real Mushaf page is a fixed typographic
/// object: specific words on specific lines of specific pages, in the Uthmani
/// glyph set, identical in every printed copy. Reproducing it needs a
/// page-and-line layout table plus the QCF font that table was measured
/// against. The bundled quran-json has verse text only.
///
/// That distinction matters — people who memorise do it by page position — so
/// this view paginates to the reader's screen and says so, rather than
/// pretending to be something it is not.
class MushafView extends StatefulWidget {
  const MushafView({
    super.key,
    required this.verses,
    this.fontSize = 26,
    this.targetLines = 15,
    this.onMarkVerse,
    this.markedVerse,
  });

  /// Any run of verses — a whole surah, or the span a juz covers.
  final List<QuranVerse> verses;

  final double fontSize;

  /// Lines per page, if the screen is tall enough. Falls back to whatever
  /// actually fits, so text is never clipped.
  final int targetLines;

  /// Save the reading position from inside this view. Null hides the control —
  /// the Juz screen has no single surah to attribute a verse to.
  final void Function(int verseNumber)? onMarkVerse;

  /// Highlights the control when the saved verse is on the current page.
  final int? markedVerse;

  @override
  State<MushafView> createState() => _MushafViewState();
}

class _MushafViewState extends State<MushafView> {
  final PageController _controller = PageController();
  int _page = 0;

  // Pagination is cached: recomputing it on every rebuild would re-lay-out the
  // whole surah each time the reader turns a page.
  List<_MushafPage>? _pages;
  double? _cachedWidth;
  int? _cachedLines;
  int? _cachedVerseCount;

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

  /// The whole run as one flowing string, plus the character offset each verse
  /// starts at. The offsets are what let a page report which verses it holds —
  /// without them, marking a position from this view would be impossible.
  (String, List<int>) _flow() {
    final StringBuffer b = StringBuffer();
    final List<int> starts = <int>[];
    for (final QuranVerse v in widget.verses) {
      starts.add(b.length);
      b.write(v.arabicText.trim());
      b.write(' \u06DD');
      b.write(_arabicDigits(v.number));
      b.write('  ');
    }
    return (b.toString(), starts);
  }

  /// Index of the verse containing character [charOffset].
  int _verseIndexAt(List<int> starts, int charOffset) {
    int lo = 0;
    int hi = starts.length - 1;
    int best = 0;
    while (lo <= hi) {
      final int mid = (lo + hi) ~/ 2;
      if (starts[mid] <= charOffset) {
        best = mid;
        lo = mid + 1;
      } else {
        hi = mid - 1;
      }
    }
    return best;
  }

  /// Lays the full text out ONCE and reads its line metrics. Re-laying-out the
  /// remainder for every page is quadratic and visibly janky on Al-Baqarah's
  /// 286 verses.
  List<_MushafPage> _paginate({
    required TextStyle style,
    required double maxWidth,
    required int linesPerPage,
  }) {
    final (String text, List<int> starts) = _flow();

    final TextPainter tp = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.rtl,
      textAlign: TextAlign.justify,
    )..layout(maxWidth: maxWidth);

    final List<LineMetrics> lines = tp.computeLineMetrics();
    final List<int> breaks = <int>[0];

    for (int first = linesPerPage; first < lines.length; first += linesPerPage) {
      // A point just inside the first line of the next page. RTL, so lines
      // begin at the right edge.
      final double y = lines[first].baseline - lines[first].ascent + 2;
      final int at =
          tp.getPositionForOffset(Offset(maxWidth - 1, y)).offset;
      if (at > breaks.last) breaks.add(at);
    }
    breaks.add(text.length);

    final List<_MushafPage> pages = <_MushafPage>[];
    for (int i = 0; i < breaks.length - 1; i++) {
      final int from = breaks[i];
      final int to = breaks[i + 1];
      if (to <= from) continue;
      final int firstIdx = _verseIndexAt(starts, from);
      final int lastIdx = _verseIndexAt(starts, to - 1);
      pages.add(_MushafPage(
        text: text.substring(from, to).trim(),
        firstVerse: widget.verses[firstIdx].number,
        lastVerse: widget.verses[lastIdx].number,
      ));
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
        final double maxWidth = c.maxWidth - hPad * 2 - 28; // 28 = card margins
        final double maxHeight = c.maxHeight - vPad * 2 - 46; // 46 = footer bar

        final double lineHeight = widget.fontSize * 2.05;
        // Never promise more lines than fit, or the last one clips.
        final int linesPerPage =
            (maxHeight / lineHeight).floor().clamp(6, widget.targetLines);

        if (_pages == null ||
            _cachedWidth != maxWidth ||
            _cachedLines != linesPerPage ||
            _cachedVerseCount != widget.verses.length) {
          _pages = _paginate(
            style: style,
            maxWidth: maxWidth,
            linesPerPage: linesPerPage,
          );
          _cachedWidth = maxWidth;
          _cachedLines = linesPerPage;
          _cachedVerseCount = widget.verses.length;
        }

        final List<_MushafPage> pages = _pages!;
        if (pages.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }
        final int safePage = _page.clamp(0, pages.length - 1);
        final _MushafPage current = pages[safePage];
        final bool markedHere = widget.markedVerse != null &&
            widget.markedVerse! >= current.firstVerse &&
            widget.markedVerse! <= current.lastVerse;

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
                  margin: const EdgeInsets.fromLTRB(14, 10, 14, 4),
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
                      pages[i].text,
                      textAlign: TextAlign.justify,
                      style: style,
                    ),
                  ),
                ),
              ),
            ),

            // Footer: where you are, and the control to save it. Marking from
            // here is the whole point — in Arabic-only mode there are no verse
            // rows to put a bookmark icon on.
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 2, 8, 8),
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: Text(
                      'Page ${safePage + 1} of ${pages.length}'
                      '   \u00b7   Ayah ${current.firstVerse}\u2013${current.lastVerse}'
                      '   \u00b7   $linesPerPage lines',
                      style:
                          AppText.caption.copyWith(color: AppColors.textMuted),
                    ),
                  ),
                  if (widget.onMarkVerse != null)
                    TextButton.icon(
                      onPressed: () =>
                          widget.onMarkVerse!(current.firstVerse),
                      icon: Icon(
                        markedHere ? Icons.bookmark : Icons.bookmark_border,
                        size: 18,
                        color: markedHere
                            ? AppColors.emerald
                            : AppColors.textMuted,
                      ),
                      label: Text(
                        markedHere ? 'Saved' : 'Save page',
                        style: AppText.caption.copyWith(
                          color: markedHere
                              ? AppColors.emerald
                              : AppColors.textMuted,
                        ),
                      ),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}
