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
  Map<String, dynamic>? _lastRead;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _load();
    _loadFavourites();
    _loadLastRead();
  }

  Future<void> _loadLastRead() async {
    final data = await QuranLocalDataService.getLastRead();
    if (!mounted) return;
    setState(() => _lastRead = data);
  }

  Future<void> _resume() async {
    final Map<String, dynamic>? last = _lastRead;
    final List<Surah>? all = _surahs;
    if (last == null || all == null) return;

    final int number = last['surahNumber'] as int;
    final int? juz = last['juzNumber'] as int?;

    // Saved from inside a juz? Go back to the juz. Dropping the reader into a
    // lone surah loses the thing they were actually working through.
    if (juz != null) {
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => JuzDetailScreen(
            juzNumber: juz,
            allSurahs: all,
            initialSurahNumber: number,
            initialVerse: last['verseNumber'] as int?,
          ),
        ),
      );
      _loadLastRead();
      return;
    }

    // Plain loop rather than firstOrNull — that lives in package:collection,
    // which is not a direct dependency, and this is not worth adding one for.
    Surah? surah;
    for (final Surah candidate in all) {
      if (candidate.number == number) {
        surah = candidate;
        break;
      }
    }
    if (surah == null) return;

    // Copied into a final before the closure. Dart does not carry a local's
    // promoted non-null type into a closure body, because the closure may run
    // after the variable has been reassigned — so `surah` is still Surah? in
    // there, but `target` is plainly Surah.
    final Surah target = surah;

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => SurahDetailScreen(
          surah: target,
          initialOffset: (last['scrollOffset'] as num?)?.toDouble(),
          initialVerse: last['verseNumber'] as int?,
        ),
      ),
    );
    // The position moves while they read, so refresh the card on the way back.
    _loadLastRead();
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
                // ASPECT RATIO, NOT A FIXED HEIGHT.
                //
                // This was a 196px-tall box with BoxFit.cover. The artwork is
                // 1.70:1; the box on a typical phone is about 1.84:1. Cover
                // fills the width and then overflows vertically, so the top and
                // bottom of the picture were being cut off — the lanterns and
                // the base of the stand.
                //
                // AspectRatio makes the box the same shape as the image, so
                // cover has nothing left to crop and nothing is letterboxed
                // either. The height now follows the screen width instead of
                // being guessed.
                Container(
                  width: double.infinity,
                  color: AppColors.white,
                  child: AspectRatio(
                    aspectRatio: 1.70,
                    child: Image.asset(
                      'assets/images/quran_header.webp',
                      fit: BoxFit.cover,
                      semanticLabel: 'Illustration of the Qur\u2019an on a stand',
                    ),
                  ),
                ),
                // Rules removed. The artwork already ends on a hard edge and
                // the tab bar has its own indicator, so these were lines drawn
                // between things that were already separated.
                if (_lastRead != null) _buildContinueCard(),
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

  Widget _buildContinueCard() {
    final Map<String, dynamic> last = _lastRead!;
    final String name = (last['surahName'] as String?) ?? 'your last surah';
    final int? verse = last['verseNumber'] as int?;
    final int? juz = last['juzNumber'] as int?;
    final String where = juz == null ? name : 'Juz $juz  \u00b7  $name';

    // White card, gold hairline, emerald type — the same construction as every
    // other card in the app. The solid green block read as a banner from a
    // different product; this belongs to the palette instead of shouting over
    // it. The gold medallion is what draws the eye, not a slab of colour.
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
      child: Material(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(4),
        child: InkWell(
          onTap: _resume,
          borderRadius: BorderRadius.circular(4),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: AppColors.goldRule),
            ),
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
            child: Row(
              children: [
                const Medallion(icon: Icons.play_arrow_rounded, size: 36),
                const SizedBox(width: 13),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'CONTINUE READING',
                        style: AppText.eyebrow.copyWith(
                            letterSpacing: 1.5, color: AppColors.textMuted),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        verse == null ? where : '$where  \u00b7  Ayah $verse',
                        style: AppText.rowTitle
                            .copyWith(fontSize: 18, color: AppColors.emerald),
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
