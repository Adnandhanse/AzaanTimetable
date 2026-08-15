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
  final List<QuranVerse> verses;

  final double fontSize;

  /// Lines per page, if the screen is tall enough. Falls back to whatever
  /// actually fits, so text is never clipped.
  final int targetLines;

  /// Save the reading position. Receives the INDEX of the first verse on the
  /// current page, not its number - across a juz the same verse number occurs
  /// in several surahs, so an index is the only unambiguous handle. The parent
  /// resolves it to whatever it needs to store.
  final void Function(int firstVerseIndexOnPage)? onMarkIndex;

  /// Index of the saved verse, so the control can show it is already saved.
  final int? markedIndex;

  /// Open on the page holding this verse, for resuming.
  final int? initialVerseIndex;

  /// Indices of verses at which a sajdah is marked.
  ///
  /// INDICES, not verse numbers - a juz spans several surahs, so ayah 15 is
  /// ambiguous, exactly as it was for the bookmark.
  ///
  /// The parent works these out because it knows which surah each verse belongs
  /// to; this widget only ever sees a flat list of verses.
  final Set<int> sajdahIndices;

  @override
  State<MushafView> createState() => _MushafViewState();
}

class _MushafViewState extends State<MushafView> {
  final PageController _controller = PageController();
  int _page = 0;

  // Pagination is cached: recomputing it on every rebuild would re-lay-out the
  // whole surah each time the reader turns a page.
  List<_MushafPage>? _pages;

  /// Sajdah indices falling on page [i].
  List<int> _sajdahOnPage(int i) {
    final pages = _pages;
    if (pages == null || i >= pages.length) return const <int>[];
    final p = pages[i];
    return widget.sajdahIndices
        .where((x) => x >= p.firstIndex && x <= p.lastIndex)
        .toList()
      ..sort();
  }
  bool _jumpedToInitial = false;
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
  /// starts at. The offsets are what let a page report which verses it holds -
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
        firstIndex: firstIdx,
        lastIndex: lastIdx,
      ));
    }
    return pages;
  }

  @override
  Widget build(BuildContext context) {
    // THE MUSHAF FACE, not the general Arabic one. This is Qur'an, and it
    // should look like the printed Mushaf people already read from.
    final TextStyle style = AppText.quranAyah.copyWith(
      fontSize: widget.fontSize,
      height: 2.05,
      color: AppColors.text,
    );

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints c) {
        const double hPad = 22;
        const double vPad = 18;
        final double maxWidth = c.maxWidth - hPad * 2 - 28; // 28 = card margins

        // Vertical chrome above and around the page, measured rather than
        // guessed:
        //   40  the top bar (6 + 2 padding, plus a ~32 TextButton.icon)
        //   14  the page card's own margins (10 top, 4 bottom)
        //   10  headroom, so a descender on the last line cannot clip
        //
        // This was 46, written when the bar was a slim FOOTER holding plain
        // text. Moving it to the top and giving it a Save-page button made it
        // taller, but the reservation was never updated - so pagination
        // believed it had ~8px more room than it did, packed in one line too
        // many, and the bottom of the last line was cut off.
        const double chrome = 40 + 14 + 10;
        final double maxHeight = c.maxHeight - vPad * 2 - chrome;

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

        // Resume: land on the page holding the saved verse. Done once, after
        // pagination exists - page numbers are meaningless before that, and
        // repeating it would fight the reader every time they turn a page.
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
                    setState(() => _page = i);
                  }
                });
              }
              break;
            }
          }
        }
        final int safePage = _page.clamp(0, pages.length - 1);
        final _MushafPage current = pages[safePage];
        final bool markedHere = widget.markedIndex != null &&
            widget.markedIndex! >= current.firstIndex &&
            widget.markedIndex! <= current.lastIndex;

        return Column(
          children: <Widget>[
            // AT THE TOP, not the bottom.
            //
            // Page number and the bookmark used to sit under the text. On a
            // full page of Arabic that put the control below the fold - you had
            // to read to the end before you could see where you were or save
            // your place. Both belong where the eye starts.
            //
            // No divider under it: the page itself is a bordered card, so a
            // rule between them was a second line doing the same job.
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 6, 8, 2),
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
                  if (widget.onMarkIndex != null)
                    TextButton.icon(
                      onPressed: () => widget.onMarkIndex!(current.firstIndex),
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
            Expanded(
              child: PageView.builder(
                controller: _controller,
                // Right to left, the way a Mushaf is turned.
                reverse: true,
                itemCount: pages.length,
                onPageChanged: (int i) => setState(() => _page = i),
                itemBuilder: (BuildContext context, int i) {
                  final Widget page = Container(
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
                  );
                  return _PageTurn(
                    controller: _controller,
                    index: i,
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
/// The leaf rotates about its inner edge with a perspective transform, so it
/// tips away from you as it leaves and settles flat as it arrives - the motion
/// a paper page makes. A shadow deepens across the turning leaf and the spine
/// edge darkens, which is what sells it as paper rather than a rotating
/// rectangle.
///
/// A true page CURL - paper bending in an arc, the back of the sheet showing
/// through - needs a fragment shader deforming a mesh. This is the hinge, not
/// the curl: convincing, and it costs one Transform per page instead of a
/// custom render pipeline on every frame.
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
        // Before the first layout the controller has no page value at all.
        double delta = 0;
        if (controller.hasClients &&
            controller.position.haveDimensions &&
            controller.page != null) {
          delta = controller.page! - index;
        }

        // Only the two pages either side of the fold are moving.
        final double t = delta.clamp(-1.0, 1.0);

        // The leaf hinges on its inner edge. reverse: true on the PageView
        // means the incoming page arrives from the left, so the spine sits on
        // the opposite side to a left-to-right book.
        final Alignment hinge =
            t >= 0 ? Alignment.centerLeft : Alignment.centerRight;

        final Matrix4 m = Matrix4.identity()
          ..setEntry(3, 2, 0.0016) // perspective; without it this is 2D skew
          ..rotateY(t * math.pi * 0.5);

        // Paper does not brighten as it turns away from the light.
        final double shade = (t.abs() * 0.45).clamp(0.0, 0.45);

        return Transform(
          alignment: hinge,
          transform: m,
          child: Stack(
            fit: StackFit.passthrough,
            children: <Widget>[
              child,
              if (shade > 0.001)
                Positioned.fill(
                  child: IgnorePointer(
                    child: Container(
                      margin: const EdgeInsets.fromLTRB(14, 10, 14, 4),
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
                            Colors.black.withOpacity(shade * 0.15),
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
