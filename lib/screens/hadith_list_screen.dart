import 'package:flutter/material.dart';

import '../services/app_strings.dart';
import '../services/hadith_grade_sections.dart';
import 'hadith_single_screen.dart';

import '../models/hadith.dart';
import '../services/quran_local_data_service.dart';
import '../services/tts_service.dart';
import '../theme/app_theme.dart';
import '../widgets/speed_selector.dart';

class HadithListScreen extends StatefulWidget {
  final HadithCollection collection;
  final HadithChapter chapter;
  final String bookKey;
  final String language;

  /// Optional grade-section items; original collection/numbering stay intact.
  final List<HadithItem>? selectedHadiths;
  final bool enableGradeTabs;
  final VoidCallback? onBrowseChapters;

  /// Land on this hadith, expanded and outlined. Used when someone searches a
  /// number and wants the hadith itself, not the chapter it lives in.
  final int? highlightHadithNumber;

  const HadithListScreen({
    super.key,
    required this.collection,
    required this.chapter,
    required this.bookKey,
    required this.language,
    this.highlightHadithNumber,
    this.selectedHadiths,
    this.enableGradeTabs = false,
    this.onBrowseChapters,
  });

  @override
  State<HadithListScreen> createState() => _HadithListScreenState();
}

class _HadithListScreenState extends State<HadithListScreen> {
  Set<String> _bookmarks = {};
  final ScrollController _scroll = ScrollController();

  /// Which hadith are open. Collapsed by default — a chapter of 170 hadith
  /// shown in full is unreadable and unscrollable, and finding anything in it
  /// means dragging past thousands of pixels of text.
  final Set<int> _expanded = <int>{};

  int? _speaking;
  double _rate = 0.45;
  int _activeTab = 0;
  String _query = '';
  bool _showSearch = false;
  final _searchController = TextEditingController();
  final Map<HadithItem, HadithGradeSection?> _grades = {};


  @override
  void initState() {
    super.initState();
    if (widget.enableGradeTabs) {
      for (final item in _baseHadiths) {
        _grades[item] = HadithGradeSections.classify(item, bookKey: widget.bookKey);
      }
    }
    final int? target = widget.highlightHadithNumber;
    if (target != null) {
      // The searched hadith opens expanded. Landing on a collapsed card would
      // make you tap again to see what you searched for.
      _expanded.add(target);
    }
    _loadBookmarks();
    TtsService.onComplete(() {
      if (mounted) setState(() => _speaking = null);
    });
    TtsService.speechRate().then((r) {
      if (mounted) setState(() => _rate = r);
    });
  }

