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
