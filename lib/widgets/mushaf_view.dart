import 'dart:math' as math;
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
    required this.firstIndex,
    required this.lastIndex,
  });

  final String text;
  final int firstVerse;
  final int lastVerse;
  final int firstIndex;
  final int lastIndex;
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
/// That distinction matters - people who memorise do it by page position - so
/// this view paginates to the reader's screen and says so, rather than
/// pretending to be something it is not.
=======
/// This is a screen-sized reading layout, not a fixed Madani Mushaf layout.
/// A fixed Mushaf requires a page/line layout table measured against the exact
/// Quran font being used.
>>>>>>> f43955a16b7db842e16035b985eeafda9a75b278
class MushafView extends StatefulWidget {
  const MushafView({
    super.key,
    required this.verses,
    this.fontSize = 26,
    this.targetLines = 15,
    this.onMarkIndex,
    this.markedIndex,
    this.initialVerseIndex,
    this.sajdahIndices = const <int>{},
  });

  /// Any run of verses - a whole surah, or the span a juz covers.
=======
>>>>>>> f43955a16b7db842e16035b985eeafda9a75b278
  final List<QuranVerse> verses;
  final double fontSize;
  final int targetLines;

  /// Save the reading position. Receives the INDEX of the first verse on the
  /// current page, not its number - across a juz the same verse number occurs
  /// in several surahs, so an index is the only unambiguous handle. The parent
  /// resolves it to whatever it needs to store.
  final void Function(int firstVerseIndexOnPage)? onMarkIndex;
  final int? markedIndex;
  final int? initialVerseIndex;
  /// Indices of verses at which a sajdah is marked.
  ///
  /// INDICES, not verse numbers - a juz spans several surahs, so ayah 15 is
  /// ambiguous, exactly as it was for the bookmark.
  ///
  /// The parent works these out because it knows which surah each verse belongs
  /// to; this widget only ever sees a flat list of verses.
=======
  final void Function(int firstVerseIndexOnPage)? onMarkIndex;
  final int? markedIndex;
  final int? initialVerseIndex;
>>>>>>> f43955a16b7db842e16035b985eeafda9a75b278
  final Set<int> sajdahIndices;

  @override
  State<MushafView> createState() => _MushafViewState();
}

class _MushafViewState extends State<MushafView> {
  final PageController _controller = PageController();
  int _page = 0;

  List<_MushafPage>? _pages;

  bool _jumpedToInitial = false;
  double? _cachedWidth;
  int? _cachedLines;
  int? _cachedVerseCount;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  static String _arabicDigits(int n) {
    const List<String> digits = <String>[
      '\u0660',
      '\u0661',
      '\u0662',
      '\u0663',
      '\u0664',
      '\u0665',
      '\u0666',
      '\u0667',
      '\u0668',
      '\u0669',
    ];

    return n
        .toString()
        .split('')
        .map((String c) => digits[int.parse(c)])
        .join();
  }

  /// The whole run as one flowing string, plus the character offset each verse
  /// starts at. The offsets are what let a page report which verses it holds -
  /// without them, marking a position from this view would be impossible.
=======
>>>>>>> f43955a16b7db842e16035b985eeafda9a75b278
  (String, List<int>) _flow() {
    final StringBuffer buffer = StringBuffer();
    final List<int> starts = <int>[];

    for (final QuranVerse verse in widget.verses) {
      starts.add(buffer.length);

      buffer.write(verse.arabicText.trim());
      buffer.write(' \u06DD');
      buffer.write(_arabicDigits(verse.number));
      buffer.write('  ');
    }

    return (buffer.toString(), starts);
  }

  int _verseIndexAt(List<int> starts, int charOffset) {
    int low = 0;
    int high = starts.length - 1;
    int best = 0;

    while (low <= high) {
      final int middle = (low + high) ~/ 2;

      if (starts[middle] <= charOffset) {
        best = middle;
        low = middle + 1;
      } else {
        high = middle - 1;
      }
    }

    return best;
  }

