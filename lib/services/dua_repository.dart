import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import '../models/dua.dart';

/// Loads Duas (supplications) from a file bundled directly inside the
/// app - works completely offline. Source: "Hisn al-Muslim" (Fortress of
/// the Muslim) by Sa'id bin Ali Al-Qahtani, via hisnmuslim.com - a
/// widely-used, respected collection distributed freely for Islamic
/// educational purposes.
class DuaRepository {
  static List<DuaCategory>? _cached;

  static Future<List<DuaCategory>> loadCategories() async {
    if (_cached != null) return _cached!;
    final jsonString = await rootBundle.loadString('assets/duas/duas_en.json');
    final List<dynamic> jsonList = json.decode(jsonString);
    _cached = jsonList.map((c) => DuaCategory.fromJson(c)).toList();
    return _cached!;
  }
}
