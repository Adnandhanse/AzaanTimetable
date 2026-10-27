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
import '../services/app_strings.dart';
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
  String _locale = 'hi-IN';
  static const _replyLanguage = 'auto';
  int _version = 0;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    if (S.isUrdu) {
      _locale = 'ur-PK';
    }
  }

  String _ui(String en, String ur) => S.tr(en, ur);
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused) _stop();
  }

  Future<void> _stop() async {
    if (mounted) setState(() => _speaking = false);
    await TtsService.stop();
  }

  void _notice(String text) {
    if (mounted)
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  void _bottom() => WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _scroll.hasClients)
          _scroll.animateTo(_scroll.position.maxScrollExtent,
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOut);
      });
  List<Map<String, String>> _history() {
    final messages = <Map<String, String>>[];
    for (final turn in _turns.where((t) => t.response != null)) {
      messages.add({'role': 'user', 'content': turn.question});
      final answer =
          (turn.response!['answer'] as Map?)?['text'] as String? ?? '';
      if (answer.isNotEmpty)
        messages.add({
          'role': 'assistant',
          'content': answer.length > 1000 ? answer.substring(0, 1000) : answer
        });
    }
    return messages.length <= 8
        ? messages
        : messages.sublist(messages.length - 8);
  }

  Future<bool> _consent() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool('ask_conversation_notice_v1') == true) return true;
    if (!mounted) return false;
    final accepted = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
                title: const Text('Ask Islam Connect'),
                content: Text(_ui(
                    'Your question, recent conversation and relevant sources are sent to Gemini. On the free tier, Google may use this data to improve its services. Audio, phone numbers and location are not sent to AI. Avoid sharing personal information.',
                    'آپ کا سوال، حالیہ گفتگو اور متعلقہ حوالے Gemini کو بھیجے جاتے ہیں۔ مفت سروس پر Google اس ڈیٹا کو سروس بہتر بنانے کے لیے استعمال کر سکتا ہے۔ آڈیو، فون نمبر یا مقام AI کو نہیں بھیجے جاتے۔ ذاتی معلومات شیئر نہ کریں۔')),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: Text(_ui('Not Now', 'ابھی نہیں'))),
                  TextButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      child: Text(_ui('Continue', 'جاری رکھیں')))
                ]));
    if (accepted == true)
      await prefs.setBool('ask_conversation_notice_v1', true);
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
      FocusScope.of(context).unfocus();
      await _stop();
      if (!mounted) return;
      final turn = retry ?? _ChatTurn(question, _history());
      setState(() {
        if (retry == null) {
          _turns.add(turn);
          if (_turns.length > 40) _turns.removeAt(0);
          _query.clear();
        }
        turn.error = null;
      });
      _bottom();
      try {
        final response = await AskConnectAi.ask(question, 'all',
            history: turn.history,
            replyLanguage: askReplyLanguage(question, _replyLanguage));
        if (!mounted || version != _version) return;
        setState(() => turn.response = response);
      } catch (error) {
        if (mounted && version == _version)
          setState(() => turn.error = _error(error));
      }
      _bottom();
    } catch (error) {
      if (mounted) _notice(_error(error));
    } finally {
      if (mounted && version == _version) setState(() => _busy = false);
    }
  }

  String _error(Object error) {
    if (error is TimeoutException)
      return _ui('The answer took too long. Please try again.',
          'جواب میں زیادہ وقت لگا۔ دوبارہ کوشش کریں۔');
    if (error is FirebaseAuthException)
      return _ui('Could not connect. Check your internet and try again.',
          'رابطہ نہیں ہو سکا۔ انٹرنیٹ دیکھ کر دوبارہ کوشش کریں۔');
    if (error is StateError)
      return _ui('The assistant needs a server update. Please try again later.',
          'معاون کی سرور اپ ڈیٹ درکار ہے۔ کچھ دیر بعد کوشش کریں۔');
    if (error is FirebaseFunctionsException) {
      final details = error.details;
      final support = details is Map ? details['supportCode'] : null;
      if (support == 'AI-USER-LIMIT')
        return _ui(
            'You have used your 5 new AI answers for today. Basic and saved answers remain available.',
            'آج کے پانچ نئے AI جوابات استعمال ہو چکے ہیں۔ بنیادی اور محفوظ جوابات دستیاب رہیں گے۔');
      if (support == 'AI-PROJECT-LIMIT')
        return _ui(
            'Today’s shared AI allowance has been used. Basic and saved answers remain available.',
            'آج کی مشترکہ AI حد مکمل ہو گئی ہے۔ بنیادی اور محفوظ جوابات دستیاب ہیں۔');
      if (support == 'AI-COOLDOWN')
        return _ui('Please wait a few seconds before your next question.',
            'اگلے سوال سے پہلے چند سیکنڈ رکیں۔');
      if (support == 'AI-LIMIT')
        return _ui(
            'The AI provider is at its usage limit. Please try again later.',
            'AI سروس کی حد مکمل ہے۔ کچھ دیر بعد کوشش کریں۔');
      if (error.code == 'unauthenticated' || error.code == 'permission-denied')
        return _ui('Could not verify your session. Please try again.',
            'سیشن کی تصدیق نہیں ہو سکی۔ دوبارہ کوشش کریں۔');
      if (error.code == 'deadline-exceeded' || support == 'AI-TIMEOUT')
        return _ui('The answer took too long. Please try again.',
            'جواب میں زیادہ وقت لگا۔ دوبارہ کوشش کریں۔');
      if (support == 'AI-OUTPUT')
        return _ui('The answer could not be loaded. Please try again.',
            'جواب لوڈ نہیں ہو سکا۔ دوبارہ کوشش کریں۔');
      if (error.code == 'invalid-argument')
        return _ui('Please shorten your question and try again.',
            'سوال مختصر کر کے دوبارہ بھیجیں۔');
    }
    // No generic resource-exhausted => quota mapping: only actual quota codes.
    return _ui('Could not load an answer. Check your connection and try again.',
        'جواب نہیں آ سکا۔ انٹرنیٹ دیکھ کر دوبارہ کوشش کریں۔');
  }

  Future<void> _listen() async {
    if (_busy || _voiceBusy) return;
    setState(() => _voiceBusy = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      if (prefs.getBool('ask_voice_provider_notice_v1') != true) {
        if (!mounted) return;
        final ok = await showDialog<bool>(
            context: context,
            builder: (ctx) => AlertDialog(
                    title: Text(_ui('Ask by Voice', 'آواز سے سوال کریں')),
                    content: Text(_ui(
                        'Your phone’s speech service converts voice to text and may use its servers. Islam Connect does not save your audio.',
                        'فون کی صوتی سروس آواز کو متن بناتی ہے اور اپنے سرور استعمال کر سکتی ہے۔ اسلام کنیکٹ آڈیو محفوظ نہیں کرتا۔')),
                    actions: [
                      TextButton(
                          onPressed: () => Navigator.pop(ctx, false),
                          child: Text(_ui('Not Now', 'ابھی نہیں'))),
                      TextButton(
                          onPressed: () => Navigator.pop(ctx, true),
                          child: Text(_ui('Continue', 'جاری رکھیں')))
                    ]));
        if (ok != true) return;
        await prefs.setBool('ask_voice_provider_notice_v1', true);
      }
      if (!mounted) return;
      final text = await AskConnectVoice.listen(_locale);
      if (mounted && text != null)
        setState(() {
          // Hindi/Hinglish is displayed in Roman script by default; English stays English.
          _query.text = askVoiceTranscript(text, _replyLanguage);
          _query.selection =
              TextSelection.collapsed(offset: _query.text.length);
        });
    } catch (_) {
      _notice(_ui('Voice input is unavailable. You can type your question.',
          'آواز کی سہولت دستیاب نہیں۔ سوال لکھ سکتے ہیں۔'));
    } finally {
      if (mounted) setState(() => _voiceBusy = false);
    }
  }

  Future<void> _speak(Map<String, dynamic> response) async {
    if (_speaking) {
      await _stop();
      return;
    }
    final language = response['language'];
    if (language != 'en' && language != 'ur') return;
    final text = (response['answer'] as Map?)?['text'] as String? ?? '';
    setState(() => _speaking = true);
    final ok = await TtsService.speak(
        text, language == 'ur' ? TtsLang.urdu : TtsLang.english);
    if (mounted) {
      setState(() => _speaking = false);
      if (!ok)
        _notice(_ui('This voice is not available on your phone.',
            'یہ آواز فون پر دستیاب نہیں۔'));
    }
  }

  Future<void> _open(Map<String, dynamic> ref, String language) async {
    await _stop();
    if (!mounted) return;
    final raw = ref['source'];
    if (raw is! Map) return;
    final h = Map<String, dynamic>.from(raw);
    try {
      if (ref['kind'] == 'scholarly') {
        final uri = Uri.tryParse(ref['url'] as String? ?? '');
        if (uri != null && uri.scheme == 'https')
          await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else if (h['kind'] == 'hadith') {
        await HadithLink.open(
            context,
            HadithRef(
                book:
                    HadithBook.values.firstWhere((b) => b.fileKey == h['book']),
                number: h['number'] as int),
            language: language == 'ur'
                ? HadithLanguage.urdu
                : HadithLanguage.english);
      } else if (h['kind'] == 'quran') {
        final surahs = await QuranRepository.loadSurahs(
            language == 'ur' ? QuranLanguage.urdu : QuranLanguage.english);
        final surah = surahs.firstWhere((s) => s.number == h['surah']);
        if (!mounted) return;
        await Navigator.of(context).push(MaterialPageRoute<void>(
            builder: (_) => SurahDetailScreen(
                surah: surah, initialVerse: h['number'] as int)));
      } else if (h['kind'] == 'story') {
        final stories = await ProphetStoriesRepository.load();
        final story = stories.firstWhere((s) => s.id == h['storyId']);
        final page = story.pages.indexWhere((p) => p.id == h['pageId']);
        if (!mounted) return;
        await Navigator.of(context).push(MaterialPageRoute<void>(
            builder: (_) => ProphetStoryReaderScreen(
                story: story, initialPage: page < 0 ? 0 : page)));
      }
    } catch (_) {
      _notice(_ui('Could not open this reference.', 'یہ حوالہ نہیں کھل سکا۔'));
    }
  }

  Future<void> _settings() async {
    await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        builder: (ctx) => StatefulBuilder(
            builder: (ctx, update) => SafeArea(
                child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                      DropdownButtonFormField<String>(
                          value: _locale,
                          decoration: InputDecoration(
                              labelText: _ui('Voice Input', 'آواز کی زبان')),
                          items: [
                            DropdownMenuItem(
                                value: 'hi-IN',
                                child: Text('Hindi / Hinglish')),
                            DropdownMenuItem(
                                value: 'ur-PK', child: Text('Urdu')),
                            DropdownMenuItem(
                                value: 'en-IN', child: Text('English'))
                          ],
                          onChanged: (v) {
                            if (v != null) {
                              setState(() => _locale = v);
                              update(() {});
                            }
                          }),
                      const SizedBox(height: 18),
                      Text(
                          _ui('Answers follow your question: Hinglish or English. Start a new chat to clear context.',
                              'گفتگو اسی سیشن میں رہتی ہے۔ نئی گفتگو سے سیاق ختم ہو جاتا ہے۔'),
                          style: TextStyle(fontSize: 12, height: 1.6)),
                    ])))));
  }

  Widget _reference(Map<String, dynamic> ref, int number, String language) {
    final source = ref['source'] is Map
        ? Map<String, dynamic>.from(ref['source'] as Map)
        : <String, dynamic>{};
    final urdu = source['ur'] as String? ?? '';
    final body = language == 'ur' && urdu.isNotEmpty
        ? urdu
        : source['en'] as String? ?? '';
    final type = ref['kind'] == 'scholarly'
        ? _ui('Scholarly interpretation', 'علمی تشریح')
        : ref['kind'] == 'story'
            ? _ui('Story · cited sources', 'کہانی · حوالے')
            : ref['kind'] == 'dua'
                ? _ui('Dua collection', 'دعاؤں کا مجموعہ')
                : _ui('Source text', 'اصل متن');
    return ExpansionTile(
        tilePadding: EdgeInsets.zero,
        title: Text('[$number] ${ref['label']}',
            style: const TextStyle(fontSize: 13, height: 1.5)),
        subtitle: Text(type,
            style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
        children: [
          Align(
              alignment: AlignmentDirectional.centerStart,
              child: SelectableText(body,
                  textDirection: language == 'ur' &&
                          (source['ur'] as String? ?? '').isNotEmpty
                      ? TextDirection.rtl
                      : TextDirection.ltr,
                  style: const TextStyle(fontSize: 14, height: 1.8))),
          if ((source['ar'] as String? ?? '').isNotEmpty)
            ExpansionTile(
                title:
                    Text(_ui('Arabic', 'عربی'), style: TextStyle(fontSize: 12)),
                children: [
                  SelectableText(source['ar'] as String,
                      textDirection: TextDirection.rtl,
                      style: AppText.arabic.copyWith(fontSize: 22))
                ]),
          if (ref['kind'] != 'dua')
            Align(
                alignment: AlignmentDirectional.centerStart,
                child: TextButton(
                    onPressed: () => _open(ref, language),
                    child: Text(_ui('Open Source', 'حوالہ کھولیں')))),
        ]);
  }

  Widget _reply(_ChatTurn turn) {
    if (turn.error != null)
      return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(turn.error!, style: const TextStyle(fontSize: 13, height: 1.5)),
        TextButton(
            onPressed: _busy ? null : () => _send(retry: turn),
            child: Text(_ui('Try Again', 'دوبارہ کوشش کریں')))
      ]);
    final response = turn.response;
    if (response == null)
      return const Padding(
          padding: EdgeInsets.symmetric(vertical: 14),
          child: SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2)));
    final language = response['language'] as String? ?? 'roman';
    final refs = (response['references'] as List? ?? [])
        .map((r) => Map<String, dynamic>.from(r as Map))
        .toList();
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      for (final raw in response['statements'] as List? ?? []) ...[
        SelectableText(raw['text'] as String,
            textDirection:
                language == 'ur' ? TextDirection.rtl : TextDirection.ltr,
            style: TextStyle(
                fontFamily: language == 'ur' ? 'NotoNastaliqUrdu' : 'Inter',
                fontSize: language == 'ur' ? 16 : 12.5,
                height: language == 'ur' ? 1.95 : 1.55,
                color: AppColors.text)),
        if ((raw['sourceIds'] as List? ?? []).isNotEmpty)
          Padding(
              padding: const EdgeInsets.only(top: 3),
              child: Text(
                  (raw['sourceIds'] as List)
                      .map((id) =>
                          '[${refs.indexWhere((r) => r['id'] == id) + 1}]')
                      .join(' '),
                  style: TextStyle(fontSize: 11, color: AppColors.textMuted))),
        const SizedBox(height: 12),
      ],
      for (final notice in response['notices'] as List? ?? [])
        Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Text(notice as String,
                style: TextStyle(
                    fontSize: 12, height: 1.6, color: AppColors.textMuted))),
      if (refs.isNotEmpty) ...[
        const Divider(),
        Text(_ui('References', 'حوالے'),
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
        for (var i = 0; i < refs.length; i++)
          _reference(refs[i], i + 1, language),
      ],
      Wrap(children: [
        IconButton(
            tooltip: _ui('Copy Answer', 'جواب نقل کریں'),
            icon: const Icon(Icons.copy_outlined, size: 18),
            onPressed: () => Clipboard.setData(ClipboardData(
                text:
                    '${(response['answer'] as Map?)?['text'] ?? ''}\n${refs.map((r) => r['label']).join('\n')}'))),
        if (language == 'en' || language == 'ur')
          IconButton(
              tooltip: _ui('Listen', 'سنیں'),
              onPressed: () => _speak(response),
              icon: Icon(
                  _speaking
                      ? Icons.stop_circle_outlined
                      : Icons.volume_up_outlined,
                  size: 20)),
      ]),
    ]);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
      appBar: AppBar(
          title:
              const Text('Ask Islam Connect', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
          actions: [
            IconButton(
                tooltip: _ui('New Chat', 'نئی گفتگو'),
                onPressed: _busy
                    ? null
                    : () {
                        _stop();
                        setState(() => _turns.clear());
                      },
                icon: const Icon(Icons.edit_square, size: 21)),
            IconButton(
                tooltip: _ui('Language', 'زبان'),
                onPressed: _busy ? null : _settings,
                icon: const Icon(Icons.tune, size: 21)),
          ]),
      body: Column(children: [
        Expanded(
            child: ListView(
                controller: _scroll,
                padding: const EdgeInsets.all(18),
                children: [
              if (_turns.isEmpty)
                Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.auto_awesome_outlined,
                              size: 28, color: AppColors.gold),
                          const SizedBox(height: 18),
                          Text(
                              _ui('A little clarity, every day.',
                                  'ہر روز، علم کی طرف ایک قدم۔'),
                              style: TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.w500)),
                          const SizedBox(height: 10),
                          Text(
                              _ui('Ask naturally. Explore answers with trusted references.',
                                  'آسانی سے سوال کریں۔ معتبر حوالوں کے ساتھ جواب جانیں۔'),
                              style: TextStyle(
                                  fontSize: 13,
                                  height: 1.5,
                                  color: AppColors.textMid)),
                          const SizedBox(height: 22),
                          for (final example in [
                            _ui('How can I build a habit of prayer?',
                                'نماز کی عادت کیسے بناؤں؟'),
                            _ui('What does Islam teach about kindness?',
                                'اسلام حسن سلوک کے بارے میں کیا سکھاتا ہے؟'),
                          ])
                            Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: OutlinedButton(
                                    style: OutlinedButton.styleFrom(
                                        alignment: Alignment.centerLeft,
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 14, vertical: 12),
                                        foregroundColor: AppColors.textMid,
                                        side: BorderSide(
                                            color: AppColors.goldRule),
                                        shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(12))),
                                    onPressed: () {
                                      _query.text = example;
                                    },
                                    child: Text(example,
                                        style: const TextStyle(
                                            fontSize: 12, height: 1.4)))),
                        ])),
              for (final turn in _turns) ...[
                Align(
                    alignment: AlignmentDirectional.centerEnd,
                    child: Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                            color: AppColors.goldRule.withOpacity(.35),
                            borderRadius: BorderRadius.circular(16)),
                        child: SelectableText(turn.question,
                            style:
                                const TextStyle(fontSize: 12.5, height: 1.5)))),
                Container(
                    margin: const EdgeInsets.only(bottom: 24),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.goldRule)),
                    child: _reply(turn)),
              ],
            ])),
        SafeArea(
            top: false,
            child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 8, 14, 12),
                child:
                    Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
                  Expanded(
                      child: TextField(
                          controller: _query,
                          minLines: 1,
                          maxLines: 5,
                          maxLength: 500,
                          textInputAction: TextInputAction.newline,
                          style: TextStyle(fontSize: 13, color: AppColors.text),
                          decoration: InputDecoration(
                              hintText: _voiceBusy
                                  ? _ui('Listening…', 'سن رہے ہیں…')
                                  : _ui('Ask a question…', 'اپنا سوال لکھیں…'),
                              counterText: '',
                              border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16)),
                              suffixIcon: IconButton(
                                  onPressed:
                                      _busy || _voiceBusy ? null : _listen,
                                  tooltip:
                                      _ui('Ask by Voice', 'آواز سے سوال کریں'),
                                  icon: Icon(_voiceBusy
                                      ? Icons.hearing
                                      : Icons.mic_none))))),
                  const SizedBox(width: 8),
                  IconButton.filledTonal(
                      tooltip: _ui('Send', 'بھیجیں'),
                      onPressed: _busy || _voiceBusy ? null : () => _send(),
                      icon:
                          Icon(_busy ? Icons.more_horiz : Icons.arrow_upward)),
                ]))),
      ]));
  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _version++;
    TtsService.stop();
    _query.dispose();
    _scroll.dispose();
    super.dispose();
  }
}