  /// Lays out the entire text once and creates page breaks from the actual
  /// Flutter line metrics.
  ///
  /// The important clipping fix is that pagination now reserves additional
  /// vertical safety space for Arabic ascenders, descenders, tashkeel and
  /// verse-end markers. The page widget also has extra bottom padding.
  List<_MushafPage> _paginate({
    required TextStyle style,
    required double maxWidth,
    required int linesPerPage,
  }) {
    final (String text, List<int> starts) = _flow();

    final TextPainter textPainter = TextPainter(
      text: TextSpan(
        text: text,
        style: style,
      ),
      textDirection: TextDirection.rtl,
      textAlign: TextAlign.justify,
    )..layout(maxWidth: maxWidth);

    final List<LineMetrics> lines = textPainter.computeLineMetrics();

    if (lines.isEmpty) {
      return const <_MushafPage>[];
    }

    final List<int> breaks = <int>[0];

    for (
      int first = linesPerPage;
      first < lines.length;
      first += linesPerPage
    ) {
      // Move into the next line with a small safety offset. This is important
      // for Arabic because tashkeel and Quranic marks can extend beyond the
      // nominal glyph box.
      final double y =
          lines[first].baseline - lines[first].ascent + 6;

      final int offset = textPainter
          .getPositionForOffset(
            Offset(maxWidth - 1, y),
          )
          .offset;

      if (offset > breaks.last) {
        breaks.add(offset);
      }
    }

    breaks.add(text.length);

    final List<_MushafPage> pages = <_MushafPage>[];

    for (int i = 0; i < breaks.length - 1; i++) {
      final int from = breaks[i];
      final int to = breaks[i + 1];

      if (to <= from) {
        continue;
      }

      final int firstIndex = _verseIndexAt(starts, from);
      final int lastIndex = _verseIndexAt(starts, to - 1);

      pages.add(
        _MushafPage(
          text: text.substring(from, to).trim(),
          firstVerse: widget.verses[firstIndex].number,
          lastVerse: widget.verses[lastIndex].number,
          firstIndex: firstIndex,
          lastIndex: lastIndex,
        ),
      );
    }

    return pages;
  }

  @override
  Widget build(BuildContext context) {
    final TextStyle style = AppText.quranAyah.copyWith(
      fontSize: widget.fontSize,
      height: 2.05,
      color: AppColors.text,
    );

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        const double horizontalPagePadding = 22;
        const double verticalPagePadding = 18;
        final double maxWidth = constraints.maxWidth - horizontalPagePadding * 2 - 28;

        // Space outside the actual text card.
        const double pageCardMargins = 14;

        // Top information bar + card margins + extra vertical safety.
        //
<<<<<<< HEAD
        // This was 46, written when the bar was a slim FOOTER holding plain
        // text. Moving it to the top and giving it a Save-page button made it
        // taller, but the reservation was never updated - so pagination
        // believed it had ~8px more room than it did, packed in one line too
        // many, and the bottom of the last line was cut off.
        const double chrome = 40 + 14 + 10;
        final double maxHeight = c.maxHeight - vPad * 2 - chrome;
>>>>>>> 28285bc011b8a609bf03663a3018378fbf233918

        // Space outside the actual text card.
        const double pageCardMargins = 14;

        // Top information bar + card margins + extra vertical safety.
        //
        // The previous implementation underestimated the available-height
        // cost after moving the page information/bookmark bar to the top.
        // That allowed one extra Arabic line to be paginated and its lower
        // marks/descenders could then be clipped.
        const double chrome = 40 + pageCardMargins + 18;

=======
        // The previous implementation underestimated the available-height
        // cost after moving the page information/bookmark bar to the top.
        // That allowed one extra Arabic line to be paginated and its lower
        // marks/descenders could then be clipped.
        const double chrome = 40 + pageCardMargins + 18;

>>>>>>> f43955a16b7db842e16035b985eeafda9a75b278
        final double maxWidth = constraints.maxWidth -
            horizontalPagePadding * 2 -
            28;

        final double maxHeight = constraints.maxHeight -
            verticalPagePadding * 2 -
            chrome;

        // The actual line height used by the Text widget is based on the
        // font's metrics. Add a small safety allowance so the last line has
        // room for Arabic marks and verse-end symbols.
        final double lineHeight =
            widget.fontSize * 2.05 + 3;

        final int linesPerPage = (maxHeight / lineHeight)
            .floor()
            .clamp(6, widget.targetLines);

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
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        // This was 46, written when the bar was a slim FOOTER holding plain
        // text. Moving it to the top and giving it a Save-page button made it
        // taller, but the reservation was never updated - so pagination
        // believed it had ~8px more room than it did, packed in one line too
        // many, and the bottom of the last line was cut off.
        const double chrome = 40 + pageCardMargins + 18;
        final double maxHeight = constraints.maxHeight - verticalPagePadding * 2 - chrome;
=======
        // Resume once, after pagination exists.
>>>>>>> f43955a16b7db842e16035b985eeafda9a75b278
        final int? resumeAt = widget.initialVerseIndex;

        if (!_jumpedToInitial && resumeAt != null) {
          _jumpedToInitial = true;

          for (int i = 0; i < pages.length; i++) {
            if (resumeAt >= pages[i].firstIndex &&
                resumeAt <= pages[i].lastIndex) {
              if (i != 0) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted && _controller.hasClients) {
                    _controller.jumpToPage(i);
                    setState(() {
                      _page = i;
                    });
                  }
                });
              }
              break;
            }
          }
        }

        final int safePage =
            _page.clamp(0, pages.length - 1);

        final _MushafPage current = pages[safePage];

        final bool markedHere =
            widget.markedIndex != null &&
            widget.markedIndex! >= current.firstIndex &&
            widget.markedIndex! <= current.lastIndex;

        return Column(
          children: <Widget>[
        // Resume: land on the page holding the saved verse. Done once, after
        // pagination exists - page numbers are meaningless before that, and
        // repeating it would fight the reader every time they turn a page.
=======
>>>>>>> f43955a16b7db842e16035b985eeafda9a75b278
            Padding(
              padding: const EdgeInsets.fromLTRB(
                18,
                6,
                8,
                2,
              ),
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: Text(
                      'Page ${safePage + 1} of ${pages.length}'
                      '   \u00B7   Ayah ${current.firstVerse}\u2013${current.lastVerse}'
                      '   \u00B7   $linesPerPage lines',
                      style: AppText.caption.copyWith(
                        color: AppColors.textMuted,
                      ),
                    ),
                  ),
                  if (widget.onMarkIndex != null)
                    TextButton.icon(
                      onPressed: () {
                        widget.onMarkIndex!(
                          current.firstIndex,
                        );
                      },
                      icon: Icon(
                        markedHere
                            ? Icons.bookmark
                            : Icons.bookmark_border,
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
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                        ),
                        minimumSize: Size.zero,
                        tapTargetSize:
                            MaterialTapTargetSize.shrinkWrap,
                      ),
                    ),
                ],
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _controller,
                reverse: true,
                itemCount: pages.length,
                onPageChanged: (int index) {
                  setState(() {
                    _page = index;
                  });
                },
                itemBuilder: (
                  BuildContext context,
                  int index,
                ) {
                  final Widget page = Container(
                    margin: const EdgeInsets.fromLTRB(
                      14,
                      10,
                      14,
                      4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                        color: AppColors.goldRule,
                      ),
                    ),

                    // Extra bottom padding is deliberate. It prevents
                    // Arabic descenders/tashkeel on the final visible line
                    // from touching or crossing the card's bottom edge.
                    padding: const EdgeInsets.fromLTRB(
                      horizontalPagePadding,
                      verticalPagePadding,
                      horizontalPagePadding,
                      verticalPagePadding + 8,
                    ),

                    child: Directionality(
                      textDirection: TextDirection.rtl,
                      child: Text(
                        pages[index].text,
                        textAlign: TextAlign.justify,
                        softWrap: true,
                        style: style,
                      ),
                    ),
                  );

                  return _PageTurn(
                    controller: _controller,
                    index: index,
                    child: page,
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}

