import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/hadith.dart';
import '../data/daily_hadith.dart';
import '../data/daily_quran_ayah.dart';
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
  final _query = TextEditingController();
  bool _busy = false, _voiceBusy = false;
  String? _searchError;
  String _locale = 'hi-IN', _translation = 'urdu', _kind = 'all';
  String? _speaking;
  bool _confirmingAi = false;
  String? _aiFollowup;
  int _searchVersion = 0, _audioVersion = 0, _total = 0;
  String? _searchedQuery;
  List<Map<String, dynamic>> _hits = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
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
    if (_busy || _voiceBusy || _confirmingAi || _query.text.trim().isEmpty) return;
    {
      _confirmingAi = true;
      try { if (!await _allowAi()) return; } finally { _confirmingAi = false; }
    }
    if (!mounted) return;
    FocusScope.of(context).unfocus();
    await _stop();
    if (!mounted) return;
    final version = ++_searchVersion;
    final query = _query.text.trim();
    setState(() { _busy = true; _hits = []; _searchedQuery = query; _total = 0; _searchError = null;
      _aiFollowup = null;
 });
    try {
      final reply = await AskConnectAi.ask(query, _kind);
      if (!mounted || version != _searchVersion) return;
      if (reply['answerMode'] != 'sources-only') {
        throw StateError('ai-backend-update-needed');
      }
      setState(() {
        _hits = (reply['hits'] as List).map((h) => Map<String, dynamic>.from(h as Map)).toList();
        _total = reply['total'] as int? ?? _hits.length;
        _aiFollowup = reply['followup'] as String?;
      });
    } catch (error) {
      if (mounted && version == _searchVersion) setState(() =>
        _searchError = _aiError(error));
    }
    finally { if (mounted && version == _searchVersion) setState(() => _busy = false); }
  }

  Future<bool> _allowAi() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool('ask_gemini_data_notice_v1') == true) return true;
    if (!mounted) return false;
    final allowed = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(
      title: const Text('Ask Islam Connect'),
      content: const Text('Aapka sawal aur related Quran, hadees ya story passages Google Gemini ko bheje jaayenge. '
        'Free tier par Google is data ko apni services improve karne ke liye use kar sakta hai. '
        'Audio, phone number aur location Gemini ko nahi bheje jaate. Sawal mein personal details na likhein.'),
      actions: [TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Abhi nahi')),
        TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Jaari rakhein'))]));
    if (allowed == true) await prefs.setBool('ask_gemini_data_notice_v1', true);
    return allowed == true;
  }

  String _aiError(Object error) {
    if (error is StateError && error.message == 'ai-backend-update-needed') {
      return 'Gemini service ka naya version deploy karna baaki hai. Platform admin se rabta karein.';
    }
    if (error is FirebaseAuthException) {
      if (error.code == 'operation-not-allowed' || error.code == 'admin-restricted-operation') {
        return 'AI setup baaki hai: Firebase mein Anonymous sign-in enable karna hai.';
      }
      return 'AI session nahi ban saka. Internet check karke dobara koshish karein.';
    }
    if (error is FirebaseFunctionsException) {
      if (error.code == 'unauthenticated') return 'AI session verify nahi ho saka. Platform admin AI service ki Cloud Run access setting check karein. [AI-AUTH]';
      if (error.code == 'permission-denied') return 'AI service access deny ho raha hai. Platform admin server permissions check karein. [AI-ACCESS]';
      if (error.code == 'deadline-exceeded') return 'Search mein zyada waqt lag raha hai. Kuch der baad dobara koshish karein. [AI-TIMEOUT]';
      final details = error.details;
      final support = details is Map ? details['supportCode'] : null;
      const messages = <String, String>{
        'AI-DATABASE': 'AI server database access check karna hai.',
        'AI-PROVIDER-REQUEST': 'Gemini request configuration check karna hai.',
        'AI-MODEL': 'Configured Gemini model available nahi hai.',
        'AI-KEY': 'Gemini API key ya access check karna hai.',
        'AI-OUTPUT': 'Gemini ka response complete ya valid nahi tha. Dobara koshish karein.',
        'AI-CORPUS': 'AI ki reference library server par load nahi ho saki.',
      };
      if (support is String && messages.containsKey(support)) return '${messages[support]} [$support]';
      if (error.code == 'internal' || error.code == 'unavailable') return 'AI server search poori nahi kar saka. Platform admin server logs check karein. [AI-SERVER]';
      if (error.code == 'not-found') return 'Gemini service abhi available nahi. Platform admin deployment check karein.';
      if (error.code == 'failed-precondition') return 'Gemini ki API key ya server setup check karna hai. Platform admin se rabta karein.';
      if (error.code == 'resource-exhausted') return 'Abhi AI ki usage limit aa gayi hai. Kuch der baad dobara koshish karein; daily limit ho to agle din try karein.';
    }
    return 'Search poori nahi ho saki. Internet check karke dobara koshish karein.';
  }

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
    TtsService.stop(); _query.dispose();
    super.dispose();
  }

  Future<void> _settings() async {
    await showModalBottomSheet<void>(context: context, showDragHandle: true,
      builder: (ctx) => StatefulBuilder(builder: (ctx, updateSheet) => SafeArea(
        child: Padding(padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text('Zaban ki settings', style: AppText.rowTitle),
            const SizedBox(height: 20),
            DropdownButtonFormField<String>(value: _locale,
              decoration: const InputDecoration(labelText: 'Bolne ki zaban'),
              items: const [
                DropdownMenuItem(value: 'hi-IN', child: Text('Hinglish')),
                DropdownMenuItem(value: 'ur-PK', child: Text('Urdu')),
                DropdownMenuItem(value: 'en-IN', child: Text('English'))],
              onChanged: (v) { if (v == null) return;
                setState(() => _locale = v); updateSheet(() {}); }),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(value: _translation,
              decoration: const InputDecoration(labelText: 'Translation aur audio'),
              items: const [DropdownMenuItem(value: 'urdu', child: Text('Urdu')),
                DropdownMenuItem(value: 'english', child: Text('English'))],
              onChanged: (v) { if (v == null) return; _stop();
                setState(() => _translation = v); updateSheet(() {}); }),
            const SizedBox(height: 16),
            const Text('Voice ka text check karke sawal bhejein. Stories ka audio English mein hai.'),
          ])))));
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Ask Islam Connect'), actions: [
      IconButton(tooltip: 'Zaban ki settings', onPressed: _busy || _voiceBusy ? null : _settings,
        icon: const Icon(Icons.tune_rounded)),
    ]),
    body: ListView(padding: const EdgeInsets.fromLTRB(20, 24, 20, 32), children: [
      Text('Har sawal, ilm ki taraf ek qadam.',
        style: AppText.rowTitle.copyWith(fontSize: 26, height: 1.3)),
      const SizedBox(height: 8),
      Text('Apna sawal likhein ya boliye. Quran, hadees aur Anbiya ki kahaniyon mein references talaash karein.',
        style: AppText.body.copyWith(color: AppColors.textMuted)),
      const SizedBox(height: 24),
      TextField(controller: _query, maxLength: 500, minLines: 2, maxLines: 6,
        enabled: !_busy && !_voiceBusy,
        textInputAction: TextInputAction.newline,
        decoration: InputDecoration(hintText: 'Aaj aap kya jaanna chahte hain?' ,
          counterText: '', filled: true, fillColor: AppColors.white,
          contentPadding: const EdgeInsets.all(18),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(20)),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(20),
            borderSide: BorderSide(color: AppColors.goldRule)),
          suffixIcon: IconButton(tooltip: 'Sawal boliye',
            onPressed: _busy || _voiceBusy ? null : _listen,
            icon: Icon(_voiceBusy ? Icons.hearing_rounded : Icons.mic_none_rounded,
              color: AppColors.text)))),
      const SizedBox(height: 12),
      FilledButton.icon(style: FilledButton.styleFrom(
        backgroundColor: AppColors.goldRule.withOpacity(.55), foregroundColor: AppColors.text,
        minimumSize: const Size.fromHeight(54), elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
        onPressed: _busy || _voiceBusy ? null : _search,
        icon: const Icon(Icons.auto_awesome_outlined, size: 20),
        label: Text(_voiceBusy ? 'Sun rahe hain…' : 'References talaash karein')),
      const SizedBox(height: 24),
      if (_busy) ...[
        const LinearProgressIndicator(), const SizedBox(height: 12),
        Text('Aapke sawal se related references dhoondh rahe hain…', style: AppText.caption),
      ],
      if (_searchError != null && !_busy) ...[
        Text(_searchError!, style: AppText.body),
        TextButton.icon(onPressed: _search, icon: const Icon(Icons.refresh),
          label: const Text('Dobara koshish karein')),
      ],
      if (_searchedQuery != null && !_busy && _searchError == null) ...[
        if (_hits.isEmpty) Padding(padding: const EdgeInsets.symmetric(vertical: 12),
          child: Text(_aiFollowup?.isNotEmpty == true ? _aiFollowup! :
            'Is sawal ka wazeh reference nahi mila. Sawal thoda aur saaf karke poochhein.',
            style: AppText.body))
        else ...[
          Text('Aapke sawal se mutalliq · $_total references', style: AppText.rowTitle),
          const SizedBox(height: 12), for (var i = 0; i < _hits.length; i++) _result(_hits[i], i + 1),
        ],
      ],
    ]));

  Widget _result(Map<String, dynamic> h, int position) {
    final urdu = _translation == 'urdu' && h['kind'] != 'story';
    final text = _body(h);
    return Card(margin: const EdgeInsets.only(bottom: 16), shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(20), side: BorderSide(color: AppColors.goldRule)),
      child: Padding(padding: const EdgeInsets.all(18), child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Text('$position. ${h['kind'] == 'story' ? 'ANBIYA KI KAHANI' : h['kind'] == 'quran' ? 'QURAN AYAT' : 'HADEES'}',
            style: AppText.caption.copyWith(color: AppColors.emerald, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8), Row(children: [
            Expanded(child: Text(_reference(h), style: AppText.rowTitle)),
            if (h['kind'] != 'story') IconButton(tooltip: 'Reference aur wazahat',
              onPressed: () => _details(h), icon: const Icon(Icons.info_outline, size: 20)),
          ]),
          if ((h['ar'] as String? ?? '').isNotEmpty) Padding(padding: const EdgeInsets.symmetric(vertical: 12),
            child: Text(h['ar'] as String, maxLines: 3, overflow: TextOverflow.ellipsis,
              textDirection: TextDirection.rtl, style: AppText.arabic.copyWith(fontSize: 22))),
          Text(text.isEmpty ? 'Is zaban mein translation available nahi.' : text,
            maxLines: 5, overflow: TextOverflow.ellipsis,
            textDirection: urdu ? TextDirection.rtl : TextDirection.ltr,
            style: urdu ? AppText.urduText.copyWith(fontSize: 18, height: 2) : AppText.body),
          if (h['kind'] == 'story') ...[
            const SizedBox(height: 12),
            for (final raw in (h['sources'] as List? ?? const []))
              Padding(padding: const EdgeInsets.only(bottom: 8),
                child: Text(raw['kind'] == 'quran'
                  ? 'Quran ${raw['surah']}:${raw['start']}${raw['end'] != raw['start'] ? '–${raw['end']}' : ''}'
                  : '${raw['book'] == 'muslim' ? 'Sahih Muslim' : 'Sahih al-Bukhari'} ${raw['editionLabel'] ?? raw['number']}',
                  style: AppText.caption.copyWith(color: AppColors.emerald))),
          ],
          const SizedBox(height: 8),
          Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            TextButton.icon(onPressed: text.isEmpty ? null : () => _speak(h),
              icon: Icon(_speaking == _id(h) ? Icons.stop_circle_outlined : Icons.volume_up_outlined),
              label: Text(_speaking == _id(h) ? 'Rokein' : h['kind'] == 'story' ? 'English mein sunein' : 'Sunein')),
            TextButton.icon(onPressed: () => _open(h), icon: const Icon(Icons.menu_book_outlined),
              label: Text(h['kind'] == 'story' ? 'Poori story parhein' : 'Poora parhein')),
          ]),
        ])));
  }
}
