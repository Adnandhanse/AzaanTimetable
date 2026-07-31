import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/hadith.dart';
import '../services/hadith_repository.dart';
import '../services/hadith_section_titles.dart';
import '../widgets/ornaments.dart';
import 'hadith_list_screen.dart';
import 'hadith_search_screen.dart';

class HadithChaptersScreen extends StatefulWidget {
  final HadithBook book;
  final HadithLanguage language;

  const HadithChaptersScreen({super.key, required this.book, required this.language});

  @override
  State<HadithChaptersScreen> createState() => _HadithChaptersScreenState();
}

class _HadithChaptersScreenState extends State<HadithChaptersScreen> {
  HadithCollection? _collection;
  String? _error;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      await HadithSectionTitles.load();
      final collection =
          await HadithRepository.loadCollection(widget.book, widget.language);
      if (!mounted) return;
      setState(() => _collection = collection);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    }
  }

  String get _langCode => widget.language == HadithLanguage.english ? 'eng' : 'urd';

  @override
  Widget build(BuildContext context) {
    // Titles are resolved through the Urdu override before filtering, so the
    // filter matches what the reader can actually see.
    String displayTitle(HadithChapter c) => HadithSectionTitles.resolve(
          book: widget.book,
          sectionNumber: c.number,
          language: widget.language,
          englishTitle: c.title,
        );

    final chapters = _collection == null
        ? <HadithChapter>[]
        : _collection!.chapters
            .where((c) => displayTitle(c)
                .toLowerCase()
                .contains(_query.toLowerCase()))
            .toList();

    final bool urduTitlesMissing = widget.language == HadithLanguage.urdu &&
        HadithSectionTitles.overrideCount(widget.book) == 0;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.book.displayName),
        backgroundColor: AppColors.emerald,
        foregroundColor: Colors.white,
        actions: [
          if (_collection != null)
            IconButton(
              icon: const Icon(Icons.search),
              tooltip: 'Search hadith text',
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => HadithSearchScreen(
                    collection: _collection!,
                    bookKey: widget.book.fileKey,
                    language: _langCode,
                  ),
                ),
              ),
            ),
        ],
      ),
      body: _error != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, color: Colors.red, size: 40),
                    const SizedBox(height: 12),
                    Text('Could not load this book:\n$_error', textAlign: TextAlign.center),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        setState(() => _error = null);
                        _load();
                      },
                      child: const Text('Try Again'),
                    ),
                  ],
                ),
              ),
            )
          : _collection == null
              ? const Center(child: CircularProgressIndicator())
              : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: TextField(
                    decoration: const InputDecoration(
                      hintText: 'Filter chapters by name',
                      prefixIcon: Icon(Icons.filter_list),
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (v) => setState(() => _query = v),
                  ),
                ),
                if (urduTitlesMissing)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                    child: Text(
                      'Chapter names are shown in English \u2014 the offline hadith dataset does not include Urdu chapter names. The hadith text itself is in Urdu.',
                      style: AppText.caption
                          .copyWith(color: AppColors.textMuted),
                    ),
                  ),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: chapters.length,
                    itemBuilder: (context, index) {
                      final chapter = chapters[index];
                      final count = _collection!.hadithsInChapter(chapter.number).length;
                      return Container(
                        decoration: BoxDecoration(
                          border: index == 0
                              ? null
                              : const Border(
                                  top: BorderSide(
                                      color: AppColors.goldRuleFaint)),
                        ),
                        child: ListTile(
                          contentPadding:
                              const EdgeInsets.symmetric(vertical: 4),
                          leading: Medallion(label: '${chapter.number}'),
                          title: Text(
                            displayTitle(chapter),
                            style: AppText.rowTitle
                                .copyWith(fontSize: 17, color: AppColors.text),
                          ),
                          subtitle: Text(
                            '$count hadith',
                            style: AppText.caption
                                .copyWith(color: AppColors.textMuted),
                          ),
                          trailing: const Icon(Icons.chevron_right,
                              size: 18, color: AppColors.chevron),
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => HadithListScreen(
                                collection: _collection!,
                                chapter: chapter,
                                bookKey: widget.book.fileKey,
                                language: _langCode,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }
}
