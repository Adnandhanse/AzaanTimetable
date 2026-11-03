import 'package:flutter/material.dart';
import '../data/tajweed_data.dart';
import '../data/sajdah_verses.dart';
import '../data/ruku_boundaries.dart';
import '../models/quran.dart';
import '../services/quran_repository.dart';

/// Dedicated edition: annotations must never be applied to another Arabic text.
class TajweedReaderScreen extends StatefulWidget {
  const TajweedReaderScreen({super.key});
  @override
  State<TajweedReaderScreen> createState() => _TajweedReaderScreenState();
}

class _TajweedReaderScreenState extends State<TajweedReaderScreen> {
  final _surahs = QuranRepository.loadSurahs(QuranLanguage.english);
  final _scroll = ScrollController();
  int _surah = 1;

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  Color _colour(String rule, bool dark) {
    if (rule == 'qalqalah') return dark ? Colors.cyanAccent : const Color(0xFF006D9C);
    if (rule == 'iqlab') return dark ? Colors.purpleAccent.shade100 : const Color(0xFF8A289B);
    if (rule.startsWith('madd')) return dark ? Colors.redAccent.shade100 : const Color(0xFFB52832);
    if (rule == 'hamzat_wasl' || rule == 'lam_shamsiyyah' || rule == 'silent') {
      return dark ? Colors.grey.shade400 : Colors.grey.shade700;
    }
    return dark ? Colors.greenAccent.shade100 : const Color(0xFF147347);
  }

  List<InlineSpan> _spans(List<dynamic> row, bool dark) {
    final text = row[0] as String;
    final chars = text.runes.toList(growable: false);
    final marks = List<String?>.filled(chars.length, null);
    for (final dynamic item in row[1] as List<dynamic>) {
      final a = item as List<dynamic>;
      final start = a[0] as int;
      final end = a[1] as int;
      if (start < 0 || end > chars.length || start >= end) {
        return [TextSpan(text: text)];
      }
      for (int i = start; i < end; i++) {
        marks[i] = a[2] as String;
      }
    }
    final result = <InlineSpan>[];
    int start = 0;
    while (start < chars.length) {
      int end = start + 1;
      while (end < chars.length && marks[end] == marks[start]) {
        end++;
      }
      result.add(TextSpan(
        text: String.fromCharCodes(chars.sublist(start, end)),
        style: marks[start] == null ? null : TextStyle(color: _colour(marks[start]!, dark)),
      ));
      start = end;
    }
    return result;
  }

  void _credits() {
    showDialog<void>(context: context, builder: (context) => AlertDialog(
      title: const Text('Tajweed colours'),
      content: const SingleChildScrollView(child: Text(
        'Green: ghunnah, ikhfa and idghaam groups\n'
        'Red: madd\nBlue: qalqalah\nPurple: iqlab\nGrey: silent/connecting letters\n\n'
        'Arabic: Tanzil.net, pinned 2017 Uthmani edition. '
        'Annotations: Collin Fair / cpfair/quran-tajweed, CC BY 4.0. '
        'Colours are grouped for this app; other Mushafs may use different colours. '
        'The source is not actively maintained. Colours are a reading aid; '
        'learn pronunciation with a qualified teacher.')),
      actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close'))],
    ));
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      appBar: AppBar(title: const Text('Colour Tajweed'), actions: [
        IconButton(onPressed: _credits, tooltip: 'Colours and sources', icon: const Icon(Icons.info_outline)),
      ]),
      body: FutureBuilder<List<Surah>>(
        future: _surahs,
        builder: (context, snapshot) {
          if (snapshot.hasError) return const Center(child: Text('Could not open Quran. Please try again.'));
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final surahs = snapshot.data!;
          final selected = surahs.firstWhere((s) => s.number == _surah);
          return Column(children: [
            Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: DropdownButton<int>(
              value: _surah, isExpanded: true,
              items: surahs.map((s) => DropdownMenuItem(value: s.number,
                child: Text('${s.number}. ${s.transliteration}'))).toList(),
              onChanged: (value) {
                if (value == null) return;
                setState(() => _surah = value);
                if (_scroll.hasClients) _scroll.jumpTo(0);
              },
            )),
            Expanded(child: ListView.builder(
              controller: _scroll,
              itemCount: selected.totalVerses,
              itemBuilder: (context, index) {
                final row = tajweedData['$_surah:${index + 1}'];
                if (row == null) return const ListTile(title: Text('Verse unavailable'));
                return Padding(padding: const EdgeInsets.fromLTRB(18, 12, 18, 12), child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text('$_surah:${index + 1}', style: Theme.of(context).textTheme.labelMedium),
                    if (SajdahVerses.isSajdah(_surah, index + 1))
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Text(
                          '۩ Sajdah — سجدہ' +
                            (SajdahVerses.noteFor(_surah, index + 1) == null
                              ? '' : '\n${SajdahVerses.noteFor(_surah, index + 1)}'),
                          style: TextStyle(fontWeight: FontWeight.bold,
                            color: dark ? Colors.orangeAccent : const Color(0xFF9C4210)),
                        ),
                      ),
                    if (isRukuEnd(_surah, index + 1))
                      const Text('ع • Ruku end'),
                    const SizedBox(height: 8),
                    Text.rich(TextSpan(children: _spans(row, dark)),
                      textDirection: TextDirection.rtl, textAlign: TextAlign.right,
                      style: TextStyle(fontFamily: 'Amiri', fontSize: 26, height: 1.9,
                        color: Theme.of(context).colorScheme.onSurface)),
                    const Divider(height: 28),
                  ],
                ));
              },
            )),
          ]);
        },
      ),
    );
  }
}
