import 'package:flutter/material.dart';

import '../services/app_strings.dart';

import '../models/hadith.dart';
import '../services/quran_local_data_service.dart';
import '../services/tts_service.dart';
import '../theme/app_theme.dart';
import '../widgets/ornaments.dart';
import 'hadith_list_screen.dart';

/// One hadith, on its own.
///
/// WHY THIS EXISTS INSTEAD OF SCROLLING A CHAPTER
///
/// Searching a number used to open the chapter and try to scroll to the hadith:
/// estimate an offset from the item's index, jump there, then correct with
/// Scrollable.ensureVisible.
///
/// That cannot work. ListView.builder only creates widgets for what is on
/// screen, so if the estimate lands thirty items short the target does not
/// exist yet, ensureVisible has nothing to find, and the correction silently
/// does nothing. Card heights vary from a couple of lines to several thousand
/// pixels, so no estimate is reliable and no tuning fixes it — searching 789
/// landed on 756.
///
/// Opening the hadith directly has no arithmetic in it and cannot miss. Chapter
/// context is one tap away for anyone who wants it, and previous/next walk the
/// whole book so a hadith near a chapter edge still reads continuously.
class HadithSingleScreen extends StatefulWidget {
  const HadithSingleScreen({
    super.key,
    required this.collection,
    required this.hadithNumber,
    required this.bookKey,
    required this.bookName,
    required this.language,
  });

  final HadithCollection collection;
  final int hadithNumber;
  final String bookKey;
  final String bookName;
  final String language;

  @override
  State<HadithSingleScreen> createState() => _HadithSingleScreenState();
}

class _HadithSingleScreenState extends State<HadithSingleScreen> {
  late int _number;
  Set<String> _bookmarks = {};
  bool _speaking = false;

  /// The whole book in number order, so previous/next do not stop at a chapter
  /// boundary.
  late final List<HadithItem> _ordered;

  @override
  void initState() {
    super.initState();
    _number = widget.hadithNumber;
    _ordered = List<HadithItem>.from(widget.collection.hadiths)
      ..sort((a, b) => a.hadithNumber.compareTo(b.hadithNumber));
    _loadBookmarks();
    TtsService.onComplete(() {
      if (mounted) setState(() => _speaking = false);
    });
  }

  @override
  void dispose() {
    TtsService.stop();
    super.dispose();
  }

  Future<void> _loadBookmarks() async {
    final b = await QuranLocalDataService.getHadithBookmarks();
    if (!mounted) return;
    setState(() => _bookmarks = b);
  }

  HadithItem? get _item {
    for (final HadithItem h in _ordered) {
      if (h.hadithNumber == _number) return h;
    }
    return null;
  }

  int get _index => _ordered.indexWhere((h) => h.hadithNumber == _number);

  HadithChapter? get _chapter {
    final it = _item;
    if (it == null) return null;
    for (final HadithChapter c in widget.collection.chapters) {
      if (c.number == it.chapterNumber) return c;
    }
    return null;
  }

  bool get _isBookmarked =>
      _bookmarks.contains('${widget.bookKey}|${widget.language}|$_number');

  Future<void> _toggleBookmark() async {
    await QuranLocalDataService.toggleHadithBookmark(
        widget.bookKey, widget.language, _number);
    _loadBookmarks();
  }

