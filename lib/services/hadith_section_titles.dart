import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;

import '../models/hadith.dart';

/// Urdu chapter (section) titles for the six Hadith books.
///
/// WHY THIS EXISTS
///
/// The bundled `hadith-api` dataset translates hadith *text* into Urdu but not
/// the section names. Every language file — including the Arabic ones — carries
/// English section titles. `urd_bukhari.json` literally contains "Revelation",
/// "Belief", "Knowledge". So there is nothing in the data to switch to, and no
/// amount of UI work makes those headings Urdu.
///
/// This class reads an override file you control:
/// `assets/hadith/urd_sections.json`. Anything present there is used when the
/// reader has picked Urdu; anything missing falls back to the English title
/// from the dataset. Half-filled is fine — you'll just get a mix.
///
/// The shipped override file is intentionally EMPTY. Chapter titles in a
/// religious app need to be right, and inventing 335 Urdu translations without
/// a source or a reviewer would be a bad way to fill a file. See
/// `assets/hadith/urd_sections.SAMPLE.json` for the format and some worked
/// examples.
class HadithSectionTitles {
  HadithSectionTitles._();

  static Map<String, Map<String, String>>? _overrides;

  /// Safe to call repeatedly — the file is parsed once and cached.
  static Future<void> load() async {
    if (_overrides != null) return;
    try {
      final String raw =
          await rootBundle.loadString('assets/hadith/urd_sections.json');
      final Map<String, dynamic> decoded =
          json.decode(raw) as Map<String, dynamic>;

      final Map<String, Map<String, String>> parsed =
          <String, Map<String, String>>{};
      for (final MapEntry<String, dynamic> entry in decoded.entries) {
        // Keys starting with _ are notes for humans, not data.
        if (entry.key.startsWith('_')) continue;
        final dynamic value = entry.value;
        if (value is Map) {
          parsed[entry.key] = value.map(
            (dynamic k, dynamic v) =>
                MapEntry<String, String>(k.toString(), v.toString()),
          );
        }
      }
      _overrides = parsed;
    } catch (e) {
      // A missing or malformed override file must never break the reader.
      // English titles are a perfectly usable fallback.
      debugPrint('Urdu section titles unavailable, using English: $e');
      _overrides = <String, Map<String, String>>{};
    }
  }

  /// The title to display. Falls back to [englishTitle] whenever there's no
  /// Urdu entry, or the reader isn't in Urdu.
  static String resolve({
    required HadithBook book,
    required int sectionNumber,
    required HadithLanguage language,
    required String englishTitle,
  }) {
    if (language != HadithLanguage.urdu) return englishTitle;
    final Map<String, String>? forBook = _overrides?[book.fileKey];
    final String? urdu = forBook?['$sectionNumber'];
    if (urdu == null || urdu.trim().isEmpty) return englishTitle;
    return urdu;
  }

  /// Whether this book's Urdu titles are a first pass that no scholar has
  /// checked. Drives the "not verified" note, which must stay visible until
  /// someone qualified signs the titles off.
  static bool isUnverified(HadithBook book) => overrideCount(book) > 0;

  /// How many titles are currently overridden for a book. Used to show an
  /// honest note in the UI rather than pretending the list is translated.
  static int overrideCount(HadithBook book) =>
      _overrides?[book.fileKey]?.entries
          .where((MapEntry<String, String> e) => e.value.trim().isNotEmpty)
          .length ??
      0;
}
