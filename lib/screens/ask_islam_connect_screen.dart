import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/hadith.dart';
import '../data/daily_hadith.dart';
import '../data/daily_quran_ayah.dart';
import '../services/ask_connect_search.dart';
import '../services/ask_connect_ai.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/ask_connect_voice.dart';
import '../services/ask_roman_text.dart';
import '../services/hadith_link.dart';
import '../services/quran_repository.dart';
import '../services/tts_service.dart';
import '../theme/app_theme.dart';
import 'surah_detail_screen.dart';
import 'prophet_story_reader_screen.dart';
import '../services/prophet_stories_repository.dart';

class AskIslamConnectScreen extends StatefulWidget {
  const AskIslamConnectScreen({super.key});
  @override
  State<AskIslamConnectScreen> createState() => _AskIslamConnectScreenState();
}

class _AskIslamConnectScreenState extends State<AskIslamConnectScreen>
    with WidgetsBindingObserver {
  final _engine = AskConnectSearch();
  final _query = TextEditingController();
  bool _ready = false, _busy = false, _voiceBusy = false;
  String? _loadError, _searchError;
  String _progress = 'Library tayyar ho rahi hai…';
  String _locale = 'hi-IN', _translation = 'urdu', _kind = 'all';
  String? _speaking;
  bool _aiMode = true, _loadingOffline = false, _confirmingAi = false;
  String? _understood, _aiFollowup, _aiStatus;
  String _aiSpeechUrdu = '', _aiSpeechEnglish = '';
  List<Map<String, dynamic>> _aiParagraphs = [];
  int _searchVersion = 0, _audioVersion = 0, _total = 0;
  String? _searchedQuery;
  List<String> _topics = [];
  List<Map<String, dynamic>> _hits = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  Future<void> _load() async {
    if (_loadingOffline || _ready) return;
    _loadingOffline = true;
    try {
      await _engine.load((message) { if (mounted) setState(() => _progress = message); });
      if (mounted) setState(() => _ready = true);
    } catch (_) {
      if (mounted) setState(() => _loadError = 'Library nahi khul saki. Wapas jaakar dobara kholein.');
    } finally { _loadingOffline = false; }
  }

  void _notice(String text) {
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  Future<void> _stop() async {
    _audioVersion++;
    if (mounted) setState(() => _speaking = null);
    await TtsService.stop();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive || state == AppLifecycleState.paused) _stop();
  }

  Future<void> _listen() async {
    if (_voiceBusy) return;
    setState(() => _voiceBusy = true);
    await _stop();
    if (!mounted) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      if (!(prefs.getBool('ask_voice_provider_notice_v1') ?? false)) {
        if (!mounted) return;
        final agreed = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(
          title: const Text('Voice search'),
          content: const Text('Aapke phone ki speech service awaaz ko text banayegi. '
            'Woh internet aur apne servers use kar sakti hai. Islam Connect audio save nahi karta. '
            'Aap text likhkar bhi search kar sakte hain.'),
          actions: [TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Text likhein')),
            FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Mic kholein'))]));
        if (agreed != true) return;
        await prefs.setBool('ask_voice_provider_notice_v1', true);
      }
      if (!mounted) return;
      final words = await AskConnectVoice.listen(_locale);
      if (!mounted) return;
      if (words != null && words.trim().isNotEmpty) {
        _query.text = askRomanTranscript(words);
        _query.selection = TextSelection.collapsed(offset: _query.text.length);
        // Keep the transcript editable. User confirms search after checking it.
      }
    } on PlatformException catch (e) {
      _notice(e.message ?? 'Voice nahi chali. Apna sawal type karein.');
    } catch (_) {
      _notice('Voice nahi chali. Apna sawal type karein.');
    } finally { if (mounted) setState(() => _voiceBusy = false); }
  }

  Future<void> _search() async {
    if (_busy || _confirmingAi || (!_aiMode && !_ready) || _query.text.trim().isEmpty) return;
    if (_aiMode) {
      _confirmingAi = true;
      try { if (!await _allowAi()) return; } finally { _confirmingAi = false; }
    }
    if (!mounted) return;
    FocusScope.of(context).unfocus();
    await _stop();
    if (!mounted) return;
    final version = ++_searchVersion;
    final query = _query.text.trim();
    setState(() { _busy = true; _hits = []; _searchedQuery = query; _total = 0; _searchError = null; _topics = [];
      _aiParagraphs = []; _understood = null; _aiFollowup = null; _aiStatus = null;
      _aiSpeechUrdu = ''; _aiSpeechEnglish = ''; });
    try {
      final reply = _aiMode ? await AskConnectAi.ask(query, _kind)
          : await _engine.search(query, _kind);
      if (!mounted || version != _searchVersion) return;
      setState(() {
        _hits = (reply['hits'] as List).map((h) => Map<String, dynamic>.from(h as Map)).toList();
        _total = reply['total'] as int? ?? _hits.length;
        _topics = (reply['terms'] as List? ?? []).cast<String>();
        if (_aiMode) {
          _aiParagraphs = (reply['paragraphs'] as List? ?? [])
              .map((p) => Map<String, dynamic>.from(p as Map)).toList();
          _understood = reply['understood'] as String?;
          _aiFollowup = reply['followup'] as String?;
          _aiStatus = reply['status'] as String?;
          _aiSpeechUrdu = reply['speech_urdu'] as String? ?? '';
          _aiSpeechEnglish = reply['speech_english'] as String? ?? '';
        }
      });
    } catch (error) {
      if (mounted && version == _searchVersion) setState(() =>
        _searchError = _aiMode ? _aiError(error) : 'Search poori nahi ho saki. Dobara koshish karein.');
    }
    finally { if (mounted && version == _searchVersion) setState(() => _busy = false); }
  }

  Future<bool> _allowAi() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool('ask_ai_data_notice_v1') == true) return true;
    if (!mounted) return false;
    final allowed = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(
      title: const Text('AI se poochhein'),
      content: const Text('Aapka likha sawal aur related library passages jawab banane ke liye '
        'hamare Firebase server se OpenAI ko bheje jaayenge. Audio, phone number aur location '
        'AI ko nahi bheje jaate. Personal details sawal mein na likhein. '
        'Bina AI ke Library search bhi use kar sakte hain.'),
      actions: [TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Abhi nahi')),
        TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('AI se poochhein'))]));
    if (allowed == true) await prefs.setBool('ask_ai_data_notice_v1', true);
    return allowed == true;
  }

  String _aiError(Object error) {
    if (error is FirebaseAuthException) {
      if (error.code == 'operation-not-allowed' || error.code == 'admin-restricted-operation') {
        return 'AI setup baaki hai: Firebase mein Anonymous sign-in enable karna hai. Library search abhi use kar sakte hain.';
      }
      return 'AI session nahi ban saka. Internet check karein ya Library search use karein.';
    }
    if (error is FirebaseFunctionsException) {
      if (error.code == 'not-found') return 'AI service abhi deploy nahi hui. Library search use karein.';
      if (error.code == 'failed-precondition') return 'AI server ki API key/access setup check karna hai. Library search use karein.';
      if (error.code == 'resource-exhausted') return 'AI ki usage limit aa gayi hai. Baad mein try karein ya Library search use karein.';
    }
    return 'AI se abhi jawab nahi mil saka. Internet check karein, dobara try karein ya Library search chunein.';
  }

  void _mode(bool ai) {
    if (_busy) return;
    _stop();
    setState(() {
      _aiMode = ai; _searchedQuery = null; _hits = []; _aiParagraphs = [];
      _aiFollowup = null; _understood = null; _searchError = null;
    });
    if (!ai) _load();
  }

  Future<void> _speakAnswer() async {
    if (_speaking == 'ai-answer') { await _stop(); return; }
    await _stop();
    if (!mounted) return;
    final token = ++_audioVersion;
    var remaining = _translation == 'urdu' ? _aiSpeechUrdu : _aiSpeechEnglish;
    if (remaining.isEmpty) return;
    setState(() => _speaking = 'ai-answer');
    while (remaining.isNotEmpty && mounted && token == _audioVersion) {
      var end = remaining.length > 2800 ? remaining.lastIndexOf(' ', 2800) : remaining.length;
      if (end < 1) end = remaining.length > 2800 ? 2800 : remaining.length;
      final ok = await TtsService.speak(remaining.substring(0, end),
        _translation == 'urdu' ? TtsLang.urdu : TtsLang.english);
      if (!mounted || token != _audioVersion) return;
      if (!ok) { _notice('Is zaban ki voice available nahi. English chunein ya TTS language install karein.'); break; }
      remaining = remaining.substring(end).trimLeft();
    }
    if (mounted && token == _audioVersion) setState(() => _speaking = null);
  }

  Widget _answerCard() => Card(
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22),
      side: BorderSide(color: AppColors.goldRule)),
    child: Padding(padding: const EdgeInsets.all(20), child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Text('Aasaan jawab · AI', style: AppText.rowTitle.copyWith(fontSize: 22)),
        const SizedBox(height: 14),
        for (final p in _aiParagraphs) ...[
          Text(p['text'] as String, style: AppText.body.copyWith(fontSize: 18, height: 1.7)),
          Wrap(spacing: 6, children: (p['source_ids'] as List).map((id) {
            final sources = _hits.where((h) => h['id'] == id);
            if (sources.isEmpty) return const SizedBox.shrink();
            final source = sources.first;
            return ActionChip(label: Text(_reference(source)),
              avatar: const Icon(Icons.menu_book_outlined, size: 16), onPressed: () => _open(source));
          }).toList()),
          const SizedBox(height: 12),
        ],
        if (_aiParagraphs.isNotEmpty) TextButton.icon(onPressed: _speakAnswer,
          icon: Icon(_speaking == 'ai-answer' ? Icons.stop_circle_outlined : Icons.volume_up_outlined),
          label: Text(_speaking == 'ai-answer' ? 'Rokein' : _translation == 'urdu' ? 'Jawab Urdu mein sunein' : 'Jawab English mein sunein')),
        if (_aiFollowup?.isNotEmpty == true) Text(_aiFollowup!, style: AppText.body),
        const SizedBox(height: 8),
        Text('AI ki aasaan wazahat hai; asal references bhi parhein. Ikhtilafi masail mein qualified aalim se tasdeeq karein.',
          style: AppText.caption.copyWith(color: AppColors.textMuted)),
      ])));

  String _id(Map<String, dynamic> h) => '${h['kind']}:${h['storyId'] ?? h['book'] ?? h['surah']}:${h['number']}';
  String _body(Map<String, dynamic> h) => h['kind'] == 'story'
      ? (h[_translation == 'urdu' ? 'roman' : 'en'] as String? ?? '')
      : (h[_translation == 'urdu' ? 'ur' : 'en'] as String? ?? '');
  String _reference(Map<String, dynamic> h) => h['kind'] == 'story'
      ? '${h['title']} · ${h['chapter']}' : h['kind'] == 'quran'
      ? 'Quran · ${h['title']} ${h['surah']}:${h['number']}'
      : '${h['title']} · Hadith ${h['number']}';

  Future<void> _speak(Map<String, dynamic> h, {bool meaning = false}) async {
    final id = _id(h);
    if (_speaking == id) { await _stop(); return; }
    await _stop();
    final version = ++_audioVersion;
    final text = h['kind'] == 'story' ? h['en'] as String
        : meaning ? (_meaningAudio(h) ?? '') : _body(h);
    if (text.trim().isEmpty) { _notice('Is zaban mein translation available nahi.'); return; }
    if (!mounted) return;
    setState(() => _speaking = id);
    bool ok = true;
    var remaining = text;
    while (remaining.isNotEmpty && mounted && version == _audioVersion) {
      var end = remaining.length > 3000 ? remaining.lastIndexOf(' ', 3000) : remaining.length;
      if (end < 1) end = remaining.length > 3000 ? 3000 : remaining.length;
      ok = await TtsService.speak(remaining.substring(0, end),
        _translation == 'urdu' && h['kind'] != 'story' ? TtsLang.urdu : TtsLang.english);
      if (!ok) break;
      remaining = remaining.substring(end).trimLeft();
    }
    if (!mounted || version != _audioVersion) return;
    setState(() => _speaking = null);
    if (!ok) _notice('Is zaban ki voice phone mein available nahi. TTS language install karein ya English chunein.');
  }

  Future<void> _open(Map<String, dynamic> h) async {
    await _stop();
    if (!mounted) return;
    if (h['kind'] == 'story') {
      try {
        final books = await ProphetStoriesRepository.load();
        final story = books.firstWhere((b) => b.id == h['storyId']);
        final page = story.pages.indexWhere((p) => p.id == h['pageId']);
        if (!mounted) return;
        await Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) =>
          ProphetStoryReaderScreen(story: story, initialPage: page < 0 ? 0 : page)));
      } catch (_) { _notice('Story nahi khul saki. Dobara koshish karein.'); }
    } else if (h['kind'] == 'hadith') {
      await HadithLink.open(context, HadithRef(
        book: HadithBook.values.firstWhere((b) => b.fileKey == h['book']), number: h['number'] as int),
        language: _translation == 'urdu' ? HadithLanguage.urdu : HadithLanguage.english);
    } else {
      try {
        final surahs = await QuranRepository.loadSurahs(
          _translation == 'urdu' ? QuranLanguage.urdu : QuranLanguage.english);
        final surah = surahs.firstWhere((s) => s.number == h['surah']);
        if (!mounted) return;
        await Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) =>
          SurahDetailScreen(surah: surah, initialVerse: h['number'] as int)));
      } catch (_) { _notice('Ayat nahi khul saki. Dobara koshish karein.'); }
    }
  }

  String? _meaning(Map<String, dynamic> h) {
    if (h['kind'] == 'quran') {
      for (final a in DailyQuranAyah.all) {
        if (a.surah == h['surah'] && a.ayah == h['number']) return a.roman;
      }
    } else {
      for (final a in DailyHadith.all) {
        if (a.book.fileKey == h['book'] && a.number == h['number']) return a.textHi;
      }
    }
    return null;
  }

  String? _meaningAudio(Map<String, dynamic> h) {
    if (h['kind'] == 'quran') {
      for (final a in DailyQuranAyah.all) {
        if (a.surah == h['surah'] && a.ayah == h['number']) {
          return _translation == 'urdu' ? a.urdu : a.english;
        }
      }
    } else {
      for (final a in DailyHadith.all) {
        if (a.book.fileKey == h['book'] && a.number == h['number']) {
          return _translation == 'urdu' ? a.textUr : a.text;
        }
      }
    }
    return null;
  }

  Future<void> _details(Map<String, dynamic> h) async {
    await _stop();
    if (!mounted) return;
    await showModalBottomSheet<void>(context: context, isScrollControlled: true,
      builder: (ctx) => SafeArea(child: Padding(padding: const EdgeInsets.all(22),
        child: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(_meaning(h) == null ? 'Reference aur wazahat' : 'Aasaan matlab', style: AppText.rowTitle),
            const SizedBox(height: 12), Text(_reference(h)), const SizedBox(height: 12),
            if (_meaning(h) != null) ...[
              Text(_meaning(h)!, style: AppText.body.copyWith(fontSize: 18)),
              TextButton.icon(onPressed: () => _speak(h, meaning: true),
                icon: const Icon(Icons.volume_up_outlined),
                label: Text(_translation == 'urdu' ? 'Urdu mafoom sunein' : 'English meaning sunein')),
              TextButton.icon(onPressed: _stop, icon: const Icon(Icons.stop_circle_outlined),
                label: const Text('Rokein')),
              const SizedBox(height: 8),
              const Text('Roman Urdu mein pehle se likha mukhtasar mafoom; poori riwayat ka tafsir ya fatwa nahi.'),
              const SizedBox(height: 12),
            ],
            if (_meaning(h) == null) const Text('Yeh database se mili related riwayat/ayat hai; search result final fatwa nahi. '
              'Is reference ka reviewed aasaan explanation abhi available nahi. '
              'Asal translation parhein; ikhtilafi masail mein qualified aalim se poochhein.'),
            const SizedBox(height: 12),
            for (final grade in (h['grades'] as List)) Padding(
              padding: const EdgeInsets.only(bottom: 8), child: Text('Source grading: $grade')),
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Band karein')),
          ])))));
    await _stop();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _searchVersion++; _audioVersion++;
    TtsService.stop(); _engine.dispose(); _query.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Ask Islam Connect')),
    body: ListView(padding: const EdgeInsets.all(20), children: [
      Container(padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(color: AppColors.goldRule.withOpacity(.25),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.goldRule)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(Icons.auto_awesome_outlined, color: AppColors.gold, size: 28),
          const SizedBox(height: 12),
          Text('Har sawal, ilm ki taraf ek qadam',
            style: AppText.rowTitle.copyWith(fontSize: 25, height: 1.35)),
          const SizedBox(height: 8),
          const Text('Poora sawal boliye ya likhiye. Jaise: Namaz mein haath kahan baandhna chahiye?'),
        ])),
      const SizedBox(height: 6),
      const Text('Quran, hadees aur Prophet Stories mein talaash karein. Parhein, sunein aur asal reference kholein.'),
      const SizedBox(height: 14),
      Wrap(spacing: 10, children: [
        ChoiceChip(label: const Text('AI jawab'), selected: _aiMode,
          onSelected: _busy ? null : (_) => _mode(true)),
        ChoiceChip(label: const Text('Library search'), selected: !_aiMode,
          onSelected: _busy ? null : (_) => _mode(false)),
      ]),
      const SizedBox(height: 18),
      Row(children: [Expanded(child: DropdownButtonFormField<String>(value: _locale,
        decoration: const InputDecoration(labelText: 'Bolne ki zaban', border: OutlineInputBorder()),
        items: const [DropdownMenuItem(value: 'hi-IN', child: Text('Hinglish (Hindi voice)')),
          DropdownMenuItem(value: 'ur-PK', child: Text('Urdu')),
          DropdownMenuItem(value: 'en-IN', child: Text('English'))],
        onChanged: _voiceBusy ? null : (v) => setState(() => _locale = v!))),
        const SizedBox(width: 12),
        Semantics(label: 'Apna sawal boliye', button: true, child: SizedBox(width: 64, height: 64,
          child: FilledButton(style: FilledButton.styleFrom(backgroundColor: AppColors.goldRule.withOpacity(.45),
            foregroundColor: AppColors.text,
            padding: EdgeInsets.zero, shape: const CircleBorder()),
            onPressed: _voiceBusy ? null : _listen,
            child: Icon(_voiceBusy ? Icons.hearing : Icons.mic, size: 30))))]),
      const SizedBox(height: 8),
      const Text('Hindi voice ka sawal Roman / Hinglish mein dikhega. Zaroorat ho to text edit karein.'),
      const SizedBox(height: 16),
      TextField(controller: _query, maxLength: 250, minLines: 1, maxLines: 3,
        textInputAction: TextInputAction.search, onSubmitted: (_) => _search(),
        decoration: const InputDecoration(labelText: 'Sawal likhein ya boliye',
          hintText: 'Namaz mein haath kahan baandhna chahiye?', prefixIcon: Icon(Icons.search),
          border: OutlineInputBorder())),
      FilledButton.icon(style: FilledButton.styleFrom(backgroundColor: AppColors.goldRule.withOpacity(.45),
        foregroundColor: AppColors.text,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        minimumSize: const Size.fromHeight(50)),
        onPressed: (_aiMode || _ready) && !_busy ? _search : null,
        icon: const Icon(Icons.search), label: Text(_aiMode ? 'AI se poochhein' : 'Talaash karein')),
      const SizedBox(height: 12),
      Wrap(spacing: 8, children: ['Namaz mein haath kahan baandhein?', 'Namaz mein ungli hilane ka hukm?', 'Yusuf alayhis salam ki kahani batao', 'Zamzam ka waqia batao'].map((q) =>
        ActionChip(label: Text(q), onPressed: (!_aiMode && !_ready) || _busy ? null : () { _query.text = q; _search(); })).toList()),
      const SizedBox(height: 12),
      Wrap(spacing: 8, children: [('all', 'Sab'), ('quran', 'Quran'), ('hadith', 'Hadees'), ('story', 'Stories')].map((v) =>
        ChoiceChip(label: Text(v.$2), selected: _kind == v.$1,
          onSelected: _busy ? null : (_) { setState(() => _kind = v.$1); if (_searchedQuery != null) _search(); })).toList()),
      const SizedBox(height: 8),
      DropdownButtonFormField<String>(value: _translation,
        decoration: const InputDecoration(labelText: 'Translation aur sunne ki zaban'),
        items: const [DropdownMenuItem(value: 'urdu', child: Text('Urdu')),
          DropdownMenuItem(value: 'english', child: Text('English'))],
        onChanged: (v) { _stop(); setState(() => _translation = v!); }),
      const SizedBox(height: 20),
      if (!_aiMode && _loadError != null) Text(_loadError!, style: const TextStyle(color: Colors.red)),
      if (!_aiMode && !_ready && _loadError == null) ...[const LinearProgressIndicator(),
        const SizedBox(height: 8), Text(_progress)],
      if (_busy) Column(children: [const CircularProgressIndicator(),
        const SizedBox(height: 10), Text(_aiMode ? 'Sawal samajhkar references se jawab tayyar ho raha hai…' : 'Talaash ho rahi hai…')]),
      if (_aiMode && !_busy && _searchedQuery == null)
        const Text('Poora sawal poochhein. AI app ki library se references lekar aasaan jawab dega. Internet zaroori hai.'),
      if (!_aiMode && _ready && !_busy && _searchedQuery == null)
        Text('${_engine.count} references tayyar. Apna sawal likhein; phir Talaash karein.'),
      if (_searchError != null && !_busy) ...[
        Text(_searchError!),
        TextButton(onPressed: _search, child: const Text('Dobara talaash karein')),
      ],
      if (_searchedQuery != null && !_busy && _searchError == null) ...[
        Text('“$_searchedQuery” · $_total related references${_total > 40 ? ' · pehle 40 dikh rahe hain' : ''}',
          style: AppText.caption),
        const SizedBox(height: 10),
        if (_aiMode && _understood?.isNotEmpty == true) Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Text('Aapka sawal: $_understood', style: AppText.body)),
        if (_aiMode && _aiStatus != null) _answerCard(),
        if (_topics.isNotEmpty) Text('Sawal ke topics: ${_topics.join(' · ')}', style: AppText.caption),
        const SizedBox(height: 8),
        if (!_aiMode && _hits.isEmpty) const Padding(padding: EdgeInsets.symmetric(vertical: 18),
          child: Text('Is sawal ka related reference abhi nahi mila. Voice ka likha sawal check karein ya isi baat ko doosre alfaaz mein poochhein. '
            'Library search har sawal ka jawab nahi de sakti; koi jawab banaya nahi jaayega.')),
        ..._hits.map(_result),
      ],
    ]));

  Widget _result(Map<String, dynamic> h) {
    final urdu = _translation == 'urdu' && h['kind'] != 'story';
    final text = _body(h);
    return Card(margin: const EdgeInsets.only(bottom: 16), shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(20), side: BorderSide(color: AppColors.goldRule)),
      child: Padding(padding: const EdgeInsets.all(18), child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Text(h['kind'] == 'story' ? 'PROPHET STORY' : h['kind'] == 'quran' ? 'QURAN AYAT' : 'HADEES',
            style: AppText.caption.copyWith(color: AppColors.emerald, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8), Text(_reference(h), style: AppText.rowTitle),
          if ((h['ar'] as String).isNotEmpty) Padding(padding: const EdgeInsets.symmetric(vertical: 12),
            child: Text(h['ar'] as String, maxLines: 3, overflow: TextOverflow.ellipsis,
              textDirection: TextDirection.rtl, style: AppText.arabic.copyWith(fontSize: 22))),
          Text(text.isEmpty ? 'Is zaban mein translation available nahi.' : text,
            maxLines: 5, overflow: TextOverflow.ellipsis,
            textDirection: urdu ? TextDirection.rtl : TextDirection.ltr,
            style: urdu ? AppText.urduText.copyWith(fontSize: 18, height: 2) : AppText.body),
          const SizedBox(height: 8),
          Wrap(spacing: 8, runSpacing: 4, children: [
            TextButton.icon(onPressed: text.isEmpty ? null : () => _speak(h),
              icon: Icon(_speaking == _id(h) ? Icons.stop_circle_outlined : Icons.volume_up_outlined),
              label: Text(_speaking == _id(h) ? 'Rokein' : h['kind'] == 'story' ? 'English mein sunein' : 'Sunein')),
            TextButton.icon(onPressed: () => _open(h), icon: const Icon(Icons.menu_book_outlined),
              label: Text(h['kind'] == 'story' ? 'Poori story parhein' : 'Poora parhein')),
            if (h['kind'] != 'story') TextButton(onPressed: () => _details(h),
              child: Text(_meaning(h) == null ? 'Reference / wazahat' : 'Aasaan matlab')),
          ]),
        ])));
  }
}
