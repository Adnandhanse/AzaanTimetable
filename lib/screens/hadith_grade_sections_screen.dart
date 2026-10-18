import 'package:flutter/material.dart';
import '../models/hadith.dart';
import '../services/hadith_repository.dart';
import '../services/hadith_grade_sections.dart';
import 'hadith_chapters_screen.dart';
import 'hadith_list_screen.dart';

class HadithGradeSectionsScreen extends StatefulWidget {
  const HadithGradeSectionsScreen({super.key, required this.book, required this.language});
  final HadithBook book;
  final HadithLanguage language;

  @override
  State<HadithGradeSectionsScreen> createState() => _HadithGradeSectionsScreenState();
}

class _HadithGradeSectionsScreenState extends State<HadithGradeSectionsScreen> {
  HadithCollection? _collection;
  Map<HadithGradeSection, List<HadithItem>>? _groups;
  bool _failed = false;
  bool get _urdu => widget.language == HadithLanguage.urdu;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _failed = false);
    try {
      final collection = await HadithRepository.loadCollection(widget.book, widget.language);
      final groups = HadithGradeSections.group(collection);
      if (!mounted) return;
      setState(() { _collection = collection; _groups = groups; });
    } catch (_) {
      if (mounted) setState(() => _failed = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colours = <Color>[
      const Color(0xFFDCE6CE), const Color(0xFFD5E4F2), const Color(0xFFF6DDCD),
      const Color(0xFFE5DCF1), const Color(0xFFF8EBBD), const Color(0xFFF2E7DE),
    ];
    return Scaffold(
      appBar: AppBar(title: Text(_urdu ? widget.book.urduName : widget.book.displayName)),
      body: _failed
          ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
              Text(_urdu ? 'کتاب لوڈ نہیں ہو سکی' : 'Could not load this book.'),
              TextButton(onPressed: _load, child: Text(_urdu ? 'دوبارہ کوشش کریں' : 'Try again')),
            ]))
          : _groups == null
              ? const Center(child: CircularProgressIndicator())
              : ListView(padding: const EdgeInsets.all(20), children: [
                  Text(_urdu ? 'درجے کے مطابق پڑھیں' : 'Browse by grade',
                    style: const TextStyle(fontFamily: 'Inter', fontSize: 23, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 10),
                  Text(_urdu
                    ? 'یہ تقسیم ایپ کے ماخذ میں موجود درجات پر مبنی ہے۔ مرکب یا صرف سند کے درجات دیگر درجات میں ہیں۔ ہر حدیث کے ساتھ اصل درجہ اور عالم کا نام موجود ہے۔'
                    : 'Sections follow the grades supplied in the bundled hadith-api data. Compound and chain-only labels stay under Other grades. Original labels and scholar names remain with each hadith.'),
                  const SizedBox(height: 12),
                  if (_groups![HadithGradeSection.ungraded]!.length == _collection!.hadiths.length)
                    Padding(padding: const EdgeInsets.only(bottom: 16), child: Text(_urdu
                      ? 'اس کتاب کے موجودہ ڈیٹا میں انفرادی درجات شامل نہیں ہیں۔ درجہ دستیاب نہ ہونے کا مطلب ضعیف ہونا نہیں ہے۔'
                      : 'This book’s bundled data has no individual grades. Missing grading does not mean a hadith is weak.')),
                  for (final section in HadithGradeSection.values)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Material(
                        color: colours[section.index],
                        borderRadius: BorderRadius.circular(18),
                        clipBehavior: Clip.antiAlias,
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                          title: Text(section.title(_urdu), style: const TextStyle(
                            color: Color(0xFF253D36), fontSize: 17, fontWeight: FontWeight.w600)),
                          subtitle: Text('${_groups![section]!.length} ${_urdu ? 'احادیث' : 'hadith'}',
                              style: const TextStyle(color: Color(0xFF45544E))),
                          trailing: const Icon(Icons.chevron_right, color: Color(0xFF45544E)),
                          onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(
                            builder: (_) => HadithListScreen(
                              collection: _collection!,
                              chapter: HadithChapter(number: -1, title: section.title(_urdu)),
                              bookKey: widget.book.fileKey,
                              language: _urdu ? 'urd' : 'eng',
                              selectedHadiths: _groups![section]!,
                            ),
                          )),
                        ),
                      ),
                    ),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    icon: const Icon(Icons.menu_book_outlined),
                    label: Text(_urdu ? 'تمام ابواب دیکھیں' : 'Browse all chapters'),
                    onPressed: () => Navigator.of(context).push(MaterialPageRoute<void>(
                      builder: (_) => HadithChaptersScreen(book: widget.book, language: widget.language))),
                  ),
                ]),
    );
  }
}
