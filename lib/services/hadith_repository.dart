import 'package:flutter/foundation.dart' show compute;
import 'package:flutter/services.dart' show rootBundle;
import '../models/hadith.dart';

/// Loads Hadith collections from files bundled directly inside the app -
/// works completely offline. Source: the "hadith-api" open dataset
/// (Unlicense / public domain) by fawazahmed0 - covers all six canonical
/// Hadith books (Kutub al-Sittah) in Arabic, English, and Urdu.
class HadithRepository {
  static final Map<String, HadithCollection> _cache = {};

  static Future<HadithCollection> loadCollection(HadithBook book, HadithLanguage language) async {
    final langPrefix = language == HadithLanguage.english ? 'eng' : 'urd';
    final cacheKey = '$langPrefix-${book.fileKey}';
    if (_cache.containsKey(cacheKey)) return _cache[cacheKey]!;

    final translationPath = 'assets/hadith/${langPrefix}_${book.fileKey}.json';
    final arabicPath = 'assets/hadith/ara_${book.fileKey}.json';

    final translationString = await rootBundle.loadString(translationPath);
    final arabicString = await rootBundle.loadString(arabicPath);

    // Parsing (especially for large books like Bukhari) happens in a
    // separate isolate via compute() so the UI doesn't appear to freeze
    // or get stuck while the JSON is being decoded and merged.
    final collection = await compute(parseHadithCollectionIsolate, [translationString, arabicString]);

    _cache[cacheKey] = collection;
    return collection;
  }
}
