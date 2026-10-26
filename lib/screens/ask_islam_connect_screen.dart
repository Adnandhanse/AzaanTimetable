import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/hadith.dart';
import '../services/ask_connect_ai.dart';
import '../services/ask_connect_voice.dart';
import '../services/ask_roman_text.dart';
import '../services/hadith_link.dart';
import '../services/quran_repository.dart';
import '../services/tts_service.dart';
import '../services/prophet_stories_repository.dart';
import '../theme/app_theme.dart';
import 'surah_detail_screen.dart';
import 'prophet_story_reader_screen.dart';

class AskIslamConnectScreen extends StatefulWidget {
  const AskIslamConnectScreen({super.key});
  @override
  State<AskIslamConnectScreen> createState() => _AskIslamConnectScreenState();
}
class _ChatTurn {
  _ChatTurn(this.question, this.history);
  final String question;
  final List<Map<String, String>> history;
  Map<String, dynamic>? response;
  String? error;
}
class _AskIslamConnectScreenState extends State<AskIslamConnectScreen>
    with WidgetsBindingObserver {
  final _query = TextEditingController();
  final _scroll = ScrollController();
  final _turns = <_ChatTurn>[];
  bool _busy = false, _voiceBusy = false, _speaking = false;
  String _locale = 'hi-IN', _replyLanguage = 'auto';
  int _version = 0;
  @override
  void initState() { super.initState(); WidgetsBinding.instance.addObserver(this); }
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive || state == AppLifecycleState.paused) _stop();
  }
  Future<void> _stop() async {
    if (mounted) setState(() => _speaking = false);
    await TtsService.stop();
  }
  void _notice(String text) {
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }
  void _bottom() => WidgetsBinding.instance.addPostFrameCallback((_) {
    if (mounted && _scroll.hasClients) _scroll.animateTo(_scroll.position.maxScrollExtent,
      duration: const Duration(milliseconds: 220), curve: Curves.easeOut);
  });
  List<Map<String, String>> _history() {
    final messages = <Map<String, String>>[];
    for (final turn in _turns.where((t) => t.response != null)) {
      messages.add({'role': 'user', 'content': turn.question});
      final answer = (turn.response!['answer'] as Map?)?['text'] as String? ?? '';
      if (answer.isNotEmpty) messages.add({'role': 'assistant',
        'content': answer.length > 1000 ? answer.substring(0, 1000) : answer});
    }
    return messages.length <= 8 ? messages : messages.sublist(messages.length - 8);
  }
  Future<bool> _consent() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool('ask_conversation_notice_v1') == true) return true;
    if (!mounted) return false;
    final accepted = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(
      title: const Text('Ask Islam Connect'),
      content: const Text('Aapka sawal, recent conversation aur related sources Gemini ko bheje jayenge. '
        'Google ke free tier par data services improve karne ke liye use ho sakta hai. '
        'Audio, phone number aur location AI ko nahi bhejte. Personal details share na karein.'),
      actions: [TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Abhi nahi')),
        TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Jaari rakhein'))]));
    if (accepted == true) await prefs.setBool('ask_conversation_notice_v1', true);
    return accepted == true;
  }
  Future<void> _send({_ChatTurn? retry}) async {
    if (_busy || _voiceBusy) return;
    final question = retry?.question ?? _query.text.trim();
    if (question.length < 3) return;
    setState(() => _busy = true);
    final version = ++_version;
    try {
      if (!await _consent() || !mounted) return;
      FocusScope.of(context).unfocus(); await _stop();
      if (!mounted) return;
      final turn = retry ?? _ChatTurn(question, _history());
      setState(() {
        if (retry == null) { _turns.add(turn); if (_turns.length > 40) _turns.removeAt(0); _query.clear(); }
        turn.error = null;
      });
      _bottom();
      try {
        final response = await AskConnectAi.ask(question, 'all',
          history: turn.history, replyLanguage: _replyLanguage);
        if (!mounted || version != _version) return;
        setState(() => turn.response = response);
      } catch (error) {
        if (mounted && version == _version) setState(() => turn.error = _error(error));
      }
      _bottom();
    } catch (error) { if (mounted) _notice(_error(error)); }
    finally { if (mounted && version == _version) setState(() => _busy = false); }
  }
  String _error(Object error) {
    if (error is TimeoutException) return 'Jawab aane mein zyada waqt laga. Dobara try karein.';
    if (error is FirebaseAuthException) return 'Session nahi ban saka. Internet check karke dobara try karein.';
    if (error is StateError) return 'Assistant ka update abhi server par available nahi. Kuch der baad try karein.';
    if (error is FirebaseFunctionsException) {
      final details = error.details;
      final support = details is Map ? details['supportCode'] : null;
      if (support == 'AI-USER-LIMIT') return 'Aaj ki personal AI limit poori ho gayi. Basic jawab aur saved answers ab bhi mil sakte hain.';
      if (support == 'AI-PROJECT-LIMIT') return 'Aaj ka shared AI budget poora ho gaya. Basic jawab aur saved answers ab bhi mil sakte hain.';
      if (support == 'AI-COOLDOWN') return 'Agla sawal bhejne se pehle kuch seconds rukhein.';
      if (support == 'AI-LIMIT') return 'Gemini ki usage limit aa gayi hai. Kuch der baad try karein.';
      if (error.code == 'unauthenticated' || error.code == 'permission-denied') return 'Session verify nahi ho saka. Dobara try karein.';
      if (error.code == 'deadline-exceeded' || support == 'AI-TIMEOUT') return 'Jawab aane mein zyada waqt laga. Dobara try karein.';
      if (support == 'AI-OUTPUT') return 'Jawab sahi tarah receive nahi hua. Dobara try karein.';
      if (error.code == 'invalid-argument') return 'Sawal thoda chhota karke dobara bhejein.';
    }
    // No generic resource-exhausted => quota mapping: only actual quota codes.
    return 'Abhi jawab nahi aa saka. Internet check karke kuch der baad try karein.';
  }
  Future<void> _listen() async {
    if (_busy || _voiceBusy) return;
    setState(() => _voiceBusy = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      if (prefs.getBool('ask_voice_provider_notice_v1') != true) {
        if (!mounted) return;
        final ok = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(
          title: const Text('Sawal boliye'),
          content: const Text('Phone ki speech service awaaz ko text banayegi aur apne servers use kar sakti hai. Islam Connect audio save nahi karta.'),
          actions: [TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Abhi nahi')),
            TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Jaari rakhein'))]));
        if (ok != true) return;
        await prefs.setBool('ask_voice_provider_notice_v1', true);
      }
      if (!mounted) return;
      final text = await AskConnectVoice.listen(_locale);
      if (mounted && text != null) setState(() {
        // Keep the recognised script unless Roman was explicitly selected.
        _query.text = _replyLanguage == 'roman' ? askRomanTranscript(text) : text;
        _query.selection = TextSelection.collapsed(offset: _query.text.length);
      });
    } catch (_) { _notice('Voice nahi chali. Sawal type kar sakte hain.'); }
    finally { if (mounted) setState(() => _voiceBusy = false); }
  }
  Future<void> _speak(Map<String, dynamic> response) async {
    if (_speaking) { await _stop(); return; }
    final language = response['language'];
    if (language != 'en' && language != 'ur') return;
    final text = (response['answer'] as Map?)?['text'] as String? ?? '';
    setState(() => _speaking = true);
    final ok = await TtsService.speak(text, language == 'ur' ? TtsLang.urdu : TtsLang.english);
    if (mounted) { setState(() => _speaking = false); if (!ok) _notice('Is zaban ki voice phone par available nahi.'); }
  }
  Future<void> _open(Map<String, dynamic> ref, String language) async {
    await _stop(); if (!mounted) return;
    final raw = ref['source']; if (raw is! Map) return;
    final h = Map<String, dynamic>.from(raw);
    try {
      if (ref['kind'] == 'scholarly') {
        final uri = Uri.tryParse(ref['url'] as String? ?? '');
        if (uri != null && uri.scheme == 'https') await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else if (h['kind'] == 'hadith') {
        await HadithLink.open(context, HadithRef(book: HadithBook.values.firstWhere((b) => b.fileKey == h['book']), number: h['number'] as int),
          language: language == 'ur' ? HadithLanguage.urdu : HadithLanguage.english);
      } else if (h['kind'] == 'quran') {
        final surahs = await QuranRepository.loadSurahs(language == 'ur' ? QuranLanguage.urdu : QuranLanguage.english);
        final surah = surahs.firstWhere((s) => s.number == h['surah']); if (!mounted) return;
        await Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => SurahDetailScreen(surah: surah, initialVerse: h['number'] as int)));
      } else if (h['kind'] == 'story') {
        final stories = await ProphetStoriesRepository.load(); final story = stories.firstWhere((s) => s.id == h['storyId']);
        final page = story.pages.indexWhere((p) => p.id == h['pageId']); if (!mounted) return;
        await Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => ProphetStoryReaderScreen(story: story, initialPage: page < 0 ? 0 : page)));
      }
    } catch (_) { _notice('Reference abhi nahi khul saka.'); }
  }
  Future<void> _settings() async {
    await showModalBottomSheet<void>(context: context, isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(builder: (ctx, update) => SafeArea(child: Padding(
        padding: const EdgeInsets.all(24), child: Column(mainAxisSize: MainAxisSize.min, children: [
          DropdownButtonFormField<String>(value: _replyLanguage,
            decoration: const InputDecoration(labelText: 'Jawab ki zaban'),
            items: const [DropdownMenuItem(value: 'auto', child: Text('Sawal ki zaban')),
              DropdownMenuItem(value: 'roman', child: Text('Roman Hindi / Urdu')),
              DropdownMenuItem(value: 'hi', child: Text('हिंदी')), DropdownMenuItem(value: 'ur', child: Text('اردو')),
              DropdownMenuItem(value: 'en', child: Text('English'))],
            onChanged: (v) { if (v != null) { setState(() => _replyLanguage = v); update(() {}); } }),
          const SizedBox(height: 18),
          DropdownButtonFormField<String>(value: _locale,
            decoration: const InputDecoration(labelText: 'Voice Input'),
            items: const [DropdownMenuItem(value: 'hi-IN', child: Text('Hindi / Hinglish')),
              DropdownMenuItem(value: 'ur-PK', child: Text('Urdu')), DropdownMenuItem(value: 'en-IN', child: Text('English'))],
            onChanged: (v) { if (v != null) { setState(() => _locale = v); update(() {}); } }),
          const SizedBox(height: 18),
          const Text('Recent chat isi screen ke session mein rehti hai. New chat se context reset hoga.', style: TextStyle(fontSize: 12, height: 1.6)),
        ])))));
  }
  Widget _reference(Map<String, dynamic> ref, int number, String language) {
    final source = ref['source'] is Map ? Map<String, dynamic>.from(ref['source'] as Map) : <String, dynamic>{};
    final urdu = source['ur'] as String? ?? '';
    final body = language == 'ur' && urdu.isNotEmpty ? urdu : source['en'] as String? ?? '';
    final type = ref['kind'] == 'scholarly' ? 'Scholarly interpretation · editorial summary'
      : ref['kind'] == 'story' ? 'Historical retelling · sources in story'
      : ref['kind'] == 'dua' ? 'Dua collection · grade not inferred' : 'Source text';
    return ExpansionTile(tilePadding: EdgeInsets.zero,
      title: Text('[$number] ${ref['label']}', style: const TextStyle(fontSize: 13, height: 1.5)),
      subtitle: Text(type, style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
      children: [Align(alignment: AlignmentDirectional.centerStart, child: SelectableText(body,
        textDirection: language == 'ur' && (source['ur'] as String? ?? '').isNotEmpty ? TextDirection.rtl : TextDirection.ltr,
        style: const TextStyle(fontSize: 14, height: 1.8))),
        if ((source['ar'] as String? ?? '').isNotEmpty) ExpansionTile(title: const Text('Arabic', style: TextStyle(fontSize: 12)),
          children: [SelectableText(source['ar'] as String, textDirection: TextDirection.rtl, style: AppText.arabic.copyWith(fontSize: 22))]),
        if (ref['kind'] != 'dua') Align(alignment: AlignmentDirectional.centerStart,
          child: TextButton(onPressed: () => _open(ref, language), child: const Text('Source kholein'))),
      ]);
  }
  Widget _reply(_ChatTurn turn) {
    if (turn.error != null) return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(turn.error!, style: const TextStyle(fontSize: 14, height: 1.6)),
      TextButton(onPressed: _busy ? null : () => _send(retry: turn), child: const Text('Dobara try karein'))]);
    final response = turn.response;
    if (response == null) return const Padding(padding: EdgeInsets.symmetric(vertical: 14),
      child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)));
    final language = response['language'] as String? ?? 'roman';
    final refs = (response['references'] as List? ?? []).map((r) => Map<String, dynamic>.from(r as Map)).toList();
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      for (final raw in response['statements'] as List? ?? []) ...[
        SelectableText(raw['text'] as String, textDirection: language == 'ur' ? TextDirection.rtl : TextDirection.ltr,
          style: TextStyle(fontFamily: language == 'ur' ? 'NotoNastaliqUrdu' : 'Inter', fontSize: 16,
            height: language == 'ur' ? 2.0 : 1.7, color: AppColors.text)),
        if ((raw['sourceIds'] as List? ?? []).isNotEmpty) Padding(padding: const EdgeInsets.only(top: 3),
          child: Text((raw['sourceIds'] as List).map((id) => '[${refs.indexWhere((r) => r['id'] == id) + 1}]').join(' '),
            style: TextStyle(fontSize: 11, color: AppColors.textMuted))),
        const SizedBox(height: 12),
      ],
      for (final notice in response['notices'] as List? ?? []) Padding(padding: const EdgeInsets.only(bottom: 10),
        child: Text(notice as String, style: TextStyle(fontSize: 12, height: 1.6, color: AppColors.textMuted))),
      if (refs.isNotEmpty) ...[
        const Divider(), const Text('References', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
        for (var i = 0; i < refs.length; i++) _reference(refs[i], i + 1, language),
      ],
      Wrap(children: [IconButton(tooltip: 'Copy answer', icon: const Icon(Icons.copy_outlined, size: 18),
        onPressed: () => Clipboard.setData(ClipboardData(text: '${(response['answer'] as Map?)?['text'] ?? ''}\n${refs.map((r) => r['label']).join('\n')}'))),
        if (language == 'en' || language == 'ur') IconButton(tooltip: 'Listen',
          onPressed: () => _speak(response), icon: Icon(_speaking ? Icons.stop_circle_outlined : Icons.volume_up_outlined, size: 20)),
      ]),
    ]);
  }
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Ask Islam Connect', style: TextStyle(fontSize: 18)), actions: [
      IconButton(tooltip: 'New chat', onPressed: _busy ? null : () { _stop(); setState(() => _turns.clear()); }, icon: const Icon(Icons.edit_square, size: 21)),
      IconButton(tooltip: 'Language', onPressed: _busy ? null : _settings, icon: const Icon(Icons.tune, size: 21)),
    ]),
    body: Column(children: [
      Expanded(child: ListView(controller: _scroll, padding: const EdgeInsets.all(18), children: [
        if (_turns.isEmpty) Padding(padding: const EdgeInsets.symmetric(vertical: 22), child: Column(
          crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Apna sawal poochhein', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600)),
            const SizedBox(height: 10), Text('Seedha jawab, aasaan wazahat aur relevant references.',
              style: TextStyle(fontSize: 14, height: 1.6, color: AppColors.textMuted)),
          ])),
        for (final turn in _turns) ...[
          Align(alignment: AlignmentDirectional.centerEnd, child: Container(
            margin: const EdgeInsets.only(bottom: 12), padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: AppColors.goldRule.withOpacity(.35), borderRadius: BorderRadius.circular(16)),
            child: SelectableText(turn.question, style: const TextStyle(fontSize: 15, height: 1.6)))),
          Container(margin: const EdgeInsets.only(bottom: 24), padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.goldRule)),
            child: _reply(turn)),
        ],
      ])),
      SafeArea(top: false, child: Padding(padding: const EdgeInsets.fromLTRB(14, 8, 14, 12), child: Row(
        crossAxisAlignment: CrossAxisAlignment.end, children: [
          Expanded(child: TextField(controller: _query, minLines: 1, maxLines: 5, maxLength: 500,
            textInputAction: TextInputAction.newline, style: const TextStyle(fontSize: 16),
            decoration: InputDecoration(hintText: _voiceBusy ? 'Sun rahe hain…' : 'Sawal ya follow-up likhein…', counterText: '',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
              suffixIcon: IconButton(onPressed: _busy || _voiceBusy ? null : _listen, tooltip: 'Sawal boliye',
                icon: Icon(_voiceBusy ? Icons.hearing : Icons.mic_none))))),
          const SizedBox(width: 8),
          IconButton.filledTonal(tooltip: 'Bhejein', onPressed: _busy || _voiceBusy ? null : () => _send(),
            icon: Icon(_busy ? Icons.more_horiz : Icons.arrow_upward)),
        ]))),
    ]));
  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this); _version++;
    TtsService.stop(); _query.dispose(); _scroll.dispose(); super.dispose();
  }
}
