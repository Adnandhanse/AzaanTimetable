import 'package:flutter/material.dart';
import '../models/quran.dart';
import '../services/quran_repository.dart';
import '../services/quran_local_data_service.dart';
import '../data/juz_boundaries.dart';
import 'surah_detail_screen.dart';
import 'juz_detail_screen.dart';

class QuranHomeScreen extends StatefulWidget {
  const QuranHomeScreen({super.key});

  @override
  State<QuranHomeScreen> createState() => _QuranHomeScreenState();
}

class _QuranHomeScreenState extends State<QuranHomeScreen> with SingleTickerProviderStateMixin {
  QuranLanguage _language = QuranLanguage.english;
  List<Surah>? _surahs;
  String _query = '';
  Set<int> _favourites = {};
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _load();
    _loadFavourites();
  }

  Future<void> _load() async {
    final surahs = await QuranRepository.loadSurahs(_language);
    if (!mounted) return;
    setState(() => _surahs = surahs);
  }

  Future<void> _loadFavourites() async {
    final favs = await QuranLocalDataService.getFavourites();
    if (!mounted) return;
    setState(() => _favourites = favs);
  }

  Future<void> _toggleFavourite(int surahNumber) async {
    await QuranLocalDataService.toggleFavourite(surahNumber);
    _loadFavourites();
  }

  @override
  Widget build(BuildContext context) {
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
              PopupMenuItem(value: QuranLanguage.hindi, child: Text('हिन्दी (Hindi)')),
            ],
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFFD4AF37),
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'By Surah'),
            Tab(text: 'By Juz'),
            Tab(text: 'Favourites'),
          ],
        ),
      ),
      body: _surahs == null
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildSurahList(_surahs!),
                _buildJuzList(),
                _buildSurahList(_surahs!.where((s) => _favourites.contains(s.number)).toList(), isFavouriteTab: true),
              ],
            ),
    );
  }

  Widget _buildSurahList(List<Surah> surahs, {bool isFavouriteTab = false}) {
    final filtered = _query.isEmpty
        ? surahs
        : surahs.where((s) {
            final q = _query.toLowerCase();
            return s.transliteration.toLowerCase().contains(q) ||
                s.englishMeaning.toLowerCase().contains(q) ||
                s.number.toString() == q;
          }).toList();

    return Column(
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
          child: filtered.isEmpty
              ? Center(
                  child: Text(
                    isFavouriteTab ? 'No favourites yet.\nTap the heart on any Surah to save it here.' : 'No Surah found.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.grey),
                  ),
                )
              : ListView.builder(
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final surah = filtered[index];
                    final isFav = _favourites.contains(surah.number);
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: const Color(0xFF14532D),
                          foregroundColor: Colors.white,
                          child: Text('${surah.number}', style: const TextStyle(fontSize: 13)),
                        ),
                        title: Text(surah.transliteration, style: const TextStyle(fontWeight: FontWeight.w600)),
                        subtitle: Text('${surah.englishMeaning} • ${surah.totalVerses} verses'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(surah.arabicName, style: const TextStyle(fontSize: 18, fontFamily: 'serif')),
                            IconButton(
                              icon: Icon(isFav ? Icons.favorite : Icons.favorite_border, color: isFav ? Colors.red : Colors.grey),
                              onPressed: () => _toggleFavourite(surah.number),
                            ),
                          ],
                        ),
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => SurahDetailScreen(surah: surah)),
                        ),
                      ),
                    );
                  },
                ),
        ),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(
            'Text: quran-json (CC BY-SA 4.0) • Works fully offline',
            style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
          ),
        ),
      ],
    );
  }

  Widget _buildJuzList() {
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: juzBoundaries.length,
      itemBuilder: (context, index) {
        final (juzNum, startSurah, startVerse) = juzBoundaries[index];
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 4),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: const Color(0xFFD4AF37),
              child: Text('$juzNum', style: const TextStyle(color: Colors.black, fontSize: 13)),
            ),
            title: Text('Juz $juzNum'),
            subtitle: Text('Starts at Surah $startSurah, Ayah $startVerse'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => JuzDetailScreen(juzNumber: juzNum, allSurahs: _surahs!)),
            ),
          ),
        );
      },
    );
  }
}
