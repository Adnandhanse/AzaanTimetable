import 'package:flutter/material.dart';
import '../models/hadith.dart';
import '../services/hadith_repository.dart';
import 'hadith_chapters_screen.dart';
import 'hadith_list_screen.dart';

/// Book opens directly into the All / Sahih / Zaeef reading layout.
class HadithGradeSectionsScreen extends StatefulWidget {
  const HadithGradeSectionsScreen({super.key, required this.book, required this.language});
  final HadithBook book;
  final HadithLanguage language;

  @override
  State<HadithGradeSectionsScreen> createState() => _HadithGradeSectionsScreenState();
}

class _HadithGradeSectionsScreenState extends State<HadithGradeSectionsScreen> {
  HadithCollection? _collection;
  bool _failed = false;
  bool get _urdu => widget.language == HadithLanguage.urdu;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _failed = false);
    try {
      final collection = await HadithRepository.loadCollection(widget.book, widget.language);
      if (mounted) setState(() => _collection = collection);
    } catch (_) {
      if (mounted) setState(() => _failed = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_collection != null) {
      return HadithListScreen(
        collection: _collection!,
        chapter: HadithChapter(number: -1, title: _urdu ? widget.book.urduName : widget.book.displayName),
        bookKey: widget.book.fileKey,
        language: _urdu ? 'urd' : 'eng',
        selectedHadiths: _collection!.hadiths,
        enableGradeTabs: true,
        onBrowseChapters: () => Navigator.of(context).push(MaterialPageRoute<void>(
          builder: (_) => HadithChaptersScreen(book: widget.book, language: widget.language))),
      );
    }
    return Scaffold(
      appBar: AppBar(title: Text(_urdu ? widget.book.urduName : widget.book.displayName)),
      body: _failed
          ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
              Text(_urdu ? 'کتاب لوڈ نہیں ہو سکی' : 'Could not load this book.'),
              TextButton(onPressed: _load, child: Text(_urdu ? 'دوبارہ کوشش کریں' : 'Try again')),
            ]))
          : const Center(child: CircularProgressIndicator()),
    );
  }
}
