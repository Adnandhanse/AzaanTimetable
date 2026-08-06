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

  /// The duas people actually reach for, in the order they occur in a day.
  ///
  /// The source file is Hisn al-Muslim's own ordering, which is thorough and
  /// completely unhelpful for finding "the dua before eating" — chapter 27 is
  /// morning remembrance, chapter 1 is waking up, and the everyday ones are
  /// scattered through 132 entries.
  ///
  /// These are matched by a distinctive fragment of the English title rather
  /// than by chapter ID, because IDs would break silently if the dataset is ever
  /// replaced with another edition. A fragment that stops matching just drops
  /// that dua back into the main list, which is a visible, harmless failure.
  static const List<String> _commonOrder = <String>[
    'when you wake up',
    'entering the restroom',
    'leaving the restroom',
    'getting dressed',
    'when leaving the home',
    'when entering the home',
    'entering the mosque',
    'leaving the mosque',
    'before eating',
    'after eating',
    'traveling',
    'riding in a vehicle',
    'sneezing',
    'visiting the sick',
    'worry and grief',
    "istikharah",
    'morning and evening',
    'before sleeping',
  ];

  static Future<List<DuaCategory>> loadCategories() async {
    if (_cached != null) return _cached!;
    final jsonString = await rootBundle.loadString('assets/duas/duas_en.json');
    final List<dynamic> jsonList = json.decode(jsonString);
    final all = jsonList.map((c) => DuaCategory.fromJson(c)).toList();

    // Everyday duas first, in daily order; everything else keeps the source
    // order after them. Nothing is hidden or removed — all 132 stay reachable.
    final List<DuaCategory> common = <DuaCategory>[];
    final Set<int> taken = <int>{};
    for (final String fragment in _commonOrder) {
      for (final DuaCategory c in all) {
        if (taken.contains(c.id)) continue;
        if (c.title.toLowerCase().contains(fragment)) {
          common.add(c);
          taken.add(c.id);
          break;
        }
      }
    }
    final rest = all.where((c) => !taken.contains(c.id)).toList();

    _commonCount = common.length;
    _cached = <DuaCategory>[...common, ...rest];
    return _cached!;
  }

  /// How many of the leading entries are the everyday set, so the screen can
  /// put a heading above them.
  static int get commonCount => _commonCount;
  static int _commonCount = 0;
}
