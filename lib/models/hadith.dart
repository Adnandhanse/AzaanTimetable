import '../services/app_strings.dart';
import 'dart:convert';

enum HadithBook { bukhari, muslim, abudawud, tirmidhi, nasai, ibnmajah }

extension HadithBookInfo on HadithBook {
  /// The book's name in Urdu script.
  ///
  /// These are the standard Urdu renderings of the titles. The titles are Arabic
  /// proper names, so writing them in Urdu script is transliteration, not
  /// translation — there is no scholarly judgement involved and nothing to get
  /// wrong.
  String get urduName {
    switch (this) {
      case HadithBook.bukhari:
        return 'صحیح بخاری';
      case HadithBook.muslim:
        return 'صحیح مسلم';
      case HadithBook.abudawud:
        return 'سنن ابو داؤد';
      case HadithBook.tirmidhi:
        return 'جامع ترمذی';
      case HadithBook.nasai:
        return 'سنن نسائی';
      case HadithBook.ibnmajah:
        return 'سنن ابن ماجہ';
    }
  }

  /// Whichever name matches the app language. Use this in the UI; use
  /// [displayName] only where an English identifier is wanted, such as a log.
  String get localName => S.isUrdu ? urduName : displayName;

  String get displayName {
    switch (this) {
      case HadithBook.bukhari:
        return 'Sahih al-Bukhari';
      case HadithBook.muslim:
        return 'Sahih Muslim';
      case HadithBook.abudawud:
        return 'Sunan Abu Dawud';
      case HadithBook.tirmidhi:
        return "Jami' at-Tirmidhi";
      case HadithBook.nasai:
        return "Sunan an-Nasa'i";
      case HadithBook.ibnmajah:
        return 'Sunan Ibn Majah';
    }
  }

  String get fileKey {
    switch (this) {
      case HadithBook.bukhari:
        return 'bukhari';
      case HadithBook.muslim:
        return 'muslim';
      case HadithBook.abudawud:
        return 'abudawud';
      case HadithBook.tirmidhi:
        return 'tirmidhi';
      case HadithBook.nasai:
        return 'nasai';
      case HadithBook.ibnmajah:
        return 'ibnmajah';
    }
  }
}

enum HadithLanguage { english, urdu }

class HadithChapter {
  final int number;
  final String title;

  HadithChapter({required this.number, required this.title});
}

class HadithItem {
  final int hadithNumber;
  final int? arabicNumber;
  final int chapterNumber;
  final String arabicText;
  final String text;
  final List<String> grades;

  HadithItem({
    required this.hadithNumber,
    this.arabicNumber,
    required this.chapterNumber,
    required this.arabicText,
    required this.text,
    required this.grades,
  });

  factory HadithItem.fromJson(Map<String, dynamic> json, {String arabicText = ''}) => HadithItem(
        hadithNumber: _toInt(json['hadithnumber']),
        arabicNumber: json['arabicnumber'] != null ? _toInt(json['arabicnumber']) : null,
        chapterNumber: _toInt(json['reference']?['book']),
        arabicText: arabicText,
        text: json['text'] ?? '',
        grades: (json['grades'] as List? ?? [])
            .map((g) => '${g['grade'] ?? ''} - ${g['name'] ?? ''}'.trim())
            .where((g) => g.isNotEmpty && g != '-')
            .toList(),
      );

  /// Some editions in this dataset encode numbers as doubles (e.g. 1.0)
  /// instead of plain integers - this safely handles either format
  /// instead of crashing with a type-cast error.
  static int _toInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is num) return value.toInt();
    return int.tryParse(value.toString()) ?? 0;
  }
}

class HadithCollection {
  final String name;
  final List<HadithChapter> chapters;
  final List<HadithItem> hadiths;

  HadithCollection({required this.name, required this.chapters, required this.hadiths});

  factory HadithCollection.fromJson(Map<String, dynamic> json, {Map<String, dynamic>? arabicJson}) {
    final metadata = json['metadata'];
    final sections = Map<String, dynamic>.from(metadata['sections'] ?? {});
    final chapters = sections.entries
        .where((e) => e.value != null && e.value.toString().isNotEmpty)
        .map((e) => HadithChapter(number: int.tryParse(e.key) ?? 0, title: e.value.toString()))
        .toList()
      ..sort((a, b) => a.number.compareTo(b.number));

    // Build a lookup of hadithnumber -> Arabic text, if Arabic data was
    // provided, so we can merge it in alongside the translation.
    final Map<int, String> arabicByNumber = {};
    if (arabicJson != null) {
      for (final h in (arabicJson['hadiths'] as List)) {
        final num = h['hadithnumber'];
        if (num != null) arabicByNumber[HadithItem._toInt(num)] = h['text'] ?? '';
      }
    }

    final hadiths = (json['hadiths'] as List)
        .map((h) => HadithItem.fromJson(h,
            arabicText:
                arabicByNumber[HadithItem._toInt(h['hadithnumber'])] ?? ''))
        // DROP EMPTY ENTRIES.
        //
        // The dataset carries numbered placeholders with no content in ANY
        // language — 203 of them in Sahih Muslim, 196 in the Introduction
        // alone, blank in English, Urdu and Arabic alike. They were rendering
        // as empty cards.
        //
        // Filtered here, at the point the collection is built, so nothing
        // downstream ever sees them: lists, chapter counts, number ranges and
        // search all become correct for free. Filtering in the UI instead
        // would have left the counts lying.
        //
        // Hadith numbers will therefore skip in those chapters. That is honest
        // — the data does not have them — and far better than blank cards.
        .where((h) =>
            h.text.trim().isNotEmpty || h.arabicText.trim().isNotEmpty)
        .toList();

    return HadithCollection(
      name: metadata['name'] ?? '',
      chapters: chapters,
      hadiths: hadiths,
    );
  }

  List<HadithItem> hadithsInChapter(int chapterNumber) =>
      hadiths.where((h) => h.chapterNumber == chapterNumber).toList();
}

/// Top-level function (required for use with compute()/isolates) that
/// decodes and merges the translation + Arabic JSON strings off the main
/// thread - large books (Bukhari, Tirmidhi, etc.) can otherwise cause a
/// visible freeze/stuck-loading appearance while parsing on the UI thread.
HadithCollection parseHadithCollectionIsolate(List<String> jsonStrings) {
  final translationJson = json.decode(jsonStrings[0]);
  final arabicJson = json.decode(jsonStrings[1]);
  return HadithCollection.fromJson(translationJson, arabicJson: arabicJson);
}
