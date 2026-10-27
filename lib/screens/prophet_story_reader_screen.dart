import 'package:flutter/material.dart';
import '../models/prophet_story.dart';
import '../models/hadith.dart';
import '../services/hadith_link.dart';
import '../services/prophet_stories_repository.dart';
import '../services/quran_repository.dart';
import '../services/tts_service.dart';
import '../theme/app_theme.dart';
import '../services/app_strings.dart';
import 'surah_detail_screen.dart';

class ProphetStoryReaderScreen extends StatefulWidget {
  const ProphetStoryReaderScreen(
      {super.key, required this.story, this.initialPage = 0});
  final ProphetStory story;
  final int initialPage;
  @override
  State<ProphetStoryReaderScreen> createState() =>
      _ProphetStoryReaderScreenState();
}

class _ProphetStoryReaderScreenState extends State<ProphetStoryReaderScreen>
    with WidgetsBindingObserver {
  final _scroll = ScrollController();
  final _viewport = GlobalKey();
  late final List<GlobalKey> _chapters;
  bool _jumping = false;
  late int _page;
  bool _english = false, _speaking = false, _opening = false;
  int _audioVersion = 0;
  Future<void> _saveQueue = Future<void>.value();
  ProphetStory get _story => widget.story;
  @override
  void initState() {
    super.initState();
    _english = !S.isUrdu;
    WidgetsBinding.instance.addObserver(this);
    _page = widget.initialPage.clamp(0, _story.pages.length - 1).toInt();
    _chapters = List.generate(_story.pages.length, (_) => GlobalKey());
    _scroll.addListener(_trackChapter);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _page > 0) _go(_page, animate: false);
    });
    _save();
  }

  void _notice(String text) {
    if (mounted)
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  void _save({bool completed = false}) {
    final pageId = _story.pages[_page].id;
    _saveQueue = _saveQueue
        .then((_) =>
            ProphetStoryProgress.save(_story.id, pageId, completed: completed))
        .catchError((Object _) {
      _notice(S.tr('Could not save reading progress.',
          'پڑھنے کی پیش رفت محفوظ نہیں ہو سکی۔'));
    });
  }

  Future<void> _stop() async {
    _audioVersion++;
    if (mounted) setState(() => _speaking = false);
    await TtsService.stop();
  }

  Future<void> _listen() async {
    if (_speaking) {
      await _stop();
      return;
    }
    final token = ++_audioVersion;
    setState(() => _speaking = true);
    final available = await TtsService.isAvailable(TtsLang.english);
    if (!mounted || token != _audioVersion) return;
    final ok = available &&
        await TtsService.speak(_story.pages[_page].english, TtsLang.english);
    if (!mounted || token != _audioVersion) return;
    setState(() => _speaking = false);
    if (!ok)
      _notice(S.tr(
          'English voice is unavailable. Check your phone’s speech settings.',
          'انگریزی آواز دستیاب نہیں۔ فون کی صوتی ترتیبات دیکھیں۔'));
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused) _stop();
  }

  Future<void> _source(ProphetStorySource source) async {
    if (_opening) return;
    setState(() => _opening = true);
    await _stop();
    if (!mounted) return;
    try {
      if (source.kind == 'hadith') {
        await HadithLink.open(
            context,
            HadithRef(
                book: source.book == 'muslim'
                    ? HadithBook.muslim
                    : HadithBook.bukhari,
                number: source.number!),
            language: _english ? HadithLanguage.english : HadithLanguage.urdu);
      } else {
        final surahs = await QuranRepository.loadSurahs(
            _english ? QuranLanguage.english : QuranLanguage.urdu);
        final surah = surahs.firstWhere((s) => s.number == source.surah);
        if (!mounted) return;
        await Navigator.of(context).push(MaterialPageRoute<void>(
            builder: (_) =>
                SurahDetailScreen(surah: surah, initialVerse: source.start!)));
      }
    } catch (_) {
      _notice(S.tr('Could not open this reference. Please try again.',
          'حوالہ نہیں کھل سکا۔ دوبارہ کوشش کریں۔'));
    } finally {
      if (mounted) setState(() => _opening = false);
    }
  }

  void _trackChapter() {
    if (_jumping || !mounted) return;
    final viewport = _viewport.currentContext?.findRenderObject();
    if (viewport is! RenderBox || !viewport.hasSize) return;
    final readingLine =
        viewport.localToGlobal(Offset.zero).dy + viewport.size.height * .3;
    var visible = 0;
    for (var i = 0; i < _chapters.length; i++) {
      final box = _chapters[i].currentContext?.findRenderObject();
      if (box is RenderBox &&
          box.hasSize &&
          box.localToGlobal(Offset.zero).dy <= readingLine) visible = i;
    }
    if (_page != visible) {
      _stop();
      setState(() => _page = visible);
      _save();
    }
  }

  Future<void> _go(int index, {bool animate = true}) async {
    if (index < 0 || index >= _story.pages.length || _jumping) return;
    final target = _chapters[index].currentContext;
    if (target == null) return;
    _jumping = true;
    await _stop();
    if (!mounted) return;
    try {
      await Scrollable.ensureVisible(target,
          alignment: 0,
          duration: animate ? const Duration(milliseconds: 300) : Duration.zero,
          curve: Curves.easeOut);
      if (mounted) {
        setState(() => _page = index);
        _save();
      }
    } finally {
      _jumping = false;
    }
  }

  void _language(bool english) {
    final chapter = _page;
    _stop();
    setState(() => _english = english);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _go(chapter, animate: false);
    });
  }

  Future<void> _contents() async {
    await _stop();
    if (!mounted) return;
    final selected = await showModalBottomSheet<int>(
        context: context,
        isScrollControlled: true,
        builder: (ctx) => SafeArea(
            child: SizedBox(
                height: MediaQuery.of(ctx).size.height * .72,
                child: Column(children: [
                  Padding(
                      padding: const EdgeInsets.all(20),
                      child: Text('Chapters · ${_story.name}',
                          style: AppText.rowTitle)),
                  Expanded(
                      child: ListView.builder(
                          itemCount: _story.pages.length,
                          itemBuilder: (ctx, i) => ListTile(
                              selected: i == _page,
                              leading: Text('${i + 1}'),
                              title: Text(_english &&
                                      _story.pages[i].titleEnglish.isNotEmpty
                                  ? _story.pages[i].titleEnglish
                                  : _story.pages[i].title),
                              trailing: i == _page
                                  ? const Icon(Icons.bookmark)
                                  : null,
                              onTap: () => Navigator.pop(ctx, i)))),
                ]))));
    if (selected != null && mounted) _go(selected);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _audioVersion++;
    TtsService.stop();
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => WillPopScope(
      onWillPop: () async {
        await _stop();
        await _saveQueue;
        return true;
      },
      child: Scaffold(
        appBar: AppBar(title: Text(_story.name), actions: [
          IconButton(
              onPressed: _contents,
              tooltip: S.tr('Chapters', 'ابواب'),
              icon: const Icon(Icons.list_alt)),
        ]),
        body: Column(children: [
          Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              child: Row(children: [
                Expanded(
                    child: Wrap(spacing: 8, children: [
                  ChoiceChip(
                      label: const Text('Roman Urdu'),
                      selected: !_english,
                      onSelected: (_) => _language(false)),
                  ChoiceChip(
                      label: const Text('English'),
                      selected: _english,
                      onSelected: (_) => _language(true)),
                ])),
                Text('${_page + 1} / ${_story.pages.length}',
                    style: AppText.caption),
              ])),
          const SizedBox(height: 8),
          LinearProgressIndicator(
              value: (_page + 1) / _story.pages.length,
              color: AppColors.gold,
              backgroundColor: AppColors.goldRule),
          Expanded(
              child: SingleChildScrollView(
                  key: _viewport,
                  controller: _scroll,
                  padding: const EdgeInsets.only(bottom: 30),
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Padding(
                            padding: const EdgeInsets.all(18),
                            child: Text(
                                _english
                                    ? 'Read the story continuously. Scroll down to keep reading.'
                                    : 'Kahani lagataar parhein. Agla hissa neeche scroll karne par milega.',
                                style: AppText.caption
                                    .copyWith(color: AppColors.textMuted))),
                        for (var i = 0; i < _story.pages.length; i++)
                          _chapter(i),
                      ]))),
          SafeArea(
              top: false,
              child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 6, 14, 10),
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    TextButton.icon(
                        onPressed: _listen,
                        icon: Icon(_speaking
                            ? Icons.stop_circle_outlined
                            : Icons.volume_up_outlined),
                        label: Text(_speaking
                            ? S.tr('Stop Audio', 'آواز بند کریں')
                            : S.tr('Listen in English', 'انگریزی میں سنیں'))),
                    Row(children: [
                      Expanded(
                          child: OutlinedButton(
                              onPressed:
                                  _page == 0 ? null : () => _go(_page - 1),
                              child: Text(
                                  _english ? 'Previous' : 'Pichhla Hissa'))),
                      const SizedBox(width: 12),
                      Expanded(
                          child: FilledButton(
                              style: FilledButton.styleFrom(
                                  backgroundColor:
                                      AppColors.goldRule.withOpacity(.5),
                                  foregroundColor: AppColors.text),
                              onPressed: () async {
                                if (_page < _story.pages.length - 1) {
                                  await _go(_page + 1);
                                  return;
                                }
                                await _stop();
                                _save(completed: true);
                                await _saveQueue;
                                if (mounted) Navigator.of(context).pop();
                              },
                              child: Text(_page == _story.pages.length - 1
                                  ? (_english ? 'Finish' : 'Mukammal')
                                  : (_english ? 'Next' : 'Agla Hissa')))),
                    ]),
                  ]))),
        ]),
      ));

  Widget _chapter(int i) {
    final p = _story.pages[i];
    final opening = _english ? _story.openingEnglish : _story.openingRoman;
    return Padding(
        key: _chapters[i],
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
        child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Stack(children: [
              // The complete scene remains visible at its original ratio. The same
              // scene softly continues behind long text; no fixed-height text box.
              Positioned.fill(
                  child: Image.asset(p.image,
                      fit: BoxFit.cover,
                      cacheWidth: 900,
                      excludeFromSemantics: true,
                      errorBuilder: (_, __, ___) =>
                          const ColoredBox(color: Color(0xFF172A2B)))),
              Positioned.fill(
                  child: ColoredBox(color: Colors.black.withOpacity(.76))),
              Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                AspectRatio(
                    aspectRatio: 1.5,
                    child: Stack(fit: StackFit.expand, children: [
                      Image.asset(p.image,
                          fit: BoxFit.contain,
                          cacheWidth: 900,
                          excludeFromSemantics: true,
                          errorBuilder: (_, __, ___) =>
                              const ColoredBox(color: Color(0xFF172A2B))),
                      const DecoratedBox(
                          decoration: BoxDecoration(
                              gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                            Colors.transparent,
                            Color(0xEA101B1D)
                          ]))),
                      Positioned(
                          left: 22,
                          right: 22,
                          bottom: 24,
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                    '${i + 1} / ${_story.pages.length} · ${_story.name}',
                                    style: const TextStyle(
                                        fontFamily: 'Inter',
                                        color: Color(0xFFF0D492),
                                        fontSize: 12,
                                        height: 1.5)),
                                const SizedBox(height: 8),
                                Text(
                                    _english && p.titleEnglish.isNotEmpty
                                        ? p.titleEnglish
                                        : p.title,
                                    style: const TextStyle(
                                        fontFamily: 'Inter',
                                        color: Colors.white,
                                        fontSize: 20,
                                        height: 1.35,
                                        fontWeight: FontWeight.w600)),
                              ])),
                    ])),
                Padding(
                    padding: const EdgeInsets.fromLTRB(22, 0, 22, 24),
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (i == 0 && opening.isNotEmpty) ...[
                            Text(opening,
                                style: const TextStyle(
                                    fontFamily: 'Inter',
                                    color: Color(0xFFF0D492),
                                    fontSize: 14,
                                    height: 1.65)),
                            const SizedBox(height: 20),
                          ],
                          Text(_english ? p.english : p.roman,
                              style: const TextStyle(
                                  fontFamily: 'Inter',
                                  color: Colors.white,
                                  fontSize: 14,
                                  height: 1.7)),
                          const SizedBox(height: 20),
                          Theme(
                              data: Theme.of(context)
                                  .copyWith(dividerColor: Colors.transparent),
                              child: ExpansionTile(
                                  tilePadding: EdgeInsets.zero,
                                  collapsedIconColor: const Color(0xFFF0D492),
                                  iconColor: const Color(0xFFF0D492),
                                  title: Text(
                                      _english
                                          ? 'Sources and notes'
                                          : 'References aur tafseel',
                                      style: const TextStyle(
                                          color: Color(0xFFF0D492),
                                          fontSize: 13)),
                                  children: [
                                    if ((_english
                                            ? p.noteEnglish
                                            : p.noteRoman) !=
                                        null)
                                      Text(
                                          (_english
                                              ? p.noteEnglish
                                              : p.noteRoman)!,
                                          style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 13,
                                              height: 1.7)),
                                    if (i == 0)
                                      Text(
                                          _english
                                              ? _story.birthNoteEnglish
                                              : _story.birthNote,
                                          style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 13,
                                              height: 1.7)),
                                    for (final source in p.sources)
                                      Align(
                                          alignment:
                                              AlignmentDirectional.centerStart,
                                          child: TextButton.icon(
                                              style: TextButton.styleFrom(
                                                  foregroundColor:
                                                      const Color(0xFFF0D492)),
                                              icon: const Icon(
                                                  Icons.open_in_new,
                                                  size: 15),
                                              label: Text(source.label),
                                              onPressed: _opening
                                                  ? null
                                                  : () => _source(source))),
                                    if (_opening)
                                      const LinearProgressIndicator(),
                                  ])),
                        ])),
              ]),
            ])));
  }
}
