import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/hadith.dart';
import '../data/daily_hadith.dart';
import '../data/daily_quran_ayah.dart';
import '../services/ask_connect_search.dart';
import '../services/ask_connect_voice.dart';
import '../services/hadith_link.dart';
import '../services/quran_repository.dart';
import '../services/tts_service.dart';
import '../theme/app_theme.dart';
import 'surah_detail_screen.dart';

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
  String? _loadError;
  String _progress = 'Library tayyar ho rahi hai…';
  String _locale = 'hi-IN', _translation = 'urdu', _kind = 'all';
  String? _speaking;
  int _searchVersion = 0, _audioVersion = 0, _total = 0;
  String? _searchedQuery;
  List<Map<String, dynamic>> _hits = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _load();
  }

  Future<void> _load() async {
    try {
      await _engine.load((message) { if (mounted) setState(() => _progress = message); });
      if (mounted) setState(() => _ready = true);
    } catch (_) {
      if (mounted) setState(() => _loadError = 'Library nahi khul saki. Wapas jaakar dobara kholein.');
    }
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
        _query.text = words;
        // Keep the transcript editable. User confirms search after checking it.
      }
    } on PlatformException catch (e) {
      _notice(e.message ?? 'Voice nahi chali. Apna sawal type karein.');
    } catch (_) {
      _notice('Voice nahi chali. Apna sawal type karein.');
    } finally { if (mounted) setState(() => _voiceBusy = false); }
  }

  Future<void> _search() async {
    if (!_ready || _query.text.trim().isEmpty) return;
    FocusScope.of(context).unfocus();
    await _stop();
    if (!mounted) return;
    final version = ++_searchVersion;
    final query = _query.text.trim();
    setState(() { _busy = true; _hits = []; _searchedQuery = query; _total = 0; });
    try {
      final reply = await _engine.search(query, _kind);
      if (!mounted || version != _searchVersion) return;
      setState(() {
        _hits = (reply['hits'] as List).map((h) => Map<String, dynamic>.from(h as Map)).toList();
        _total = reply['total'] as int;
      });
    } catch (_) { _notice('Search nahi ho saki. Dobara koshish karein.'); }
    finally { if (mounted && version == _searchVersion) setState(() => _busy = false); }
  }

  String _id(Map<String, dynamic> h) => '${h['kind']}:${h['book'] ?? h['surah']}:${h['number']}';
  String _body(Map<String, dynamic> h) => (h[_translation == 'urdu' ? 'ur' : 'en'] as String? ?? '');
  String _reference(Map<String, dynamic> h) => h['kind'] == 'quran'
      ? 'Quran · ${h['title']} ${h['surah']}:${h['number']}'
      : '${h['title']} · Hadith ${h['number']}';

  Future<void> _speak(Map<String, dynamic> h, {bool meaning = false}) async {
    final id = _id(h);
    if (_speaking == id) { await _stop(); return; }
    await _stop();
    final version = ++_audioVersion;
    final text = meaning ? (_meaningAudio(h) ?? '') : _body(h);
    if (text.trim().isEmpty) { _notice('Is zaban mein translation available nahi.'); return; }
    if (!mounted) return;
    setState(() => _speaking = id);
    bool ok = true;
    var remaining = text;
    while (remaining.isNotEmpty && mounted && version == _audioVersion) {
      var end = remaining.length > 3000 ? remaining.lastIndexOf(' ', 3000) : remaining.length;
      if (end < 1) end = remaining.length > 3000 ? 3000 : remaining.length;
      ok = await TtsService.speak(remaining.substring(0, end),
        _translation == 'urdu' ? TtsLang.urdu : TtsLang.english);
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
    if (h['kind'] == 'hadith') {
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
      Text('Apna sawal boliye', style: AppText.rowTitle.copyWith(fontSize: 25)),
      const SizedBox(height: 6),
      const Text('Quran aur hadees mein talaash karein. Parhein, sunein aur asal reference kholein.'),
      const SizedBox(height: 18),
      Row(children: [Expanded(child: DropdownButtonFormField<String>(value: _locale,
        decoration: const InputDecoration(labelText: 'Bolne ki zaban', border: OutlineInputBorder()),
        items: const [DropdownMenuItem(value: 'hi-IN', child: Text('Hindi / Roman Urdu')),
          DropdownMenuItem(value: 'ur-PK', child: Text('Urdu')),
          DropdownMenuItem(value: 'en-IN', child: Text('English'))],
        onChanged: _voiceBusy ? null : (v) => setState(() => _locale = v!))),
        const SizedBox(width: 12),
        Semantics(label: 'Apna sawal boliye', button: true, child: SizedBox(width: 64, height: 64,
          child: FilledButton(style: FilledButton.styleFrom(backgroundColor: AppColors.emerald,
            padding: EdgeInsets.zero, shape: const CircleBorder()),
            onPressed: _voiceBusy ? null : _listen,
            child: Icon(_voiceBusy ? Icons.hearing : Icons.mic, size: 30))))]),
      const SizedBox(height: 16),
      TextField(controller: _query, maxLength: 250, minLines: 1, maxLines: 3,
        textInputAction: TextInputAction.search, onSubmitted: (_) => _search(),
        decoration: const InputDecoration(labelText: 'Sawal likhein ya boliye',
          hintText: 'Jaise: sabr, gussa, namaz mein ungli', prefixIcon: Icon(Icons.search),
          border: OutlineInputBorder())),
      FilledButton.icon(style: FilledButton.styleFrom(backgroundColor: AppColors.emerald,
        minimumSize: const Size.fromHeight(50)),
        onPressed: _ready && !_busy ? _search : null,
        icon: const Icon(Icons.search), label: const Text('Talaash karein')),
      const SizedBox(height: 12),
      Wrap(spacing: 8, children: ['sabr', 'gussa', 'maa', 'namaz mein ungli'].map((q) =>
        ActionChip(label: Text(q), onPressed: !_ready || _busy ? null : () { _query.text = q; _search(); })).toList()),
      const SizedBox(height: 12),
      Wrap(spacing: 8, children: [('all', 'Sab'), ('quran', 'Quran'), ('hadith', 'Hadees')].map((v) =>
        ChoiceChip(label: Text(v.$2), selected: _kind == v.$1,
          onSelected: _busy ? null : (_) { setState(() => _kind = v.$1); if (_searchedQuery != null) _search(); })).toList()),
      const SizedBox(height: 8),
      DropdownButtonFormField<String>(value: _translation,
        decoration: const InputDecoration(labelText: 'Translation aur sunne ki zaban'),
        items: const [DropdownMenuItem(value: 'urdu', child: Text('Urdu')),
          DropdownMenuItem(value: 'english', child: Text('English'))],
        onChanged: (v) { _stop(); setState(() => _translation = v!); }),
      const SizedBox(height: 20),
      if (_loadError != null) Text(_loadError!, style: const TextStyle(color: Colors.red)),
      if (!_ready && _loadError == null) ...[const LinearProgressIndicator(),
        const SizedBox(height: 8), Text(_progress)],
      if (_busy) const Center(child: CircularProgressIndicator()),
      if (_ready && !_busy && _searchedQuery == null)
        Text('${_engine.count} references tayyar. Apna sawal likhein; phir Talaash karein.'),
      if (_searchedQuery != null && !_busy) ...[
        Text('“$_searchedQuery” · $_total related references${_total > 40 ? ' · pehle 40 dikh rahe hain' : ''}',
          style: AppText.caption),
        const SizedBox(height: 10),
        if (_hits.isEmpty) const Padding(padding: EdgeInsets.symmetric(vertical: 18),
          child: Text('Related reference nahi mila. Chhote keywords try karein, jaise “ungli”, “sabr” ya “gussa”. '
            'Har sawal ki wording samajhna is offline search mein mumkin nahi.')),
        ..._hits.map(_result),
      ],
    ]));

  Widget _result(Map<String, dynamic> h) {
    final urdu = _translation == 'urdu';
    final text = _body(h);
    return Card(margin: const EdgeInsets.only(bottom: 16), shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(20), side: BorderSide(color: AppColors.goldRule)),
      child: Padding(padding: const EdgeInsets.all(18), child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Text(h['kind'] == 'quran' ? 'QURAN AYAT' : 'HADEES',
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
              label: Text(_speaking == _id(h) ? 'Rokein' : 'Sunein')),
            TextButton.icon(onPressed: () => _open(h), icon: const Icon(Icons.menu_book_outlined),
              label: const Text('Poora parhein')),
            TextButton(onPressed: () => _details(h),
              child: Text(_meaning(h) == null ? 'Reference / wazahat' : 'Aasaan matlab')),
          ]),
        ])));
  }
}
