import 'dart:async';
import 'dart:convert';
import 'dart:isolate';
import 'package:flutter/services.dart';

/// Search only: never generates a ruling, translation or explanation.
/// The worker lives only while this search screen is open. Parsing and ranking
/// all six books happen off the UI isolate; only the best 40 hits cross back.
class AskConnectSearch {
  Isolate? _worker;
  ReceivePort? _receive;
  SendPort? _send;
  final _pending = <int, Completer<Map<String, dynamic>>>{};
  int _sequence = 0;
  bool _closed = false;
  Future<void>? _loading;
  int count = 0;

  Future<void> load(void Function(String) progress) =>
      _loading ??= _load(progress);

  Future<void> _load(void Function(String) progress) async {
    final ready = Completer<SendPort>();
    final receive = ReceivePort();
    _receive = receive;
    receive.listen((dynamic message) {
      if (message is SendPort) {
        if (!ready.isCompleted) ready.complete(message);
      } else if (message is Map) {
        final reply = Map<String, dynamic>.from(message);
        final c = _pending.remove(reply['id']);
        if (reply['error'] != null) {
          c?.completeError(StateError(reply['error'].toString()));
        } else {
          c?.complete(reply);
        }
      }
    });
    final worker = await Isolate.spawn(_askSearchWorker, receive.sendPort);
    if (_closed) { worker.kill(); throw StateError('Search closed'); }
    _worker = worker;
    _send = await ready.future.timeout(const Duration(seconds: 20));
    progress('Quran tayyar ho raha hai…');
    final en = await rootBundle.loadString('assets/quran/quran_en.json', cache: false);
    final ur = await rootBundle.loadString('assets/quran/quran_ur.json', cache: false);
    await _request({'op': 'quran', 'en': en, 'ur': ur});
    for (final book in ['bukhari', 'muslim', 'abudawud', 'tirmidhi', 'nasai', 'ibnmajah']) {
      if (_closed) throw StateError('Search closed');
      progress('Hadees library: $book…');
      final english = await rootBundle.loadString('assets/hadith/eng_$book.json', cache: false);
      final urdu = await rootBundle.loadString('assets/hadith/urd_$book.json', cache: false);
      final arabic = await rootBundle.loadString('assets/hadith/ara_$book.json', cache: false);
      final reply = await _request({'op': 'book', 'book': book,
        'en': english, 'ur': urdu, 'ar': arabic});
      count = reply['count'] as int;
    }
  }

  Future<Map<String, dynamic>> _request(Map<String, dynamic> data) async {
    if (_closed || _send == null) throw StateError('Search unavailable');
    final id = ++_sequence;
    final c = Completer<Map<String, dynamic>>();
    _pending[id] = c;
    _send!.send({...data, 'id': id});
    try { return await c.future.timeout(const Duration(seconds: 60)); }
    finally { _pending.remove(id); }
  }

  Future<Map<String, dynamic>> search(String query, String kind) =>
      _request({'op': 'search', 'query': query, 'kind': kind});

  void dispose() {
    _closed = true;
    _worker?.kill(priority: Isolate.immediate);
    _receive?.close();
    for (final c in _pending.values) {
      if (!c.isCompleted) c.completeError(StateError('Search closed'));
    }
    _pending.clear();
  }
}

String normalizeAskText(String value) => value.toLowerCase()
    .replaceAll(RegExp(r'[\u064B-\u065F\u0670\u06D6-\u06ED]'), '')
    .replaceAll(RegExp(r'[؀-؅؉-؍؛-؟٪-٭۔]'), ' ')
    .replaceAll('ي', 'ی').replaceAll('ى', 'ی').replaceAll('ك', 'ک')
    .replaceAll(RegExp(r'[^a-z0-9\u0600-\u06FF\u0900-\u097F]+'), ' ')
    .replaceAll(RegExp(r'\s+'), ' ').trim();

