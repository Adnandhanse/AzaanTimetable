import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../data/ruku_boundaries.dart';
import '../data/tajweed_data.dart';
import '../services/quran_tajweed_style.dart';
import '../models/quran.dart';
import '../theme/app_theme.dart';

/// One paginated page: its text, and which verses fall on it.
class _MushafPage {
  const _MushafPage({
    required this.lineRanges,
    required this.firstVerse,
    required this.lastVerse,
    required this.firstIndex,
    required this.lastIndex,
  });

  final List<(int, int)> lineRanges;
  final int firstVerse;
  final int lastVerse;
  final int firstIndex;
  final int lastIndex;
}

/// Arabic-only reader with 15 measured Arabic rows on every full page.
class MushafView extends StatefulWidget {
  const MushafView({
    super.key,
    required this.verses,
    this.fontSize = 26,
    this.numberRukuByJuz = false,
    this.onMarkIndex,
    this.markedIndex,
    this.initialVerseIndex,
    this.sajdahIndices = const <int>{},
    this.surahForIndex,
    this.surahNameForIndex,
  });

  /// Any run of verses - a whole surah, or the span a juz covers.
  final List<QuranVerse> verses;
  final double fontSize;
  final bool numberRukuByJuz;

  /// Save the reading position. Receives the INDEX of the first verse on the
  /// current page, not its number.
  final void Function(int firstVerseIndexOnPage)? onMarkIndex;

  final int? markedIndex;
  final int? initialVerseIndex;

  /// Indices of verses at which a sajdah is marked.
  ///
  /// INDICES, not verse numbers - a juz spans several surahs, so ayah 15 is
  /// ambiguous, exactly as it was for the bookmark.
  final Set<int> sajdahIndices;

  /// Which surah a given verse index belongs to, for the Ruku indicator.
  ///
  /// A surah screen always answers with its own surah number; a juz screen
  /// answers per-index, since a juz runs across several surahs. Omitted
  /// entirely, the Ruku indicator just does not show - this is optional
  /// context, not something MushafView can work out on its own from a flat
  /// verse list.
  final int Function(int index)? surahForIndex;
  final String Function(int index)? surahNameForIndex;

  @override
  State<MushafView> createState() => _MushafViewState();
}

class _MushafViewState extends State<MushafView> {
  final PageController _controller = PageController();

  int _page = 0;
  final Map<int, String> _colourMarks = {};
  static const int _linesPerPage = 15;
  String _readingText = '';
  final Map<int, String> _surahOpenings = {};

  List<_MushafPage>? _pages;

  bool _jumpedToInitial = false;
  double? _cachedWidth;
  bool? _cachedJuzNumbering;
  List<QuranVerse>? _cachedVerses;
  double? _cachedFontSize;
  TextScaler? _cachedTextScaler;
  bool? _cachedTajweed;

  static const double _rukuGutter = 25;
  static const _viewportPadding = EdgeInsets.fromLTRB(3, 2, 3, 4);
  static const _pageMargin = EdgeInsets.fromLTRB(
    _rukuGutter + 3, 2, _rukuGutter + 3, 4,
  );
  final Map<int, int> _rukuEndDigits = {};
  static const double _lineSpacing = 1.75;
  static final String _bismillah = tajweedData['1:1']![0] as String;
  // The bundled edition retains an extra shadda in the openings of 95 and 97.
  static final String _bismillahWithShadda = 'بّ${_bismillah.substring(1)}';