/// Makes a page swing on its spine instead of sliding.
///
            // AT THE TOP, not the bottom.
            //
            // Page number and the bookmark used to sit under the text. On a
            // full page of Arabic that put the control below the fold - you had
            // to read to the end before you could see where you were or save
            // your place. Both belong where the eye starts.
            //
            // No divider under it: the page itself is a bordered card, so a
            // rule between them was a second line doing the same job.
=======
/// This is a hinge-style page turn rather than a true paper curl. A true curl
/// would require mesh deformation / shader rendering.
>>>>>>> f43955a16b7db842e16035b985eeafda9a75b278
class _PageTurn extends StatelessWidget {
  const _PageTurn({
    required this.controller,
    required this.index,
    required this.child,
  });

  final PageController controller;
  final int index;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (BuildContext context, Widget? _) {
        double delta = 0;

        if (controller.hasClients &&
            controller.position.haveDimensions &&
            controller.page != null) {
          delta = controller.page! - index;
        }

        final double t =
            delta.clamp(-1.0, 1.0);

        final Alignment hinge = t >= 0
            ? Alignment.centerLeft
            : Alignment.centerRight;

        final Matrix4 transform = Matrix4.identity()
          ..setEntry(3, 2, 0.0016)
          ..rotateY(t * math.pi * 0.5);

        final double shade =
            (t.abs() * 0.45).clamp(0.0, 0.45);

        return Transform(
          alignment: hinge,
          transform: transform,
          child: Stack(
            fit: StackFit.passthrough,
            children: <Widget>[
              child,
              if (shade > 0.001)
                Positioned.fill(
                  child: IgnorePointer(
                    child: Container(
                      margin: const EdgeInsets.fromLTRB(
                        14,
                        10,
                        14,
                        4,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(4),
                        gradient: LinearGradient(
                          begin: t >= 0
                              ? Alignment.centerLeft
                              : Alignment.centerRight,
                          end: t >= 0
                              ? Alignment.centerRight
                              : Alignment.centerLeft,
                          colors: <Color>[
                            Colors.black.withOpacity(shade),
                            Colors.black.withOpacity(
                              shade * 0.15,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
