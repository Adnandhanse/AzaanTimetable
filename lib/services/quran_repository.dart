import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import '../models/quran.dart';

enum QuranLanguage {
  english,
  urdu,
  hindi;

  /// Matches QuranLocalDataService's stored string, independent of the
  /// enum's declared order.
  String get code => switch (this) {
        QuranLanguage.english => 'english',
        QuranLanguage.urdu => 'urdu',
        QuranLanguage.hindi => 'hindi',
      };

  static QuranLanguage fromCode(String code) => switch (code) {
        'urdu' => QuranLanguage.urdu,
        'hindi' => QuranLanguage.hindi,
        _ => QuranLanguage.english,
      };
}

/// Loads the Quran (Arabic text + translation) from a file bundled
/// directly inside the app - works completely offline, no internet or
/// API needed at any point after install.
///
/// Sources:
/// - Arabic text & English/Urdu translations: "quran-json" project
///   (CC BY-SA 4.0) - https://github.com/risan/quran-json
/// - Hindi translation: "quran-api" project (Unlicense/Public Domain) -
///   https://github.com/fawazahmed0/quran-api - translation by Suhel
///   Farooq Khan & Saifur Rahman Nadwi, sourced from tanzil.net.
class QuranRepository {
  static List<Surah>? _cachedEnglish;
  static List<Surah>? _cachedUrdu;
  static List<Surah>? _cachedHindi;

  static Future<List<Surah>> loadSurahs(QuranLanguage language) async {
    if (language == QuranLanguage.english && _cachedEnglish != null) return _cachedEnglish!;
    if (language == QuranLanguage.urdu && _cachedUrdu != null) return _cachedUrdu!;
    if (language == QuranLanguage.hindi && _cachedHindi != null) return _cachedHindi!;

    if (language == QuranLanguage.hindi) {
      final surahs = await _loadHindi();
      _cachedHindi = surahs;
      return surahs;
    }

    final path = language == QuranLanguage.english
        ? 'assets/quran/quran_en.json'
        : 'assets/quran/quran_ur.json';

    final jsonString = await rootBundle.loadString(path);
    final List<dynamic> jsonList = json.decode(jsonString);
    final surahs = jsonList.map((s) => Surah.fromJson(s)).toList();

    if (language == QuranLanguage.english) {
      _cachedEnglish = surahs;
    } else {
      _cachedUrdu = surahs;
    }
    return surahs;
  }

  /// Hindi translation comes as a flat chapter/verse lookup rather than
  /// the nested per-surah format - so we reuse the English data's Surah
  /// metadata (names, Arabic text) and just swap in Hindi translations.
  static Future<List<Surah>> _loadHindi() async {
    final baseSurahs = await loadSurahs(QuranLanguage.english);

    final lookupString = await rootBundle.loadString('assets/quran/quran_hi_lookup.json');
    final Map<String, dynamic> lookup = json.decode(lookupString);

    return baseSurahs.map((surah) {
      final hindiVerses = surah.verses.map((v) {
        final hindiText = lookup['${surah.number}-${v.number}'] ?? v.translation;
        return QuranVerse(number: v.number, arabicText: v.arabicText, translation: hindiText);
      }).toList();

      return Surah(
        number: surah.number,
        arabicName: surah.arabicName,
        transliteration: surah.transliteration,
        englishMeaning: surah.englishMeaning,
        type: surah.type,
        totalVerses: surah.totalVerses,
        verses: hindiVerses,
      );
    }).toList();
  }
}