  static String? _openingPrefix(String text) {
    if (text.startsWith('$_bismillah ')) return _bismillah;
    if (text.startsWith('$_bismillahWithShadda ')) return _bismillahWithShadda;
    return null;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // Isolate the complete number label so multiple digits keep their order
  // inside RTL text. The preceding no-break space keeps it with the ayah.
  static final RegExp _ayahMarker = RegExp(
    '\u2066\\([\u0660-\u0669]+\\)\u2069',
  );

  List<TextSpan> _spans(
    String pageText, {
    required TextStyle bodyStyle,
    required TextStyle markerStyle,
    int charStart = 0,
  }) {
    final List<TextSpan> spans = <TextSpan>[];
    int last = 0;

    for (final RegExpMatch match in _ayahMarker.allMatches(pageText)) {
      if (match.start > last) {
        spans.addAll(QuranTajweedStyle.spans(
          pageText.substring(last, match.start), bodyStyle, _colourMarks,
          Theme.of(context).brightness == Brightness.dark, offset: charStart + last));
      }
      final token = match.group(0)!;
      // Reserve the original marker footprint while painting a thin ring
      // around the digits separately from the Arabic glyphs.
      final invisible = markerStyle.copyWith(color: Colors.transparent);
      spans.add(TextSpan(text: token.substring(0, 2), style: invisible));
      spans.add(TextSpan(
        text: token.substring(2, token.length - 2), style: markerStyle,
      ));
      spans.add(TextSpan(text: token.substring(token.length - 2), style: invisible));
      last = match.end;
    }

    if (last < pageText.length) {
      spans.addAll(QuranTajweedStyle.spans(
        pageText.substring(last), bodyStyle, _colourMarks,
        Theme.of(context).brightness == Brightness.dark, offset: charStart + last));
    }

    return spans;
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
  /// starts at.
  (String, List<int>) _flow() {
    _colourMarks.clear();
    _surahOpenings.clear();
    _rukuEndDigits.clear();
    final StringBuffer buffer = StringBuffer();
    final List<int> starts = <int>[];

    bool afterFatihaBismillah = false;
    int juzRuku = 0;
    for (int index = 0; index < widget.verses.length; index++) {
      final QuranVerse verse = widget.verses[index];
      final verseText = verse.arabicText.trim();
      final verseSurah = widget.surahForIndex?.call(index);
      final opensSurah = verse.number == 1;
      final prefix = opensSurah && verseSurah != 9
          ? _openingPrefix(verseText)
          : null;
      if (index > 0) {
        buffer.write(opensSurah || afterFatihaBismillah ? '\n' : '  ');
      }
      afterFatihaBismillah = opensSurah && verseSurah == 1 &&
          verseText == _bismillah;
      starts.add(buffer.length);
      final surahName = opensSurah ? widget.surahNameForIndex?.call(index) : null;
      if (surahName != null && surahName.isNotEmpty) {
        _surahOpenings[buffer.length] = surahName;
      }
      if (verseSurah != null) {
        final marks = QuranTajweedStyle.marks(verseSurah, verse.number, verseText);
        for (final entry in marks.entries) {
          _colourMarks[buffer.length + entry.key] = entry.value;
        }
      }
      // Replace only the separator space: all Tajweed offsets stay valid.
      if (prefix != null) {
        buffer
          ..write(prefix)
          ..write('\n')
          ..write(verseText.substring(prefix.length + 1));
      } else {
        buffer.write(verseText);
      }
      buffer.write('\u00A0\u2066(');
      buffer.write(_arabicDigits(verse.number));
      final ruku = verseSurah == null ? null : rukuAt(verseSurah, verse.number);
      if (ruku != null && ruku.$3 == verse.number) {
        juzRuku++;
        _rukuEndDigits[buffer.length - 1] =
            widget.numberRukuByJuz ? juzRuku : ruku.$1;
      }
      buffer.write(')\u2069');
      if (widget.sajdahIndices.contains(index)) buffer.write('  ۩  ');
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
  List<_MushafPage> _paginate({
    required TextStyle style,
    required TextStyle markerStyle,
    required double maxWidth,
    required TextScaler textScaler,
  }) {
    final (String text, List<int> starts) = _flow();

    _readingText = text;

    if (text.isEmpty || starts.isEmpty) {
      return const <_MushafPage>[];
    }

    // Built from the SAME mixed-style spans the page actually renders (see
    // _spans), not a uniform-style approximation - otherwise the ayah-marker
    // run's real (smaller, different-font) width wouldn't match what this
    // layout assumed, and computed line/page breaks could drift from where
    // Text.rich actually wraps.
    final TextPainter textPainter = TextPainter(
      text: TextSpan(
        children: _spans(text, bodyStyle: style, markerStyle: markerStyle),
      ),
      textDirection: TextDirection.rtl,
      textAlign: TextAlign.center,
      textScaler: textScaler,
    )..layout(maxWidth: maxWidth);

    final List<LineMetrics> lines = textPainter.computeLineMetrics();

    if (lines.isEmpty) {
      textPainter.dispose();
      return const <_MushafPage>[];
    }

    // Record each shaped row once. Render those exact slices instead of
    // letting each page wrap the text again and change the row count.
    final ranges = <(int, int)>[];
    for (final line in lines) {
      final position = textPainter.getPositionForOffset(
        Offset(line.left + line.width / 2,
            line.baseline + (line.descent - line.ascent) / 2),
      );
      final boundary = textPainter.getLineBoundary(position);
      if (boundary.start < 0 || boundary.end > text.length) continue;
      final raw = text.substring(boundary.start, boundary.end);
      final content = raw.trim();
      if (content.isEmpty) continue;
      final start = boundary.start + raw.length - raw.trimLeft().length;
      final end = start + content.length;
      if (ranges.isEmpty || start >= ranges.last.$2) {
        ranges.add((start, end));
      }
    }
    textPainter.dispose();

    final pages = <_MushafPage>[];
    for (int first = 0; first < ranges.length; first += _linesPerPage) {
      final end = math.min(first + _linesPerPage, ranges.length);
      final pageRows = ranges.sublist(first, end);
      final firstIndex = _verseIndexAt(starts, pageRows.first.$1);
      final lastIndex = _verseIndexAt(starts, pageRows.last.$2 - 1);
      pages.add(_MushafPage(
        lineRanges: pageRows,
        firstVerse: widget.verses[firstIndex].number,
        lastVerse: widget.verses[lastIndex].number,
        firstIndex: firstIndex,
        lastIndex: lastIndex,
      ));
    }

    return pages;
  }

  @override
  Widget build(BuildContext context) {
    final textScaler = MediaQuery.textScalerOf(context);
    final dark = Theme.of(context).brightness == Brightness.dark;
    final frameColor = dark ? const Color(0xFFD5DFD5) : const Color(0xFF26302C);
    final openingFill = Color.lerp(AppColors.white, AppColors.emerald, dark ? 0.18 : 0.08)!;
    final ruleColor = dark ? const Color(0xFF839187) : const Color(0xFF535E57);
    final TextStyle style = AppText.quranAyah.copyWith(
      fontSize: widget.fontSize,
      height: _lineSpacing,
      color: AppColors.text,
    );

    // Ayah-end marker style, shared by pagination, the ruled-line layout,
    // and the actual rendered text so all three agree on where lines break.
    // Amiri provides normal-width Arabic-Indic digits for these labels.
    final TextStyle markerStyle = style.copyWith(
      fontFamily: AppFonts.arabic,
      fontSize: (widget.fontSize * 0.32).clamp(9.0, 14.0).toDouble(),
      color: Color.lerp(AppColors.emerald, AppColors.text, 0.26)!,
    );

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        const double gutter = 7;
        final double pageWidth =
            math.max(1.0, constraints.maxWidth - _pageMargin.horizontal);
        final double maxWidth = math.max(1.0, pageWidth - gutter * 2);
        if (_pages == null ||
            _cachedWidth != maxWidth ||
            _cachedJuzNumbering != widget.numberRukuByJuz ||
            _cachedVerses != widget.verses ||
            _cachedFontSize != widget.fontSize ||
            _cachedTextScaler != textScaler ||
            _cachedTajweed != QuranTajweedStyle.enabled) {
          _pages = _paginate(
            style: style,
            markerStyle: markerStyle,
            maxWidth: maxWidth,
            textScaler: textScaler,
          );

          _cachedWidth = maxWidth;
          _cachedJuzNumbering = widget.numberRukuByJuz;
          _cachedVerses = widget.verses;
          _cachedFontSize = widget.fontSize;
          _cachedTextScaler = textScaler;
          _cachedTajweed = QuranTajweedStyle.enabled;
        }

        final List<_MushafPage> pages = _pages!;

        if (pages.isEmpty) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        // Resume once, after pagination exists.
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
            // Page information and bookmark control at the top.
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
                      'Page ${safePage + 1} of ${pages.length}',
                      style: AppText.caption.copyWith(color: AppColors.textMuted),
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
                  final data = pages[index];
                  final blocks = <Widget>[];
                  for (final (rowStart, rowEnd) in data.lineRanges) {
                    final openingName = _surahOpenings[rowStart];
                    final content = _readingText.substring(rowStart, rowEnd);
                    final span = TextSpan(
                      children: _spans(content, charStart: rowStart,
                          bodyStyle: style, markerStyle: markerStyle),
                    );
                    final isBismillah = content == _bismillah ||
                        content == _bismillahWithShadda ||
                        content.startsWith('$_bismillah\u00A0\u2066(');
                    const alignment = TextAlign.center;
                    final painter = TextPainter(
                      text: span,
                      textDirection: TextDirection.rtl,
                      textAlign: alignment,
                      maxLines: 1,
                      textScaler: textScaler,
                    )..layout(minWidth: maxWidth, maxWidth: maxWidth);
                    final bottoms = [
                      for (final line in painter.computeLineMetrics())
                        line.baseline + line.descent,
                    ];
                    final rukuRows = <int, List<int>>{};
                    final rings = <Rect>[];
                    for (final marker in _ayahMarker.allMatches(content)) {
                      final boxes = painter.getBoxesForSelection(
                        TextSelection(
                          baseOffset: marker.start + 2,
                          extentOffset: marker.end - 2,
                        ),
                      );
                      if (boxes.isEmpty) continue;
                      final digits = boxes
                          .map((box) => box.toRect())
                          .reduce((a, b) => a.expandToInclude(b));
                      final center = digits.center;
                      final diameter = math.max(
                        textScaler.scale(markerStyle.fontSize!) * 1.42,
                        digits.width + 3,
                      );
                      rings.add(Rect.fromCircle(
                        center: Offset(center.dx + gutter, center.dy),
                        radius: diameter / 2,
                      ));
                      final number = _rukuEndDigits[rowStart + marker.end - 3];
                      if (number == null) continue;
                      final line = bottoms.indexWhere((bottom) => center.dy < bottom);
                      if (line >= 0) {
                        (rukuRows[line] ??= <int>[]).add(number);
                      }
                    }
                    painter.dispose();

                    final ruledText = Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(gutter, 0, gutter, 3),
                          child: SizedBox(
                            width: maxWidth,
                            child: RichText(
                              text: span,
                              textDirection: TextDirection.rtl,
                              textAlign: alignment,
                              softWrap: false,
                              maxLines: 1,
                              overflow: TextOverflow.visible,
                              textScaler: textScaler,
                            ),
                          ),
                        ),
                        for (final ring in rings)
                          Positioned.fromRect(
                            rect: ring,
                            child: IgnorePointer(
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(color: markerStyle.color!),
                                ),
                              ),
                            ),
                          ),
                        for (final y in isBismillah ? const <double>[] : bottoms)
                          Positioned(
                            left: 2,
                            right: 2,
                            top: y + 1,
                            height: 1.25,
                            child: ColoredBox(color: ruleColor),
                          ),
                        for (final entry in rukuRows.entries)
                          Positioned(
                            left: -_rukuGutter,
                            width: _rukuGutter - 3,
                            top: entry.key == 0 ? 0 : bottoms[entry.key - 1],
                            height: bottoms[entry.key] -
                                (entry.key == 0 ? 0 : bottoms[entry.key - 1]),
                            child: Semantics(
                              label: entry.value.map((n) => 'End of Ruku $n').join(', '),
                              child: ExcludeSemantics(
                                child: Center(
                                  child: FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Text(
                                      'ع ${entry.value.map(_arabicDigits).join('، ')}',
                                      textDirection: TextDirection.ltr,
                                      style: markerStyle.copyWith(fontSize: 17),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    );
                    if (openingName != null || isBismillah) {
                      blocks.add(Container(
                        decoration: BoxDecoration(
                          color: openingFill,
                          border: Border(
                            top: BorderSide(color: ruleColor),
                            bottom: BorderSide(color: ruleColor),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            if (openingName != null)
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: gutter, vertical: 6,
                                ),
                                child: Text(
                                  openingName,
                                  textAlign: TextAlign.center,
                                  textDirection: TextDirection.rtl,
                                  style: AppText.arabicTitle.copyWith(
                                    color: AppColors.text, fontSize: 21,
                                  ),
                                ),
                              ),
                            if (isBismillah) ruledText,
                          ],
                        ),
                      ));
                    }
                    if (!isBismillah) blocks.add(ruledText);
                  }
                  final Widget page = Padding(
                    padding: _viewportPadding,
                    child: Align(
                      alignment: Alignment.topCenter,
                      child: SingleChildScrollView(
                        physics: const ClampingScrollPhysics(),
                        padding: const EdgeInsets.symmetric(horizontal: _rukuGutter),
                        child: Container(
                          width: pageWidth,
                          color: AppColors.white,
                          foregroundDecoration: BoxDecoration(
                            border: Border.all(color: frameColor, width: 3),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: blocks,
                          ),
                        ),
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

/// Hinge-style page turn rather than a true paper curl.
///
/// A true curl would require mesh deformation / shader rendering.
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
                      margin: _MushafViewState._pageMargin,
                      decoration: BoxDecoration(
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