  @override
  void dispose() {
    TtsService.stop();
    _scroll.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadBookmarks() async {
    final b = await QuranLocalDataService.getHadithBookmarks();
    if (!mounted) return;
    setState(() => _bookmarks = b);
  }

  String _bookmarkKey(int n) => '${widget.bookKey}|${widget.language}|$n';

  bool _isBookmarked(int n) => _bookmarks.contains(_bookmarkKey(n));

  Future<void> _toggleBookmark(int n) async {
    // Existing signature and existing key format — bookmarks saved by earlier
    // versions must keep working, so the storage is left exactly as it was.
    await QuranLocalDataService.toggleHadithBookmark(
        widget.bookKey, widget.language, n);
    _loadBookmarks();
  }

  List<HadithItem> get _baseHadiths =>
      widget.selectedHadiths ?? widget.collection.hadithsInChapter(widget.chapter.number);

  List<HadithItem> get _searched {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return _baseHadiths;
    final number = int.tryParse(q);
    return _baseHadiths.where((h) => number != null
        ? h.hadithNumber == number
        : h.text.toLowerCase().contains(q) || h.arabicText.contains(q)).toList();
  }

  List<HadithItem> get _hadiths => _searched.where((h) => !widget.enableGradeTabs ||
      _activeTab == 0 || _grades[h] == (_activeTab == 1
          ? HadithGradeSection.sahih : HadithGradeSection.daif)).toList();

  String get _bookName {
    for (final book in HadithBook.values) {
      if (book.fileKey == widget.bookKey) return widget.language == 'urd' ? book.urduName : book.displayName;
    }
    return widget.collection.name;
  }

  String _sourceStatus(HadithItem h) {
    if (HadithGradeSections.isSahihCollection(widget.bookKey)) return 'Sahih';
    for (final grade in h.grades) {
      final separator = grade.lastIndexOf(' - ');
      if (separator < 0) continue;
      final name = grade.substring(separator + 3)
          .toLowerCase().replaceAll(RegExp(r'[^a-z]'), '');
      if (name.contains('albani')) return grade;
    }
    return h.grades.isEmpty ? (widget.language == 'urd' ? 'درجہ دستیاب نہیں' : 'Grade not supplied') : h.grades.join(' • ');
  }

  /// NO SCROLL-TO-TARGET HERE, DELIBERATELY.
  ///
  /// It used to estimate an offset from the item index, jump, then correct with
  /// Scrollable.ensureVisible. That cannot work: ListView.builder has not built
  /// anything off screen, so when the estimate misses the target does not exist
  /// and the correction does nothing. Card heights range from two lines to
  /// thousands of pixels, so the estimate always misses — searching 789 landed
  /// on 756.
  ///
  /// Searching a number now opens HadithSingleScreen instead, which needs no
  /// arithmetic and cannot miss. If the reader arrives here from that screen,
  /// the hadith is still outlined in gold so it is findable by eye, and the
  /// list is left where the reader put it rather than twitching to a guess.

  Future<void> _speak(HadithItem h) async {
    if (_speaking == h.hadithNumber) {
      await TtsService.stop();
      if (mounted) setState(() => _speaking = null);
      return;
    }
    final TtsLang lang =
        widget.language == 'urd' ? TtsLang.urdu : TtsLang.english;

    // Only ever the translation. Never h.arabicText.
    final ok = await TtsService.speak(h.text, lang);
    if (!mounted) return;
    if (!ok) {
      setState(() => _speaking = null);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(lang == TtsLang.urdu
              ? 'Urdu speech is not installed on this phone. Add it in Settings > General management > Text-to-speech.'
              : 'Speech is not available on this phone.'),
          duration: const Duration(seconds: 5),
        ),
      );
      return;
    }
    setState(() => _speaking = h.hadithNumber);
  }

  @override
  Widget build(BuildContext context) {
    final hadiths = _hadiths;

    final scope = _searched;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final urdu = widget.language == 'urd';
    final sahihCount = scope.where((h) => _grades[h] == HadithGradeSection.sahih).length;
    final daifCount = scope.where((h) => _grades[h] == HadithGradeSection.daif).length;
    return DefaultTabController(
      length: 3,
      child: Scaffold(
      appBar: AppBar(
        title: widget.enableGradeTabs ? Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(_bookName, style: const TextStyle(fontSize: 17)),
          Text('${hadiths.length} ${urdu ? 'احادیث' : 'hadith found'}', style: const TextStyle(fontSize: 12)),
        ]) : Text(widget.chapter.title),
        actions: widget.enableGradeTabs ? [
          IconButton(icon: Icon(_showSearch ? Icons.close : Icons.search),
            tooltip: urdu ? 'تلاش کریں' : 'Search',
            onPressed: () => setState(() {
              _showSearch = !_showSearch;
              if (!_showSearch) { _query = ''; _searchController.clear(); }
            })),
          if (widget.onBrowseChapters != null)
            IconButton(icon: const Icon(Icons.menu_book_outlined),
              tooltip: urdu ? 'ابواب' : 'Browse chapters', onPressed: widget.onBrowseChapters),
        ] : null,
        bottom: widget.enableGradeTabs ? PreferredSize(
          preferredSize: Size.fromHeight(_showSearch ? 116 : 48),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            if (_showSearch) Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
              child: TextField(controller: _searchController,
                onChanged: (value) => setState(() => _query = value),
                decoration: InputDecoration(isDense: true,
                  prefixIcon: const Icon(Icons.search),
                  hintText: urdu ? 'حدیث یا نمبر تلاش کریں' : 'Search text or hadith number')),
            ),
            TabBar(
              labelPadding: EdgeInsets.zero,
              labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
              labelColor: dark ? const Color(0xFFA7D2B5) : const Color(0xFF276346),
              unselectedLabelColor: dark ? Colors.white70 : const Color(0xFF6B736E),
              indicatorColor: const Color(0xFF659D7B),
              onTap: (index) async {
                await TtsService.stop();
                if (mounted) setState(() { _activeTab = index; _speaking = null; });
              },
              tabs: [
                Tab(text: '${urdu ? 'تمام' : 'ALL'} · ${scope.length}'),
                Tab(text: '${urdu ? 'صحیح' : 'SAHIH'} · $sahihCount'),
                Tab(text: '${urdu ? 'ضعیف' : 'ZAEEF'} · $daifCount'),
              ],
            ),
          ]),
        ) : null,
      ),
      body: Column(children: [
        if (widget.enableGradeTabs) Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
          child: Text(HadithGradeSections.isSahihCollection(widget.bookKey)
            ? (urdu ? 'صحیح مجموعہ: تمام احادیث صحیح ٹیب میں ہیں۔' : 'Sahih collection: all entries appear in the Sahih tab.')
            : (urdu ? 'درجہ: البانی جہاں موجود ہو۔ حسن اور غیر واضح درجات اصل حیثیت کے ساتھ تمام میں ہیں۔'
                : 'Al-Albani grading where supplied. Hasan and unclear grades remain in All with their original status.'),
            style: TextStyle(fontSize: 11, color: dark ? Colors.white60 : const Color(0xFF6B736E))),
        ),
        Expanded(child: hadiths.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(28),
                child: Text(
                  widget.selectedHadiths != null
                      ? (widget.language == 'urd' ? 'اس حصے میں کوئی حدیث دستیاب نہیں ہے۔' : 'No hadith in this section in the bundled data.')
                      : 'No hadith in this chapter are available in this translation.',
                  textAlign: TextAlign.center,
                  style: AppText.body.copyWith(color: AppColors.textMuted),
                ),
              ),
            )
          : ListView.builder(
              controller: _scroll,
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              itemCount: hadiths.length,
              itemBuilder: (context, index) {
                final h = hadiths[index];
                final bool isTarget =
                    widget.highlightHadithNumber == h.hadithNumber;
                if (widget.enableGradeTabs) {
                  return _BookReadingCard(
                    item: h, bookName: _bookName, status: _sourceStatus(h),
                    urdu: urdu, speaking: _speaking == h.hadithNumber,
                    bookmarked: _isBookmarked(h.hadithNumber), rate: _rate,
                    onPlay: () => _speak(h), onBookmark: () => _toggleBookmark(h.hadithNumber),
                    onRate: (r) async { await TtsService.setSpeechRate(r); if (mounted) setState(() => _rate = r); },
                    onReadFull: () => Navigator.of(context).push(MaterialPageRoute<void>(
                      builder: (_) => HadithSingleScreen(collection: widget.collection,
                        hadithNumber: h.hadithNumber, bookKey: widget.bookKey,
                        bookName: _bookName, language: widget.language))),
                  );
                }
                return _HadithCard(
                  item: h,
                  isUrduText: widget.language == 'urd',
                  isTarget: isTarget,
                  isExpanded: _expanded.contains(h.hadithNumber),
                  isBookmarked: _isBookmarked(h.hadithNumber),
                  isSpeaking: _speaking == h.hadithNumber,
                  rate: _rate,
                  onRate: (r) async {
                    await TtsService.setSpeechRate(r);
                    if (mounted) setState(() => _rate = r);
                  },
                  onToggle: () => setState(() {
                    if (!_expanded.remove(h.hadithNumber)) {
                      _expanded.add(h.hadithNumber);
                    }
                  }),
                  onBookmark: () => _toggleBookmark(h.hadithNumber),
                  onSpeak: () => _speak(h),
                );
              },
            )),
      ]),
      ),
    );
  }
}