/// Curated vocabulary bridges, not an LLM. Specific concepts are mandatory:
/// a finger question cannot return a hadith merely because it says "prayer".
const askConcepts = <List<String>>[
  ['namaz', 'namaaz', 'salah', 'salat', 'prayer', 'prayers', 'praying', 'prays', 'نماز', 'صلاۃ', 'नमाज', 'नमाज़'],
  ['ungli', 'unglee', 'finger', 'fingers', 'forefinger', 'انگلی', 'انگلیوں', 'उंगली', 'उँगली'],
  ['harkat', 'hilana', 'hilaana', 'movement', 'moving', 'move', 'moved', 'حرکت', 'ہلانا', 'ہلانے', 'ہلاتے', 'हिलाना', 'हिलाने', 'हिलाते', 'हरकत'],
  ['tashahhud', 'tashahud', 'تشہد', 'तशह्हुद'],
  ['sabr', 'sabar', 'patience', 'patient', 'صبر', 'صابر', 'सब्र'],
  ['gussa', 'ghussa', 'anger', 'angry', 'غصہ', 'غصے', 'غضب', 'गुस्सा'],
  ['walidain', 'parents', 'parent', 'والدین', 'माता', 'पिता'],
  ['maa', 'ammi', 'mother', 'mothers', 'ماں', 'والدہ', 'माँ', 'मां'],
  ['baap', 'abbu', 'father', 'fathers', 'باپ', 'والد', 'पिता'],
  ['roza', 'roze', 'fasting', 'fast', 'روزہ', 'روزے', 'صوم', 'रोजा', 'रोज़ा'],
  ['zakat', 'zakaat', 'زکوۃ', 'زکاة', 'زکوٰۃ', 'जकात'],
  ['sadqa', 'sadaqah', 'charity', 'صدقة', 'صدقہ', 'خیرات', 'दान'],
  ['wudu', 'wuzu', 'ablution', 'ablutions', 'وضو', 'वुजू'],
  ['niyat', 'niyyah', 'intention', 'intentions', 'نیت', 'نیتوں', 'नीयत'],
  ['sach', 'truth', 'truthful', 'سچ', 'سچائی', 'सच'],
  ['jhoot', 'jhut', 'lie', 'lies', 'lying', 'جھوٹ', 'झूठ'],
  ['padosi', 'neighbour', 'neighbor', 'neighbours', 'neighbors', 'پڑوسی', 'पड़ोसी'],
  ['shukr', 'gratitude', 'grateful', 'شکر', 'شکرگزار', 'शुक्र'],
  ['maafi', 'forgive', 'forgiveness', 'معافی', 'معاف', 'مغفرت', 'माफी'],
  ['dua', 'duaa', 'supplication', 'supplicate', 'دعا', 'دعاء', 'दुआ'],
  ['safai', 'cleanliness', 'clean', 'صفائی', 'پاکیزگی', 'सफाई'],
  ['rahmat', 'mercy', 'merciful', 'رحمت', 'رحم', 'रहमत'],
  ['rizq', 'provision', 'sustenance', 'رزق', 'रिज्क'],
  ['qarz', 'debt', 'debts', 'قرض', 'कर्ज'],
  ['nikah', 'marriage', 'marry', 'نکاح', 'شادی', 'निकाह'],
  ['salam', 'greeting', 'greetings', 'سلام', 'सलाम'],
  ['hasad', 'envy', 'jealousy', 'حسد', 'حسद'],
  ['gheebat', 'ghibat', 'backbiting', 'غیبت', 'गीबत'],
];
const _askStop = 'a an the of in on at to and or about how what is are does do should '
    'can i me please tell hadith hadees hadiths quran ayat verse verses hukum hukm '
    'ka ki ke ko se mein mai me hai hain kya kaise bare baare batao bataye dene '
    'karna karne k liye kuch chahiye mujhe do '
    'کے کی کا کو میں سے ہے ہیں کیا کیسے بارے حکم حدیث قرآن بتائیں دینے کرنا کریں چاہیے مجھے '
    'का की के में से है हैं क्या कैसे बारे हुक्म हुकुम हदीस बताओ देने करना चाहिए मुझे';

List<List<String>> askQueryGroups(String query) {
  final words = normalizeAskText(query).split(' ');
  final stop = normalizeAskText(_askStop).split(' ').toSet();
  final groups = <List<String>>[];
  final seen = <int>{};
  for (final word in words) {
    if (word.isEmpty || stop.contains(word)) continue;
    final index = askConcepts.indexWhere((g) => g.map(normalizeAskText).contains(word));
    if (index >= 0) {
      if (seen.add(index)) groups.add(askConcepts[index].map(normalizeAskText).toList());
    } else if (word.length >= 2) {
      if (!groups.any((g) => g.length == 1 && g.single == word)) groups.add([word]);
    }
  }
  return groups;
}

class _AskDocument {
  _AskDocument(this.data) : normalized = ' ${normalizeAskText(
      '${data['en']} ${data['ur']} ${data['ar']} ${data['context'] ?? ''}')} ';
  final Map<String, dynamic> data;
  final String normalized;
}

