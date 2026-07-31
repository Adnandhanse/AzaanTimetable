import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Stores bookmarks (favourite Surahs) and personal notes locally on the
/// device - works fully offline, no account or internet needed.
class QuranLocalDataService {
  static const _favouritesKey = 'quran_favourite_surahs';
  static const _notesKey = 'quran_verse_notes';

  static Future<Set<int>> getFavourites() async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_favouritesKey) ?? [];
    return list.map(int.parse).toSet();
  }

  static Future<void> toggleFavourite(int surahNumber) async {
    final prefs = await SharedPreferences.getInstance();
    final favourites = await getFavourites();
    if (favourites.contains(surahNumber)) {
      favourites.remove(surahNumber);
    } else {
      favourites.add(surahNumber);
    }
    await prefs.setStringList(_favouritesKey, favourites.map((e) => e.toString()).toList());
  }

  static Future<Map<String, String>> getAllNotes() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_notesKey);
    if (jsonString == null) return {};
    return Map<String, String>.from(json.decode(jsonString));
  }

  static Future<String?> getNote(int surahNumber, int verseNumber) async {
    final notes = await getAllNotes();
    return notes['$surahNumber-$verseNumber'];
  }

  static Future<void> saveNote(int surahNumber, int verseNumber, String note) async {
    final prefs = await SharedPreferences.getInstance();
    final notes = await getAllNotes();
    if (note.trim().isEmpty) {
      notes.remove('$surahNumber-$verseNumber');
    } else {
      notes['$surahNumber-$verseNumber'] = note;
    }
    await prefs.setString(_notesKey, json.encode(notes));
  }

  // --- Reading mode preference --------------------------------------------

  static const _arabicOnlyKey = 'quran_arabic_only';

  /// Defaults to TRUE — the Qur'an opens in Arabic only, and translation is
  /// something the reader turns on. Whichever way they last left it sticks, so
  /// nobody has to re-toggle it every time they open a surah.
  static Future<bool> getArabicOnly() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_arabicOnlyKey) ?? true;
  }

  static Future<void> setArabicOnly(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_arabicOnlyKey, value);
  }

  // --- Where the reader stopped -------------------------------------------

  static const _lastReadKey = 'quran_last_read';

  /// Remembers where reading stopped.
  ///
  /// Two levels of precision, both stored:
  ///   * [scrollOffset] - saved automatically whenever the reader scrolls, so
  ///     reopening a surah lands exactly where they were, mid-screen and all.
  ///   * [verseNumber]  - set only when the reader explicitly marks a verse.
  ///     Offsets are meaningless across a font-size or device change, so the
  ///     verse is what survives; the offset is the nicety on top.
  ///
  /// Only one position is kept. A reading app that remembers thirty places
  /// remembers none of them usefully.
  static Future<void> saveLastRead({
    required int surahNumber,
    required String surahName,
    int? verseNumber,
    double? scrollOffset,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final existing = await getLastRead();

    // Auto-saves must not wipe a verse the reader deliberately marked in this
    // same surah - keep the explicit mark unless a new one replaces it.
    final int? keepVerse = verseNumber ??
        (existing != null && existing['surahNumber'] == surahNumber
            ? existing['verseNumber'] as int?
            : null);

    await prefs.setString(
      _lastReadKey,
      json.encode(<String, dynamic>{
        'surahNumber': surahNumber,
        'surahName': surahName,
        'verseNumber': keepVerse,
        'scrollOffset': scrollOffset ?? 0.0,
        'savedAt': DateTime.now().millisecondsSinceEpoch,
      }),
    );
  }

  static Future<Map<String, dynamic>?> getLastRead() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_lastReadKey);
    if (raw == null) return null;
    try {
      return Map<String, dynamic>.from(json.decode(raw));
    } catch (_) {
      // Corrupt entry should never block reading.
      return null;
    }
  }

  static Future<void> clearLastRead() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_lastReadKey);
  }

  // --- Hadith bookmarks ---
  static const _hadithBookmarksKey = 'hadith_bookmarks';

  /// Each bookmark is stored as "bookKey|language|hadithNumber".
  static Future<Set<String>> getHadithBookmarks() async {
    final prefs = await SharedPreferences.getInstance();
    return (prefs.getStringList(_hadithBookmarksKey) ?? []).toSet();
  }

  static Future<void> toggleHadithBookmark(String bookKey, String language, int hadithNumber) async {
    final prefs = await SharedPreferences.getInstance();
    final bookmarks = await getHadithBookmarks();
    final id = '$bookKey|$language|$hadithNumber';
    if (bookmarks.contains(id)) {
      bookmarks.remove(id);
    } else {
      bookmarks.add(id);
    }
    await prefs.setStringList(_hadithBookmarksKey, bookmarks.toList());
  }

  static Future<bool> isHadithBookmarked(String bookKey, String language, int hadithNumber) async {
    final bookmarks = await getHadithBookmarks();
    return bookmarks.contains('$bookKey|$language|$hadithNumber');
  }
}
