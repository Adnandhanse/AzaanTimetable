import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/tajweed_data.dart';

class QuranTajweedStyle {
  static bool enabled = false;
  static Future<void> load() async {
    enabled = (await SharedPreferences.getInstance()).getBool('quran_colour_tajweed') ?? false;
  }
  static Future<void> setEnabled(bool value) async {
    await (await SharedPreferences.getInstance()).setBool('quran_colour_tajweed', value);
    enabled = value;
  }

  static Color colour(String rule, bool dark) {
    if (rule == 'qalqalah') return dark ? const Color(0xFF80DEEA) : const Color(0xFF006D9C);
    if (rule == 'iqlab') return dark ? const Color(0xFFEA80FC) : const Color(0xFF8A289B);
    if (rule.startsWith('madd')) return dark ? const Color(0xFFFF8A80) : const Color(0xFFB52832);
    if (rule == 'hamzat_wasl' || rule == 'lam_shamsiyyah' || rule == 'silent') {
      return dark ? const Color(0xFFBDBDBD) : const Color(0xFF616161);
    }
    return dark ? const Color(0xFFB9F6CA) : const Color(0xFF147347);
  }

  /// Only exact edition matches. Never normalises or guesses offsets.
  static Map<int, String> marks(int surah, int ayah, String text) {
    final row = tajweedData['$surah:$ayah'];
    if (row == null || row[0] != text) return const {};
    final codeUnits = <int>[0];
    for (final rune in text.runes) {
      codeUnits.add(codeUnits.last + (rune > 0xFFFF ? 2 : 1));
    }
    final marks = <int, String>{};
    for (final dynamic item in row[1] as List<dynamic>) {
      final a = item as List<dynamic>;
      final start = a[0] as int;
      final end = a[1] as int;
      if (start < 0 || start >= end || end >= codeUnits.length) return const {};
      for (int i = codeUnits[start]; i < codeUnits[end]; i++) {
        marks[i] = a[2] as String;
      }
    }
    return marks;
  }

  static List<TextSpan> spans(String text, TextStyle style,
      Map<int, String> marks, bool dark, {int offset = 0}) {
    final result = <TextSpan>[];
    int start = 0;
    while (start < text.length) {
      final rule = enabled ? marks[offset + start] : null;
      int end = start + 1;
      while (end < text.length && (enabled ? marks[offset + end] : null) == rule) {
        end++;
      }
      result.add(TextSpan(text: text.substring(start, end),
        style: rule == null ? style : style.copyWith(color: colour(rule, dark))));
      start = end;
    }
    return result;
  }
}
