import 'package:flutter/material.dart';
import '../models/quran.dart';
import '../services/quran_repository.dart';
import 'surah_detail_screen.dart';

class QuranHomeScreen extends StatefulWidget {
  const QuranHomeScreen({super.key});

  @override
  State<QuranHomeScreen> createState() => _QuranHomeScreenState();
}

class _QuranHomeScreenState extends State<QuranHomeScreen> {
  QuranLanguage _language = QuranLanguage.english;
  List<Surah>? _surahs;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final surahs = await QuranRepository.loadSurahs(_language);
    if (!mounted) return;
    setState(() => _surahs = surahs);
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _surahs == null
        ? <Surah>[]
        : _surahs!.where((s) {
            if (_query.isEmpty) return true;
            final q = _query.toLowerCase();
            return s.transliteration.toLowerCase().contains(q) ||
                s.englishMeaning.toLowerCase().contains(q) ||
                s.number.toString() == q;
          }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Quran'),
        backgroundColor: const Color(0xFF14532D),
        foregroundColor: Colors.white,
        actions: [
          PopupMenuButton<QuranLanguage>(
            icon: const Icon(Icons.translate),
            onSelected: (lang) {
              setState(() {
                _language = lang;
                _surahs = null;
              });
              _load();
            },
            itemBuilder: (_) => const [
              PopupMenuItem(value: QuranLanguage.english, child: Text('English')),
              PopupMenuItem(value: QuranLanguage.urdu, child: Text('اردو (Urdu)')),
            ],
          ),
        ],
      ),
      body: _surahs == null
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: TextField(
                    decoration: const InputDecoration(
                      hintText: 'Search Surah by name or number',
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (v) => setState(() => _query = v),
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final surah = filtered[index];
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: const Color(0xFF14532D),
                          foregroundColor: Colors.white,
                          child: Text('${surah.number}', style: const TextStyle(fontSize: 13)),
                        ),
                        title: Text(surah.transliteration, style: const TextStyle(fontWeight: FontWeight.w600)),
                        subtitle: Text('${surah.englishMeaning} • ${surah.totalVerses} verses'),
                        trailing: Text(
                          surah.arabicName,
                          style: const TextStyle(fontSize: 18, fontFamily: 'serif'),
                        ),
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => SurahDetailScreen(surah: surah)),
                        ),
                      );
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    'Text source: quran-json (CC BY-SA 4.0) - works fully offline',
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                  ),
                ),
              ],
            ),
    );
  }
}
