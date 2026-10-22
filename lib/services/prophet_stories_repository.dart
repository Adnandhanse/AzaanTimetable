import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/prophet_story.dart';

List<ProphetStory> _parseStories(String data) =>
  ((jsonDecode(data) as Map<String, dynamic>)['books'] as List)
    .map((j) => ProphetStory.fromJson(Map<String, dynamic>.from(j as Map))).toList();

class ProphetStoriesRepository {
  static Future<List<ProphetStory>>? _cache;
  static Future<List<ProphetStory>> load() => _cache ??= _load();
  static Future<List<ProphetStory>> _load() async {
    try {
      final raw = await rootBundle.loadString('assets/prophet_stories/stories.json');
      return await compute(_parseStories, raw);
    } catch (_) { _cache = null; rethrow; }
  }
}

/// Stable page IDs, so adding chapters later does not silently resume elsewhere.
class ProphetStoryProgress {
  static String _key(String id) => 'prophet_story_progress_v1_$id';
  static Future<Map<String, dynamic>> read(String id) async {
    final prefs = await SharedPreferences.getInstance();
    try {
      final raw = prefs.getString(_key(id));
      return raw == null ? {} : Map<String, dynamic>.from(jsonDecode(raw) as Map);
    } catch (_) { return {}; }
  }
  static Future<void> save(String id, String pageId, {bool completed = false}) async {
    final prefs = await SharedPreferences.getInstance();
    final old = await read(id);
    final ok = await prefs.setString(_key(id), jsonEncode({
      'page': pageId, 'contentVersion': 4,
      'completed': completed || (old['contentVersion'] == 4 && old['completed'] == true),
    }));
    if (!ok) throw StateError('Progress not saved');
  }
}
