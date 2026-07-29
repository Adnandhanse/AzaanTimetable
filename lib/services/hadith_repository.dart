import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import '../models/hadith.dart';

/// Loads Hadith collections from files bundled directly inside the app -
/// works completely offline. Source: the "hadith-api" open dataset
/// (Unlicense / public domain) by fawazahmed0 - covers all six canonical
/// Hadith books (Kutub al-Sittah) in both English and Urdu.
class HadithRepository {
  static final Map<String, HadithCollection> _cache = {};

  static Future<HadithCollection> loadCollection(HadithBook book, HadithLanguage language) async {
    final langPrefix = language == HadithLanguage.english ? 'eng' : 'urd';
    final cacheKey = '$langPrefix-${book.fileKey}';
    if (_cache.containsKey(cacheKey)) return _cache[cacheKey]!;

    final path = 'assets/hadith/${langPrefix}_${book.fileKey}.json';
    final jsonString = await rootBundle.loadString(path);
    final collection = HadithCollection.fromJson(json.decode(jsonString));
    _cache[cacheKey] = collection;
    return collection;
  }
}
