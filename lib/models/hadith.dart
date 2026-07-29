import 'dart:convert';

enum HadithBook { bukhari, muslim, abudawud, tirmidhi, nasai, ibnmajah }

extension HadithBookInfo on HadithBook {
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
        hadithNumber: json['hadithnumber'] ?? 0,
        arabicNumber: json['arabicnumber'],
        chapterNumber: (json['reference']?['book']) ?? 0,
        arabicText: arabicText,
        text: json['text'] ?? '',
        grades: (json['grades'] as List? ?? [])
            .map((g) => '${g['grade'] ?? ''} - ${g['name'] ?? ''}'.trim())
            .where((g) => g.isNotEmpty && g != '-')
            .toList(),
      );
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
        if (num != null) arabicByNumber[num] = h['text'] ?? '';
      }
    }

    final hadiths = (json['hadiths'] as List)
        .map((h) => HadithItem.fromJson(h, arabicText: arabicByNumber[h['hadithnumber']] ?? ''))
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
