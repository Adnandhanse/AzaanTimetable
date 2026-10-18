import '../models/hadith.dart';

/// Navigation groups, not a new scholarly assessment. Only explicit labels
/// from the bundled source are grouped. Compound/chain-only grades stay intact.
enum HadithGradeSection { sahih, hasan, daif, multiple, other, ungraded }

extension HadithGradeSectionLabel on HadithGradeSection {
  String title(bool urdu) {
    switch (this) {
      case HadithGradeSection.sahih: return urdu ? 'صحیح احادیث' : 'Sahih hadith';
      case HadithGradeSection.hasan: return urdu ? 'حسن احادیث' : 'Hasan hadith';
      case HadithGradeSection.daif: return urdu ? 'ضعیف احادیث' : 'Da‘if hadith';
      case HadithGradeSection.multiple: return urdu ? 'مختلف درجات' : 'Multiple grades';
      case HadithGradeSection.other: return urdu ? 'دیگر درجات' : 'Other grades';
      case HadithGradeSection.ungraded: return urdu ? 'درجہ دستیاب نہیں' : 'Grade not available';
    }
  }
}

class HadithGradeSections {
  /// Model strings are "grade - scholar". Take the LAST separator because
  /// a grade may itself contain " - ", e.g. "Sahih - Agreed Upon".
  static String sourceLabel(String entry) {
    final separator = entry.lastIndexOf(' - ');
    return (separator < 0 ? entry : entry.substring(0, separator)).trim();
  }

  static HadithGradeSection classify(HadithItem item) {
    final labels = item.grades.map(sourceLabel)
        .map((label) => label.toLowerCase().replaceAll(RegExp(r'\s+'), ' ').trim())
        .where((label) => label.isNotEmpty && label != '-').toSet();
    if (labels.isEmpty) return HadithGradeSection.ungraded;
    final groups = labels.map((label) {
      // Deliberately no substring matching: "Hasan Sahih", "Isnaad Sahih",
      // "Mawdu", "Shadh", etc. are NOT silently relabelled.
      if (label == 'sahih') return HadithGradeSection.sahih;
      if (label == 'hasan') return HadithGradeSection.hasan;
      if (label == 'daif' || label == "da'if" || label == 'da‘if') {
        return HadithGradeSection.daif;
      }
      return HadithGradeSection.other;
    }).toSet();
    if (groups.length > 1 || (groups.single == HadithGradeSection.other && labels.length > 1)) {
      return HadithGradeSection.multiple;
    }
    return groups.single;
  }

  static Map<HadithGradeSection, List<HadithItem>> group(HadithCollection collection) {
    final result = {for (final section in HadithGradeSection.values) section: <HadithItem>[]};
    for (final item in collection.hadiths) {
      result[classify(item)]!.add(item);
    }
    return result;
  }
}