class _HadithCard extends StatelessWidget {
  const _HadithCard({
    super.key,
    required this.item,
    required this.isUrduText,
    required this.isTarget,
    required this.isExpanded,
    required this.isBookmarked,
    required this.isSpeaking,
    required this.rate,
    required this.onRate,
    required this.onToggle,
    required this.onBookmark,
    required this.onSpeak,
  });

  final HadithItem item;

  /// Whether the translation being displayed is Urdu, so it can be set in
  /// Nastaliq and laid out right-to-left.
  final bool isUrduText;

  final bool isTarget;
  final bool isExpanded;
  final bool isBookmarked;
  final bool isSpeaking;
  final double rate;
  final ValueChanged<double> onRate;
  final VoidCallback onToggle;
  final VoidCallback onBookmark;
  final VoidCallback onSpeak;

  /// A short, honest preview: the opening of the translation, or the Arabic if
  /// there is no translation. Deliberately not a summary — paraphrasing a
  /// hadith to fit a card is not something an app should do.
  String get _preview {
    final t = item.text.trim();
    if (t.isNotEmpty) return t;
    return item.arabicText.trim();
  }

  bool get _previewIsArabic => item.text.trim().isEmpty;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: isTarget ? AppColors.gold : AppColors.goldRule,
          width: isTarget ? 2 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: onToggle,
            borderRadius: BorderRadius.circular(4),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 8, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Badges wrap; the bookmark is pinned. Three items in a plain
                  // Row pushed the icon off screen once numbers reached four
                  // digits.
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: [
                            _Badge(
                              text: '${S.hadithWord} ${item.hadithNumber}',
                              bg: AppColors.emerald.withOpacity(0.1),
                              fg: AppColors.emerald,
                            ),
                            if (item.arabicNumber != null)
                              _Badge(
                                text: '${S.arabicEdition} ${item.arabicNumber}',
                                bg: AppColors.gold.withOpacity(0.15),
                                fg: const Color(0xFF8A6D1E),
                              ),
                            for (final g in item.grades)
                              _Badge(
                                text: g,
                                bg: g.toLowerCase().contains('daif')
                                    ? const Color(0x1AB3261E)
                                    : AppColors.emerald.withOpacity(0.08),
                                fg: g.toLowerCase().contains('daif')
                                    ? const Color(0xFFB3261E)
                                    : AppColors.textMid,
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 4),
                      SizedBox(
                        width: 40,
                        child: IconButton(
                          padding: EdgeInsets.zero,
                          visualDensity: VisualDensity.compact,
                          icon: Icon(
                            isBookmarked
                                ? Icons.bookmark
                                : Icons.bookmark_border,
                            color: isBookmarked
                                ? AppColors.gold
                                : AppColors.chevron,
                          ),
                          tooltip: 'Bookmark',
                          onPressed: onBookmark,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (!isExpanded) ...[
                    Directionality(
                      textDirection: _previewIsArabic
                          ? TextDirection.rtl
                          : TextDirection.ltr,
                      child: Text(
                        _preview,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: _previewIsArabic
                            ? AppText.arabic.copyWith(
                                fontSize: 17,
                                height: 1.6,
                                color: AppColors.text)
                            : (isUrduText
                                ? AppText.urduText
                                    .copyWith(fontSize: 16, color: AppColors.textMid)
                                : AppText.translation
                                    .copyWith(color: AppColors.textMid)),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Text(S.tapToReadFull,
                            style: AppText.caption
                                .copyWith(color: AppColors.gold)),
                        const SizedBox(width: 4),
                        Icon(Icons.expand_more,
                            size: 16, color: AppColors.gold),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
          if (isExpanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ABOVE THE TEXT, not below it.
                  //
                  // A hadith can run for several screens, so a control at the
                  // bottom meant scrolling past the whole thing to start
                  // listening — the one thing you want before reading, not
                  // after.
                  if (item.text.trim().isNotEmpty) ...[
                    Row(
                      children: [
                      OutlinedButton.icon(
                        onPressed: onSpeak,
                        icon: Icon(
                            isSpeaking ? Icons.stop : Icons.volume_up_outlined,
                            size: 16),
                        // Says "translation" on purpose. It never reads the
                        // Arabic and the label should not suggest it does.
                        label: Text(
                            isSpeaking ? S.stopWord : S.listenToTranslation),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.emerald,
                          side: BorderSide(color: AppColors.goldRule),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 8),
                          minimumSize: Size.zero,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(4)),
                          textStyle: AppText.caption,
                        ),
                      ),
                      const Spacer(),
                      SpeedSelector(
                        options: TtsService.speeds,
                        value: rate,
                        onChanged: onRate,
                        compact: true,
                      ),
                      ],
                    ),
                    const SizedBox(height: 10),
                  ],
                  if (item.arabicText.trim().isNotEmpty) ...[
                    Container(height: 1, color: AppColors.goldRuleFaint),
                    const SizedBox(height: 10),
                    Directionality(
                      textDirection: TextDirection.rtl,
                      child: Text(
                        item.arabicText,
                        textAlign: TextAlign.right,
                        style: AppText.arabicVerse
                            .copyWith(fontSize: 21, color: AppColors.text),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                  if (item.text.trim().isNotEmpty) ...[
                    Container(height: 1, color: AppColors.goldRuleFaint),
                    const SizedBox(height: 10),
                    // Nastaliq when the translation being shown is Urdu. Naskh
                    // renders Urdu legibly but wrongly — the way English set in
                    // Fraktur is legible but wrong.
                    Text(
                      item.text,
                      textDirection: isUrduText
                          ? TextDirection.rtl
                          : TextDirection.ltr,
                      textAlign:
                          isUrduText ? TextAlign.right : TextAlign.left,
                      style: isUrduText
                          ? AppText.urduText.copyWith(color: AppColors.text)
                          : AppText.translation
                              .copyWith(color: AppColors.text),
                    ),
                  ] else
                    Text(
                      S.noTranslationAvailable,
                      style: AppText.caption
                          .copyWith(color: AppColors.textFaint),
                    ),
                  if (item.grades.length > 1) ...[
                    const SizedBox(height: 10),
                    Text(S.gradings,
                        style: AppText.eyebrow.copyWith(
                            letterSpacing: 1.4, color: AppColors.textMuted)),
                    const SizedBox(height: 4),
                    for (final g in item.grades)
                      Text('· $g',
                          style: AppText.caption
                              .copyWith(color: AppColors.textMuted)),
                  ],
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      const Spacer(),
                      InkWell(
                        onTap: onToggle,
                        child: Padding(
                          padding: const EdgeInsets.all(6),
                          child: Row(
                            children: [
                              Text(S.collapse,
                                  style: AppText.caption
                                      .copyWith(color: AppColors.textMuted)),
                              Icon(Icons.expand_less,
                                  size: 16, color: AppColors.textMuted),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.text, required this.bg, required this.fg});

  final String text;
  final Color bg;
  final Color fg;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration:
          BoxDecoration(color: bg, borderRadius: BorderRadius.circular(6)),
      child: Text(
        text,
        style: AppText.caption
            .copyWith(fontSize: 12, fontWeight: FontWeight.w600, color: fg),
      ),
    );
  }
}


class _BookReadingCard extends StatelessWidget {
  const _BookReadingCard({required this.item, required this.bookName,
    required this.status, required this.urdu, required this.speaking,
    required this.bookmarked, required this.rate, required this.onPlay,
    required this.onBookmark, required this.onReadFull, required this.onRate});
  final HadithItem item;
  final String bookName, status;
  final bool urdu, speaking, bookmarked;
  final double rate;
  final VoidCallback onPlay, onBookmark, onReadFull;
  final ValueChanged<double> onRate;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final ink = dark ? const Color(0xFFB5D9BF) : const Color(0xFF2B5E43);
    final text = item.text.trim().isEmpty ? item.arabicText : item.text;
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: dark ? const Color(0xFF28382F) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: dark ? const Color(0xFF3C5043) : const Color(0xFFE3E8DE)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 12, offset: const Offset(0, 3))],
      ),
      padding: const EdgeInsets.all(18),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        SelectableText(text,
          textDirection: urdu || item.text.trim().isEmpty ? TextDirection.rtl : TextDirection.ltr,
          textAlign: urdu ? TextAlign.right : TextAlign.left,
          style: urdu ? AppText.urduText.copyWith(fontSize: 18, color: ink)
              : AppText.translation.copyWith(fontSize: 16, height: 1.7, color: ink)),
        const SizedBox(height: 20),
        Divider(color: ink.withOpacity(0.15)),
        const SizedBox(height: 8),
        Text('${urdu ? 'کتاب' : 'Book'}: $bookName',
          style: TextStyle(fontSize: 13, color: dark ? Colors.white70 : const Color(0xFF536157))),
        const SizedBox(height: 4),
        Text('${urdu ? 'حدیث نمبر' : 'Hadith No.'} ${item.hadithNumber}',
          style: TextStyle(fontSize: 13, color: ink, fontWeight: FontWeight.w600)),
        const SizedBox(height: 4),
        Text('${urdu ? 'درجہ' : 'Status'}: $status',
          style: TextStyle(fontSize: 12, color: dark ? Colors.white70 : const Color(0xFF536157))),
        const SizedBox(height: 12),
        Wrap(spacing: 12, runSpacing: 8, crossAxisAlignment: WrapCrossAlignment.center, children: [
          FilledButton.icon(onPressed: item.text.trim().isEmpty ? null : onPlay,
            icon: Icon(speaking ? Icons.stop_rounded : Icons.play_arrow_rounded),
            label: Text(speaking ? S.stopWord : (urdu ? 'ترجمہ سنیں' : 'Play translation')),
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFF47775A), foregroundColor: Colors.white)),
          PopupMenuButton<String>(
            tooltip: urdu ? 'مزید' : 'More',
            icon: Icon(Icons.more_vert, color: ink),
            onSelected: (action) {
              if (action == 'full') onReadFull();
              if (action == 'bookmark') onBookmark();
              if (action == 'grades') showDialog<void>(context: context, builder: (ctx) => AlertDialog(
                title: Text(S.gradings),
                content: SingleChildScrollView(child: Text(item.grades.isEmpty ? status : item.grades.join('\n\n'))),
                actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close'))],
              ));
            },
            itemBuilder: (_) => [
              PopupMenuItem(value: 'full', child: Text(urdu ? 'مکمل حدیث اور عربی' : 'Read in full / Arabic')),
              PopupMenuItem(value: 'bookmark', child: Text(bookmarked ? 'Remove bookmark' : 'Bookmark')),
              PopupMenuItem(value: 'grades', child: Text(S.gradings)),
            ],
          ),
          SpeedSelector(options: TtsService.speeds, value: rate, onChanged: onRate, compact: true),
        ]),
      ]),
    );
  }
}
