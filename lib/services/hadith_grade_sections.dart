import '../models/hadith.dart';

/// Only these two navigation tabs are exposed. Hasan/ungraded/unclear entries
/// remain in All with their original labels rather than being called weak.
enum HadithGradeSection { sahih, daif }

class HadithGradeSections {
  static bool isSahihCollection(String bookKey) =>
      bookKey == 'bukhari' || bookKey == 'muslim';

  static String sourceLabel(String entry) {
    final separator = entry.lastIndexOf(' - ');
    return (separator < 0 ? entry : entry.substring(0, separator)).trim();
  }

  static HadithGradeSection? _labelGroup(String source) {
    final label = source.toLowerCase().replaceAll(RegExp(r"[‘’']"), '')
        .replaceAll(RegExp(r'\s+'), ' ').trim();
    // Chain-only assessments are not automatically judgments on the full text.
    if (RegExp(r'\b(isnaad|isnad|sanad|matn|mauquf|muquf|maqtu|mursal)\b').hasMatch(label)) return null;
    if (RegExp(r'\b(daif|daeef|zaeef|weak)\b').hasMatch(label)) return HadithGradeSection.daif;
    if (label == 'sahih' || label.startsWith('sahih ') || label == 'hasan sahih') {
      return HadithGradeSection.sahih;
    }
    return null;
  }

  /// Al-Albani is the named reference where present in the other four books.
  /// Original gradings from every supplied scholar remain on the card.
  static HadithGradeSection? classify(HadithItem item, {required String bookKey}) {
    if (isSahihCollection(bookKey)) return HadithGradeSection.sahih;
    final entries = item.grades.where((g) {
      final label = sourceLabel(g);
      return label.isNotEmpty && label != '-';
    }).toList();
    for (final entry in entries) {
      final separator = entry.lastIndexOf(' - ');
      final scholar = separator < 0 ? '' : entry.substring(separator + 3)
          .toLowerCase().replaceAll(RegExp(r'[^a-z]'), '');
      if (scholar.contains('albani')) return _labelGroup(sourceLabel(entry));
    }
    if (entries.isEmpty) return null;
    final groups = entries.map((e) => _labelGroup(sourceLabel(e))).toSet();
    return groups.length == 1 ? groups.single : null;
  }
}
