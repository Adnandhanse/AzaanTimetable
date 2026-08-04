import 'package:flutter/material.dart';

import '../services/app_strings.dart';

import '../models/hadith.dart';
import '../services/quran_local_data_service.dart';
import '../services/tts_service.dart';
import '../theme/app_theme.dart';

class HadithListScreen extends StatefulWidget {
  final HadithCollection collection;
  final HadithChapter chapter;
  final String bookKey;
  final String language;

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

  @override
  void initState() {
    super.initState();
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
  }

  @override
  void dispose() {
    TtsService.stop();
    _scroll.dispose();
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

  List<HadithItem> get _hadiths =>
      widget.collection.hadithsInChapter(widget.chapter.number);

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

    return Scaffold(
      appBar: AppBar(title: Text(widget.chapter.title)),
      body: hadiths.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(28),
                child: Text(
                  'No hadith in this chapter are available in this translation.',
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
                return _HadithCard(
                  item: h,
                  isTarget: isTarget,
                  isExpanded: _expanded.contains(h.hadithNumber),
                  isBookmarked: _isBookmarked(h.hadithNumber),
                  isSpeaking: _speaking == h.hadithNumber,
                  onToggle: () => setState(() {
                    if (!_expanded.remove(h.hadithNumber)) {
                      _expanded.add(h.hadithNumber);
                    }
                  }),
                  onBookmark: () => _toggleBookmark(h.hadithNumber),
                  onSpeak: () => _speak(h),
                );
              },
            ),
    );
  }
}

class _HadithCard extends StatelessWidget {
  const _HadithCard({
    super.key,
    required this.item,
    required this.isTarget,
    required this.isExpanded,
    required this.isBookmarked,
    required this.isSpeaking,
    required this.onToggle,
    required this.onBookmark,
    required this.onSpeak,
  });

  final HadithItem item;
  final bool isTarget;
  final bool isExpanded;
  final bool isBookmarked;
  final bool isSpeaking;
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
                            for (final g in item.grades.take(1))
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
                            : AppText.translation
                                .copyWith(color: AppColors.textMid),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Text(S.tapToReadFull,
                            style: AppText.caption
                                .copyWith(color: AppColors.gold)),
                        const SizedBox(width: 4),
                        const Icon(Icons.expand_more,
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
                    Text(item.text,
                        style: AppText.translation
                            .copyWith(color: AppColors.text)),
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
                      if (item.text.trim().isNotEmpty)
                        OutlinedButton.icon(
                          onPressed: onSpeak,
                          icon: Icon(
                              isSpeaking ? Icons.stop : Icons.volume_up_outlined,
                              size: 16),
                          // Says "translation" on purpose. The button never
                          // reads the Arabic, and the label should not let
                          // anyone assume it does.
                          label:
                              Text(isSpeaking ? S.stopWord : S.listenToTranslation),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.emerald,
                            side: const BorderSide(color: AppColors.goldRule),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 8),
                            minimumSize: Size.zero,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(4)),
                            textStyle: AppText.caption,
                          ),
                        ),
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
                              const Icon(Icons.expand_less,
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