int _number(dynamic n) => n is num ? n.toInt() : int.parse(n.toString());
void _askSearchWorker(SendPort host) {
  final port = ReceivePort();
  final documents = <_AskDocument>[];
  host.send(port.sendPort);
  port.listen((dynamic raw) {
    final m = raw as Map;
    try {
      if (m['op'] == 'quran') {
        final en = jsonDecode(m['en'] as String) as List;
        final ur = jsonDecode(m['ur'] as String) as List;
        final urBySurah = {for (final s in ur) _number(s['id']): s};
        for (final s in en) {
          final u = urBySurah[_number(s['id'])];
          final translations = {for (final v in (u?['verses'] as List? ?? [])) _number(v['id']): v['translation']};
          for (final v in s['verses']) {
            documents.add(_AskDocument({'kind': 'quran', 'surah': _number(s['id']),
              'number': _number(v['id']), 'title': s['transliteration'],
              'en': v['translation'] ?? '', 'ur': translations[_number(v['id'])] ?? '',
              'ar': v['text'] ?? '', 'grades': <String>[]}));
          }
        }
      } else if (m['op'] == 'book') {
        final en = jsonDecode(m['en'] as String) as Map;
        final ur = jsonDecode(m['ur'] as String) as Map;
        final ar = jsonDecode(m['ar'] as String) as Map;
        final urItems = {for (final h in ur['hadiths']) _number(h['hadithnumber']): h};
        final arItems = {for (final h in ar['hadiths']) _number(h['hadithnumber']): h};
        final enItems = {for (final h in en['hadiths']) _number(h['hadithnumber']): h};
        // Include new references present in either translation; never create IDs.
        final numbers = {...enItems.keys, ...urItems.keys}.toList()..sort();
        for (final n in numbers) {
          final e = enItems[n]; final u = urItems[n]; final a = arItems[n];
          final english = (e?['text'] ?? '').toString();
          final urdu = (u?['text'] ?? '').toString();
          final arabic = (a?['text'] ?? '').toString();
          if ('$english$urdu$arabic'.trim().isEmpty) continue;
          final chapter = (e?['reference']?['book'] ?? u?['reference']?['book'] ?? 0).toString();
          final section = en['metadata']?['sections']?[chapter] ?? '';
          final grades = <String>{};
          for (final h in [e, u, a]) {
            for (final g in (h?['grades'] as List? ?? [])) {
              final label = '${g['grade'] ?? ''} — ${g['name'] ?? ''}';
              if (label.replaceAll('—', '').trim().isNotEmpty) grades.add(label);
            }
          }
          documents.add(_AskDocument({'kind': 'hadith', 'book': m['book'],
            'number': n, 'title': en['metadata']['name'], 'en': english,
            'ur': urdu, 'ar': arabic, 'context': section, 'grades': grades.toList()}));
        }
      } else if (m['op'] == 'search') {
        final groups = askQueryGroups(m['query'] as String);
        final matches = <(int, _AskDocument)>[];
        final prayerFinger = groups.any((g) => g.contains('namaz')) &&
            groups.any((g) => g.contains('ungli'));
        if (groups.isNotEmpty && groups.length <= 12) {
          for (final doc in documents) {
            if (m['kind'] != 'all' && doc.data['kind'] != m['kind']) continue;
            var score = 0; var all = true;
            for (final group in groups) {
              final hits = group.where((term) => doc.normalized.contains(' $term ')).length;
              if (hits == 0) { all = false; break; }
              score += 10 + (hits > 3 ? 3 : hits);
            }
            if (all) {
              // A common specific topic: promote seated-prayer narrations over
              // long reports that mention fingers and prayer in unrelated parts.
              if (prayerFinger && ['tashahhud', 'tashahud', 'تشہد'].any(
                  (word) => doc.normalized.contains(' $word '))) score += 30;
              if (doc.data['book'] == 'bukhari' || doc.data['book'] == 'muslim') score += 1;
              matches.add((score, doc));
            }
          }
        }
        matches.sort((a, b) {
          final ranking = b.$1.compareTo(a.$1);
          return ranking != 0 ? ranking : a.$2.normalized.length.compareTo(b.$2.normalized.length);
        });
        host.send({'id': m['id'], 'total': matches.length,
          'terms': groups.map((g) => g.first).toList(),
          'hits': matches.take(40).map((r) => r.$2.data).toList()});
        return;
      }
      host.send({'id': m['id'], 'count': documents.length});
    } catch (e) { host.send({'id': m['id'], 'error': e.toString()}); }
  });
}
