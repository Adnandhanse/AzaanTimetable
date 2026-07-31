import 'package:flutter/material.dart';
import '../models/quran.dart';
import '../services/quran_repository.dart';
import '../services/quran_local_data_service.dart';
import '../services/app_strings.dart';
import '../data/juz_boundaries.dart';
import '../theme/app_theme.dart';
import '../widgets/ornaments.dart';
import 'surah_detail_screen.dart';
import 'juz_detail_screen.dart';

class QuranHomeScreen extends StatefulWidget {
  const QuranHomeScreen({super.key});

  @override
  State<QuranHomeScreen> createState() => _QuranHomeScreenState();
}

class _QuranHomeScreenState extends State<QuranHomeScreen>
    with SingleTickerProviderStateMixin {
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

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
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
        title: Text(S.quran),
        actions: [
          PopupMenuButton<QuranLanguage>(
            icon: const Icon(Icons.translate, size: 20),
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
      ),
      body: _surahs == null
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // The artwork carries the القرآن الكريم title itself, so
                // there is no text title here — it would double up.
                // BoxFit.contain, not cover: the image is square and the
                // header is a band, so cropping would cut the lanterns.
                // Its cream ground matches the palette, so the letterboxing
                // is invisible.
                Container(
                  width: double.infinity,
                  height: 186,
                  color: AppColors.white,
                  alignment: Alignment.center,
                  child: Image.asset(
                    'assets/images/quran_header.webp',
                    fit: BoxFit.contain,
                    height: 186,
                    semanticsLabel: 'Illustration of the Qur\u2019an on a stand',
                  ),
                ),
                Container(height: 1, color: AppColors.goldRule),
                Container(
                  color: AppColors.white,
                  child: TabBar(
                    controller: _tabController,
                    indicatorColor: AppColors.gold,
                    indicatorWeight: 2,
                    labelColor: AppColors.emerald,
                    unselectedLabelColor: AppColors.textMuted,
                    labelStyle: AppText.body.copyWith(fontSize: 12.5),
                    unselectedLabelStyle: AppText.body.copyWith(fontSize: 12.5),
                    tabs: [
                      Tab(text: S.bySurah),
                      Tab(text: S.byJuz),
                      Tab(text: S.favourites),
                    ],
                  ),
                ),
                Container(height: 1, color: AppColors.goldRule),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildSurahList(_surahs!),
                      _buildJuzList(),
                      _buildSurahList(
                        _surahs!
                            .where((s) => _favourites.contains(s.number))
                            .toList(),
                        isFavouriteTab: true,
                      ),
                    ],
                  ),
                ),
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
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 6),
          child: TextField(
            style: AppText.body,
            decoration: InputDecoration(
              hintText: S.searchSurahHint,
              hintStyle: AppText.body.copyWith(color: AppColors.textFaint),
              prefixIcon: const Icon(Icons.search,
                  size: 18, color: AppColors.textMuted),
              filled: true,
              fillColor: AppColors.white,
              isDense: true,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(4),
                borderSide: const BorderSide(color: AppColors.goldRule),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(4),
                borderSide: const BorderSide(color: AppColors.goldRule),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(4),
                borderSide: const BorderSide(color: AppColors.gold),
              ),
            ),
            onChanged: (v) => setState(() => _query = v),
          ),
        ),
        Expanded(
          child: filtered.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(28),
                    child: Text(
                      isFavouriteTab
                          ? 'No favourites yet.\nTap the heart on any Surah to save it here.'
                          : 'No Surah found.',
                      textAlign: TextAlign.center,
                      style:
                          AppText.body.copyWith(color: AppColors.textMuted),
                    ),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final surah = filtered[index];
                    final isFav = _favourites.contains(surah.number);
                    return Container(
                      decoration: BoxDecoration(
                        border: index == 0
                            ? null
                            : const Border(
                                top: BorderSide(
                                    color: AppColors.goldRuleFaint)),
                      ),
                      child: InkWell(
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                              builder: (_) => SurahDetailScreen(surah: surah)),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          child: Row(
                            children: [
                              Medallion(label: '${surah.number}'),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      surah.transliteration,
                                      style: AppText.rowTitle.copyWith(
                                          fontSize: 18, color: AppColors.text),
                                    ),
                                    Text(
                                      '${surah.englishMeaning} · ${surah.totalVerses} verses',
                                      style: AppText.caption.copyWith(
                                          color: AppColors.textMuted),
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                surah.arabicName,
                                style: AppText.arabic.copyWith(
                                  fontSize: 17,
                                  height: 1.3,
                                  color: AppColors.gold,
                                ),
                              ),
                              IconButton(
                                icon: Icon(
                                  isFav
                                      ? Icons.favorite
                                      : Icons.favorite_border,
                                  size: 18,
                                  color: isFav
                                      ? AppColors.emerald
                                      : AppColors.chevron,
                                ),
                                onPressed: () =>
                                    _toggleFavourite(surah.number),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 10),
          child: Text(
            'Text: quran-json (CC BY-SA 4.0) · Works fully offline',
            textAlign: TextAlign.center,
            style: AppText.caption.copyWith(color: AppColors.textFaint),
          ),
        ),
      ],
    );
  }

  Widget _buildJuzList() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      itemCount: juzBoundaries.length,
      itemBuilder: (context, index) {
        final (juzNum, startSurah, startVerse) = juzBoundaries[index];
        return Container(
          decoration: BoxDecoration(
            border: index == 0
                ? null
                : const Border(
                    top: BorderSide(color: AppColors.goldRuleFaint)),
          ),
          child: InkWell(
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) =>
                    JuzDetailScreen(juzNumber: juzNum, allSurahs: _surahs!),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Row(
                children: [
                  Medallion(label: '$juzNum'),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Juz $juzNum',
                          style: AppText.rowTitle
                              .copyWith(fontSize: 18, color: AppColors.text),
                        ),
                        Text(
                          'Starts at Surah $startSurah, Ayah $startVerse',
                          style: AppText.caption
                              .copyWith(color: AppColors.textMuted),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right,
                      size: 18, color: AppColors.chevron),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
