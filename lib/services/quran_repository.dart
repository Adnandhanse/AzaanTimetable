import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import '../models/quran.dart';

enum QuranLanguage { english, urdu }

/// Loads the Quran (Arabic text + translation) from a file bundled
/// directly inside the app - works completely offline, no internet or
/// API needed at any point after install.
///
/// Source: Arabic text and translations from the open-source "quran-json"
/// project (CC BY-SA 4.0) - https://github.com/risan/quran-json
class QuranRepository {
  static List<Surah>? _cachedEnglish;
  static List<Surah>? _cachedUrdu;

  static Future<List<Surah>> loadSurahs(QuranLanguage language) async {
    if (language == QuranLanguage.english && _cachedEnglish != null) return _cachedEnglish!;
    if (language == QuranLanguage.urdu && _cachedUrdu != null) return _cachedUrdu!;

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
}
