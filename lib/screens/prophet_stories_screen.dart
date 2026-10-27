import 'package:flutter/material.dart';
import '../models/prophet_story.dart';
import '../services/prophet_stories_repository.dart';
import '../theme/app_theme.dart';
import '../services/app_strings.dart';
import '../widgets/prophet_story_artwork.dart';
import '../widgets/prophet_places_map.dart';
import 'prophet_story_reader_screen.dart';

class ProphetStoriesScreen extends StatefulWidget {
  const ProphetStoriesScreen({super.key});
  @override
  State<ProphetStoriesScreen> createState() => _ProphetStoriesScreenState();
}

class _ProphetStoriesScreenState extends State<ProphetStoriesScreen> {
  List<ProphetStory>? _books;
  final _progress = <String, Map<String, dynamic>>{};
  String _query = '';
  bool _failed = false, _navigating = false, _showMap = true;
  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final books = await ProphetStoriesRepository.load();
      final progress = <String, Map<String, dynamic>>{};
      for (final b in books) {
        progress[b.id] = await ProphetStoryProgress.read(b.id);
      }
      if (mounted)
        setState(() {
          _books = books;
          _progress.addAll(progress);
          _failed = false;
        });
    } catch (_) {
      if (mounted) setState(() => _failed = true);
    }
  }

  Future<void> _open(ProphetStory story) async {
    if (_navigating) return;
    _navigating = true;
    try {
      final saved = _progress[story.id]?['page'];
      final index = story.pages.indexWhere((p) => p.id == saved);
      await Navigator.of(context).push(MaterialPageRoute<void>(
          builder: (_) => ProphetStoryReaderScreen(
              story: story, initialPage: index < 0 ? 0 : index)));
      if (mounted) await _load();
    } finally {
      _navigating = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final books = _books
        ?.where((b) =>
            b.name.toLowerCase().contains(_query.toLowerCase()) ||
            b.id.contains(_query.toLowerCase()))
        .toList();
    return Scaffold(
        appBar: AppBar(title: const Text('Prophet Stories')),
        body: _failed
            ? Center(
                child: TextButton(
                    onPressed: () {
                      setState(() => _failed = false);
                      _load();
                    },
                    child: Text(S.tr('Could not load stories · Try Again',
                        'کہانیاں لوڈ نہیں ہو سکیں · دوبارہ کوشش کریں'))))
            : books == null
                ? const Center(child: CircularProgressIndicator())
                : ListView(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
                    children: [
                        Wrap(spacing: 10, children: [
                          ChoiceChip(
                              label:
                                  Text(S.tr('Explore the Map', 'نقشہ دیکھیں')),
                              selected: _showMap,
                              onSelected: (_) =>
                                  setState(() => _showMap = true)),
                          ChoiceChip(
                              label: Text(S.tr('All Stories', 'تمام کہانیاں')),
                              selected: !_showMap,
                              onSelected: (_) =>
                                  setState(() => _showMap = false)),
                        ]),
                        const SizedBox(height: 18),
                        if (_showMap && _query.isEmpty) ...[
                          ProphetPlacesMap(stories: _books!, onOpen: _open),
                          const SizedBox(height: 24),
                        ],
                        Text(
                            S.tr(
                                '25 Prophets · Accounts from the Quran and authentic Hadith',
                                '۲۵ انبیاء · قرآن اور صحیح حدیث کے واقعات'),
                            style: TextStyle(fontSize: 14, height: 1.6)),
                        const SizedBox(height: 14),
                        TextField(
                            decoration: InputDecoration(
                                prefixIcon: const Icon(Icons.search),
                                hintText: S.tr('Search by Prophet’s Name',
                                    'نبی کا نام تلاش کریں'),
                                border: OutlineInputBorder()),
                            onChanged: (v) =>
                                setState(() => _query = v.trim())),
                        const SizedBox(height: 16),
                        if (books.isEmpty)
                          Text(S.tr(
                              'No stories found.', 'کوئی کہانی نہیں ملی۔')),
                        ...books.map((b) {
                          final saved = _progress[b.id] ?? {};
                          final done = saved['completed'] == true &&
                              saved['contentVersion'] == 4;
                          final index =
                              b.pages.indexWhere((p) => p.id == saved['page']);
                          return Card(
                              margin: const EdgeInsets.only(bottom: 14),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                  side: BorderSide(color: AppColors.goldRule)),
                              clipBehavior: Clip.antiAlias,
                              child: InkWell(
                                  onTap: () => _open(b),
                                  child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.stretch,
                                      children: [
                                        ProphetStoryArtwork(
                                            image: b.pages.first.image,
                                            title: b.name),
                                        Padding(
                                            padding: const EdgeInsets.fromLTRB(
                                                18, 14, 18, 18),
                                            child: Row(children: [
                                              Expanded(
                                                  child: Column(
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .start,
                                                      children: [
                                                    if (b
                                                        .teaser.isNotEmpty) ...[
                                                      const SizedBox(height: 8),
                                                      Text(
                                                          S.isUrdu
                                                              ? b.teaser
                                                              : b.openingEnglish
                                                                  .split('\n')
                                                                  .first,
                                                          maxLines: 3,
                                                          overflow: TextOverflow
                                                              .ellipsis,
                                                          style: AppText.body
                                                              .copyWith(
                                                                  height: 1.5,
                                                                  color: AppColors
                                                                      .textMid)),
                                                    ],
                                                    const SizedBox(height: 8),
                                                    Text(
                                                        '${b.pages.length} ${S.tr('chapters', 'حصے')} · English / Roman Urdu',
                                                        style: AppText.caption),
                                                    const SizedBox(height: 8),
                                                    Text(
                                                        done
                                                            ? S.tr('Read Again',
                                                                'دوبارہ پڑھیں')
                                                            : index >= 0
                                                                ? '${S.tr('Continue · Chapter', 'جاری رکھیں · حصہ')} ${index + 1}'
                                                                : S.tr(
                                                                    'Start Reading',
                                                                    'پڑھنا شروع کریں'),
                                                        style: AppText.body
                                                            .copyWith(
                                                                color: AppColors
                                                                    .emerald,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w600)),
                                                  ])),
                                              const SizedBox(width: 10),
                                              Icon(
                                                  done
                                                      ? Icons
                                                          .check_circle_outline
                                                      : Icons
                                                          .arrow_forward_rounded,
                                                  color: AppColors.gold),
                                            ])),
                                      ])));
                        }),
                        TextButton.icon(
                            onPressed: () => showDialog<void>(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                        title: Text(S.tr('About These Stories',
                                            'ان کہانیوں کے بارے میں')),
                                        content: SingleChildScrollView(
                                            child: Text(S.tr(
                                                'Accessible retellings of selected accounts from the Quran and Sahih al-Bukhari/Muslim. These are not word-for-word translations or complete historical biographies. Details of birth and childhood are included only where supported. Illustrations are artistic settings, not verified images of the original places. No people or animals are depicted.',
                                                'یہ قرآن اور صحیح بخاری و مسلم کے منتخب واقعات کا آسان بیان ہے، لفظی ترجمہ یا مکمل تاریخی سوانح نہیں۔ پیدائش اور بچپن کی تفصیل صرف ماخذ کی تائید کے ساتھ دی گئی ہے۔ تصاویر فنّی مناظر ہیں، اصل مقامات کی مصدقہ تصاویر نہیں۔'))),
                                        actions: [
                                          TextButton(
                                              onPressed: () =>
                                                  Navigator.pop(ctx),
                                              child: Text(
                                                  S.tr('Close', 'بند کریں')))
                                        ])),
                            icon: const Icon(Icons.info_outline),
                            label: Text(S.tr(
                                'Sources and Artwork', 'ماخذ اور تصاویر'))),
                      ]));
  }
}
