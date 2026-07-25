class QuranVerse {
  final int number;
  final String arabicText;
  final String translation;

  QuranVerse({required this.number, required this.arabicText, required this.translation});

  factory QuranVerse.fromJson(Map<String, dynamic> json) => QuranVerse(
        number: json['id'],
        arabicText: json['text'],
        translation: json['translation'] ?? '',
      );
}

class Surah {
  final int number;
  final String arabicName;
  final String transliteration;
  final String englishMeaning;
  final String type; // meccan / medinan
  final int totalVerses;
  final List<QuranVerse> verses;

  Surah({
    required this.number,
    required this.arabicName,
    required this.transliteration,
    required this.englishMeaning,
    required this.type,
    required this.totalVerses,
    required this.verses,
  });

  factory Surah.fromJson(Map<String, dynamic> json) => Surah(
        number: json['id'],
        arabicName: json['name'],
        transliteration: json['transliteration'],
        englishMeaning: json['translation'] ?? '',
        type: json['type'] ?? '',
        totalVerses: json['total_verses'] ?? (json['verses'] as List).length,
        verses: (json['verses'] as List).map((v) => QuranVerse.fromJson(v)).toList(),
      );
}