  Future<void> _speak() async {
    final it = _item;
    if (it == null) return;
    if (_speaking) {
      await TtsService.stop();
      if (mounted) setState(() => _speaking = false);
      return;
    }
    final lang = widget.language == 'urd' ? TtsLang.urdu : TtsLang.english;
    // The translation only. Never it.arabicText.
    final ok = await TtsService.speak(it.text, lang);
    if (!mounted) return;
    if (!ok) {
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
    setState(() => _speaking = true);
  }

  void _step(int delta) {
    final int i = _index;
    if (i < 0) return;
    final int next = i + delta;
    if (next < 0 || next >= _ordered.length) return;
    TtsService.stop();
    setState(() {
      _speaking = false;
      _number = _ordered[next].hadithNumber;
    });
  }

  @override
  Widget build(BuildContext context) {
    final HadithItem? it = _item;
    final HadithChapter? ch = _chapter;

    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.bookName} $_number'),
        actions: [
          IconButton(
            icon: Icon(_isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                size: 20),
            color: _isBookmarked ? AppColors.gold : null,
            tooltip: 'Bookmark',
            onPressed: it == null ? null : _toggleBookmark,
          ),
        ],
      ),
      body: it == null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(28),
                child: Text(
                  'Hadith $_number is not present in ${widget.bookName} in this dataset.',
                  textAlign: TextAlign.center,
                  style: AppText.body.copyWith(color: AppColors.textMuted),
                ),
              ),
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
              children: [
                if (ch != null) ...[
                  SectionRule(label: ch.title),
                  const SizedBox(height: 12),
                ],
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    _Badge(
                      text: '${S.hadithWord} ${it.hadithNumber}',
                      bg: AppColors.emerald.withOpacity(0.1),
                      fg: AppColors.emerald,
                    ),
                    if (it.arabicNumber != null)
                      _Badge(
                        text: '${S.arabicEdition} ${it.arabicNumber}',
                        bg: AppColors.gold.withOpacity(0.15),
                        fg: const Color(0xFF8A6D1E),
                      ),
                    for (final g in it.grades)
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
                const SizedBox(height: 16),
                if (it.arabicText.trim().isNotEmpty) ...[
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: AppColors.goldRule),
                    ),
                    padding: const EdgeInsets.all(16),
                    child: Directionality(
                      textDirection: TextDirection.rtl,
                      child: Text(
                        it.arabicText,
                        textAlign: TextAlign.right,
                        style: AppText.arabicVerse
                            .copyWith(fontSize: 22, color: AppColors.text),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                if (it.text.trim().isNotEmpty)
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: AppColors.goldRule),
                    ),
                    padding: const EdgeInsets.all(16),
                    child: Builder(builder: (context) {
                      final bool urdu = widget.language == 'urd';
                      return Text(
                        it.text,
                        textDirection:
                            urdu ? TextDirection.rtl : TextDirection.ltr,
                        textAlign: urdu ? TextAlign.right : TextAlign.left,
                        style: urdu
                            ? AppText.urduText.copyWith(color: AppColors.text)
                            : AppText.translation
                                .copyWith(color: AppColors.text),
                      );
                    }),
                  )
                else
                  Text(
                    S.noTranslationAvailable,
                    style: AppText.caption.copyWith(color: AppColors.textFaint),
                  ),
                const SizedBox(height: 14),
                if (it.text.trim().isNotEmpty)
                  OutlinedButton.icon(
                    onPressed: _speak,
                    icon: Icon(_speaking ? Icons.stop : Icons.volume_up_outlined,
                        size: 17),
                    label:
                        Text(_speaking ? S.stopWord : S.listenToTranslation),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.emerald,
                      side: const BorderSide(color: AppColors.goldRule),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4)),
                      textStyle: AppText.body,
                    ),
                  ),
                const SizedBox(height: 20),
                const DiamondRule(),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _index > 0 ? () => _step(-1) : null,
                        icon: const Icon(Icons.chevron_left, size: 18),
                        label: Text(S.previousWord),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.emerald,
                          side: const BorderSide(color: AppColors.goldRule),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(4)),
                          textStyle: AppText.caption,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _index >= 0 && _index < _ordered.length - 1
                            ? () => _step(1)
                            : null,
                        icon: const Icon(Icons.chevron_right, size: 18),
                        label: Text(S.nextWord),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.emerald,
                          side: const BorderSide(color: AppColors.goldRule),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(4)),
                          textStyle: AppText.caption,
                        ),
                      ),
                    ),
                  ],
                ),
                if (ch != null) ...[
                  const SizedBox(height: 10),
                  TextButton.icon(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => HadithListScreen(
                          collection: widget.collection,
                          chapter: ch,
                          bookKey: widget.bookKey,
                          language: widget.language,
                          highlightHadithNumber: _number,
                        ),
                      ),
                    ),
                    icon: const Icon(Icons.list_alt_outlined, size: 17),
                    label: Text('${S.readWholeChapter}: ${ch.title}'),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.emerald,
                      textStyle: AppText.caption,
                    ),
                  ),
                ],
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
