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
  final int chapterNumber;
  final String text;
  final List<String> grades;

  HadithItem({
    required this.hadithNumber,
    required this.chapterNumber,
    required this.text,
    required this.grades,
  });

  factory HadithItem.fromJson(Map<String, dynamic> json) => HadithItem(
        hadithNumber: json['hadithnumber'] ?? 0,
        chapterNumber: (json['reference']?['book']) ?? 0,
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

  factory HadithCollection.fromJson(Map<String, dynamic> json) {
    final metadata = json['metadata'];
    final sections = Map<String, dynamic>.from(metadata['sections'] ?? {});
    final chapters = sections.entries
        .where((e) => e.value != null && e.value.toString().isNotEmpty)
        .map((e) => HadithChapter(number: int.parse(e.key), title: e.value.toString()))
        .toList()
      ..sort((a, b) => a.number.compareTo(b.number));

    final hadiths = (json['hadiths'] as List).map((h) => HadithItem.fromJson(h)).toList();

    return HadithCollection(
      name: metadata['name'] ?? '',
      chapters: chapters,
      hadiths: hadiths,
    );
  }

  List<HadithItem> hadithsInChapter(int chapterNumber) =>
      hadiths.where((h) => h.chapterNumber == chapterNumber).toList();
}
