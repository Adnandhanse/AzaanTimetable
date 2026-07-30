import 'package:flutter/material.dart';
import '../models/hadith.dart';
import '../services/hadith_repository.dart';
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
      final collection = await HadithRepository.loadCollection(widget.book, widget.language);
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
    final chapters = _collection == null
        ? <HadithChapter>[]
        : _collection!.chapters.where((c) => c.title.toLowerCase().contains(_query.toLowerCase())).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.book.displayName),
        backgroundColor: const Color(0xFF1F5E4A),
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
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    itemCount: chapters.length,
                    itemBuilder: (context, index) {
                      final chapter = chapters[index];
                      final count = _collection!.hadithsInChapter(chapter.number).length;
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: const Color(0xFF1F5E4A),
                            foregroundColor: Colors.white,
                            child: Text('${chapter.number}', style: const TextStyle(fontSize: 12)),
                          ),
                          title: Text(chapter.title),
                          subtitle: Text('$count hadith(s)'),
                          trailing: const Icon(Icons.chevron_right),
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
