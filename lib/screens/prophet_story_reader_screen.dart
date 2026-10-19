import 'package:flutter/material.dart';
import '../models/prophet_story.dart';
import '../models/hadith.dart';
import '../services/hadith_link.dart';
import '../services/prophet_stories_repository.dart';
import '../services/quran_repository.dart';
import '../services/tts_service.dart';
import '../theme/app_theme.dart';
import 'surah_detail_screen.dart';

class ProphetStoryReaderScreen extends StatefulWidget {
  const ProphetStoryReaderScreen({super.key, required this.story, this.initialPage = 0});
  final ProphetStory story;
  final int initialPage;
  @override
  State<ProphetStoryReaderScreen> createState() => _ProphetStoryReaderScreenState();
}
class _ProphetStoryReaderScreenState extends State<ProphetStoryReaderScreen>
    with WidgetsBindingObserver {
  late final PageController _controller;
  late int _page;
  bool _english = false, _speaking = false, _opening = false;
  int _audioVersion = 0;
  Future<void> _saveQueue = Future<void>.value();
  ProphetStory get _story => widget.story;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _page = widget.initialPage.clamp(0, _story.pages.length - 1).toInt();
    _controller = PageController(initialPage: _page);
    _save();
  }
  void _notice(String text) {
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }
  void _save({bool completed = false}) {
    final pageId = _story.pages[_page].id;
    _saveQueue = _saveQueue.then((_) => ProphetStoryProgress.save(
      _story.id, pageId, completed: completed)).catchError((Object _) {
        _notice('Reading progress save nahi ho saka.');
      });
  }
  Future<void> _stop() async {
    _audioVersion++;
    if (mounted) setState(() => _speaking = false);
    await TtsService.stop();
  }
  Future<void> _listen() async {
    if (_speaking) { await _stop(); return; }
    final token = ++_audioVersion;
    setState(() => _speaking = true);
    final available = await TtsService.isAvailable(TtsLang.english);
    if (!mounted || token != _audioVersion) return;
    final ok = available && await TtsService.speak(_story.pages[_page].english, TtsLang.english);
    if (!mounted || token != _audioVersion) return;
    setState(() => _speaking = false);
    if (!ok) _notice('English voice available nahi. Phone ki TTS settings check karein.');
  }
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive || state == AppLifecycleState.paused) _stop();
  }
  Future<void> _source(ProphetStorySource source) async {
    if (_opening) return;
    setState(() => _opening = true);
    await _stop();
    if (!mounted) return;
    try {
      if (source.kind == 'hadith') {
        await HadithLink.open(context, HadithRef(book: source.book == 'muslim' ? HadithBook.muslim : HadithBook.bukhari,
          number: source.number!), language: _english ? HadithLanguage.english : HadithLanguage.urdu);
      } else {
        final surahs = await QuranRepository.loadSurahs(
          _english ? QuranLanguage.english : QuranLanguage.urdu);
        final surah = surahs.firstWhere((s) => s.number == source.surah);
        if (!mounted) return;
        await Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) =>
          SurahDetailScreen(surah: surah, initialVerse: source.start!)));
      }
    } catch (_) { _notice('Reference nahi khul saka. Dobara koshish karein.'); }
    finally { if (mounted) setState(() => _opening = false); }
  }
  void _go(int index) {
    if (index < 0 || index >= _story.pages.length) return;
    _controller.animateToPage(index, duration: const Duration(milliseconds: 250), curve: Curves.easeOut);
  }
  Future<void> _contents() async {
    await _stop();
    if (!mounted) return;
    final selected = await showModalBottomSheet<int>(context: context, isScrollControlled: true,
      builder: (ctx) => SafeArea(child: SizedBox(height: MediaQuery.of(ctx).size.height * .72,
        child: Column(children: [
          Padding(padding: const EdgeInsets.all(20), child: Text('Chapters · ${_story.name}', style: AppText.rowTitle)),
          Expanded(child: ListView.builder(itemCount: _story.pages.length,
            itemBuilder: (ctx, i) => ListTile(selected: i == _page,
              leading: Text('${i + 1}'), title: Text(_story.pages[i].title),
              trailing: i == _page ? const Icon(Icons.bookmark) : null,
              onTap: () => Navigator.pop(ctx, i)))),
        ]))));
    if (selected != null && mounted) _go(selected);
  }
  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _audioVersion++; TtsService.stop(); _controller.dispose();
    super.dispose();
  }
  @override
  Widget build(BuildContext context) => WillPopScope(
    onWillPop: () async { await _stop(); await _saveQueue; return true; },
    child: Scaffold(
    appBar: AppBar(title: Text(_story.name), actions: [
      IconButton(onPressed: _contents, tooltip: 'Chapters', icon: const Icon(Icons.list_alt)),
    ]),
    body: Column(children: [
      Padding(padding: const EdgeInsets.symmetric(horizontal: 20), child: Row(children: [
        Expanded(child: Wrap(spacing: 8, children: [
          ChoiceChip(label: const Text('Roman Urdu'), selected: !_english,
            onSelected: (_) { _stop(); setState(() => _english = false); }),
          ChoiceChip(label: const Text('English'), selected: _english,
            onSelected: (_) { _stop(); setState(() => _english = true); }),
        ])),
        Text('${_page + 1} / ${_story.pages.length}', style: AppText.caption),
      ])),
      const SizedBox(height: 8),
      LinearProgressIndicator(value: (_page + 1) / _story.pages.length,
        color: AppColors.emerald, backgroundColor: AppColors.goldRule),
      Expanded(child: PageView.builder(controller: _controller, itemCount: _story.pages.length,
        onPageChanged: (i) { _stop(); setState(() => _page = i); _save(); },
        itemBuilder: (context, i) {
          final p = _story.pages[i];
          return SingleChildScrollView(key: PageStorageKey(p.id),
            padding: const EdgeInsets.only(bottom: 24), child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                AspectRatio(aspectRatio: 1.5, child: Image.asset(p.image,
                  fit: BoxFit.cover, cacheWidth: 1200,
                  semanticLabel: 'Artistic environment: ${p.title}. No people or animals.',
                  errorBuilder: (_, __, ___) => Container(color: AppColors.goldRule,
                    child: const Center(child: Icon(Icons.landscape_outlined, size: 48))))),
                Padding(padding: const EdgeInsets.fromLTRB(22, 22, 22, 0), child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                    Text(p.title, style: AppText.rowTitle.copyWith(fontSize: 25, height: 1.3)),
                    const SizedBox(height: 16),
                    Text(_english ? p.english : p.roman,
                      style: AppText.body.copyWith(fontSize: 19, height: 1.85)),
                    const SizedBox(height: 16),
                    if (i == 0) ...[
                      Container(padding: const EdgeInsets.all(14), decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14), color: AppColors.goldRule.withOpacity(.3)),
                        child: Text(_english ? _story.birthNoteEnglish : _story.birthNote,
                          style: AppText.caption.copyWith(height: 1.65))),
                      const SizedBox(height: 16),
                    ],
                    Text(_english ? 'SOURCE REFERENCES' : 'ASAL REFERENCES',
                      style: AppText.caption.copyWith(color: AppColors.emerald,
                        fontWeight: FontWeight.w600)),
                    const SizedBox(height: 6),
                    Wrap(spacing: 8, runSpacing: 4, children: p.sources.map((s) =>
                      ActionChip(avatar: const Icon(Icons.open_in_new, size: 15),
                        label: Text(s.label), onPressed: _opening ? null : () => _source(s))).toList()),
                    if (_opening) const LinearProgressIndicator(),
                    const SizedBox(height: 8),
                    Text(_english ? 'References open at the first verse of a cited range.'
                      : 'Reference range ki pehli ayat par khulega; aage ki ayaat bhi parhein.',
                      style: AppText.caption),
                  ])),
              ]));
        })),
      SafeArea(top: false, child: Padding(padding: const EdgeInsets.fromLTRB(14, 8, 14, 10),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          TextButton.icon(onPressed: _listen,
            icon: Icon(_speaking ? Icons.stop_circle_outlined : Icons.volume_up_outlined),
            label: Text(_speaking ? 'Stop audio' : 'Listen in English')),
          Row(children: [
            Expanded(child: OutlinedButton(onPressed: _page == 0 ? null : () => _go(_page - 1),
              child: const Text('Previous'))),
            const SizedBox(width: 12),
            Expanded(child: FilledButton(style: FilledButton.styleFrom(backgroundColor: AppColors.emerald),
              onPressed: () async {
                if (_page < _story.pages.length - 1) { _go(_page + 1); return; }
                await _stop(); _save(completed: true); await _saveQueue;
                if (mounted) Navigator.of(context).pop();
              }, child: Text(_page == _story.pages.length - 1 ? 'Finish' : 'Next'))),
          ]),
        ]))),
    ])));
}
