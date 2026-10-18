import 'package:flutter/material.dart';
import '../models/hadith.dart';
import '../services/hadith_repository.dart';
import '../services/hadith_grade_sections.dart';
import 'hadith_chapters_screen.dart';

/// Book -> Sahih / Zaeef category -> original chapters -> original reading cards.
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

  void _open(HadithGradeSection? section) {
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) =>
      HadithChaptersScreen(book: widget.book, language: widget.language, gradeSection: section)));
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final counts = {for (final section in HadithGradeSection.values) section: 0};
    for (final item in _collection?.hadiths ?? <HadithItem>[]) {
      final grade = HadithGradeSections.classify(item, bookKey: widget.book.fileKey);
      if (grade != null) counts[grade] = counts[grade]! + 1;
    }
    return Scaffold(
      appBar: AppBar(title: Text(_urdu ? widget.book.urduName : widget.book.displayName)),
      body: _failed
          ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
              Text(_urdu ? 'کتاب لوڈ نہیں ہو سکی' : 'Could not load this book.'),
              TextButton(onPressed: _load, child: Text(_urdu ? 'دوبارہ کوشش کریں' : 'Try again')),
            ]))
          : _collection == null ? const Center(child: CircularProgressIndicator())
          : ListView(padding: const EdgeInsets.all(20), children: [
              Text(_urdu ? 'احادیث کا انتخاب کریں' : 'Choose a category',
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w600)),
              const SizedBox(height: 20),
              for (final section in HadithGradeSection.values)
                Padding(padding: const EdgeInsets.only(bottom: 16), child: Material(
                  color: section == HadithGradeSection.sahih
                    ? (dark ? const Color(0xFF244331) : const Color(0xFFE1ECD6))
                    : (dark ? const Color(0xFF49382F) : const Color(0xFFF7DFCE)),
                  borderRadius: BorderRadius.circular(20),
                  clipBehavior: Clip.antiAlias,
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 22, vertical: 22),
                    title: Text(section == HadithGradeSection.sahih
                      ? (_urdu ? 'صحیح احادیث' : 'Sahih hadith')
                      : (_urdu ? 'ضعیف احادیث' : 'Zaeef hadith'),
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600,
                        color: dark ? Colors.white : const Color(0xFF284C37))),
                    subtitle: Padding(padding: const EdgeInsets.only(top: 8),
                      child: Text('${counts[section]} ${_urdu ? 'احادیث' : 'hadith'}',
                        style: TextStyle(fontSize: 15, color: dark ? Colors.white70 : const Color(0xFF607262)))),
                    trailing: Icon(Icons.chevron_right, color: dark ? Colors.white70 : const Color(0xFF47664F)),
                    onTap: counts[section] == 0 ? null : () => _open(section),
                  ),
                )),
              const SizedBox(height: 12),
              OutlinedButton.icon(onPressed: () => _open(null),
                icon: const Icon(Icons.menu_book_outlined),
                label: Text(_urdu ? 'تمام ابواب دیکھیں' : 'Browse all chapters')),
              const SizedBox(height: 12),
              Text(HadithGradeSections.isSahihCollection(widget.book.fileKey)
                ? (_urdu ? 'اس صحیح مجموعے کی تمام احادیث صحیح حصے میں ہیں۔' : 'All entries in this Sahih collection are in the Sahih category.')
                : (_urdu ? 'حسن اور غیر واضح درجات تمام ابواب میں دستیاب ہیں۔ اصل درجات مکمل حدیث میں دیکھیں۔'
                  : 'Hasan and unclear grades remain available in all chapters. Detailed source gradings appear in the full hadith.'),
                style: TextStyle(fontSize: 12, color: dark ? Colors.white60 : const Color(0xFF728077))),
            ]),
    );
  }
}
