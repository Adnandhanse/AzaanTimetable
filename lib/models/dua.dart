class DuaItem {
  final String arabicText;
  final String translation;
  final String? translationHinglish;
  final String? audioUrl;

  DuaItem({
    required this.arabicText,
    required this.translation,
    this.translationHinglish,
    this.audioUrl,
  });

  /// Hinglish by default; falls back to English wherever a dua does not have
  /// a Hinglish translation yet, so partial coverage degrades sensibly
  /// instead of leaving a blank.
  String get displayTranslation => translationHinglish ?? translation;

  factory DuaItem.fromJson(Map<String, dynamic> json) => DuaItem(
        arabicText: json['ARABIC_TEXT'] ?? '',
        translation: json['TRANSLATED_TEXT'] ?? '',
        translationHinglish: json['TRANSLATED_TEXT_HINGLISH'],
        audioUrl: json['AUDIO'],
      );
}

class DuaCategory {
  final int id;
  final String title;
  final String? titleHinglish;
  final String? audioUrl;
  final List<DuaItem> duas;

  DuaCategory({
    required this.id,
    required this.title,
    this.titleHinglish,
    this.audioUrl,
    required this.duas,
  });

  /// Hinglish by default; falls back to the English chapter title for the
  /// ~114 chapters that don't have one yet.
  String get displayTitle => titleHinglish ?? title;

  factory DuaCategory.fromJson(Map<String, dynamic> json) => DuaCategory(
        id: json['ID'],
        title: json['TITLE'] ?? '',
        titleHinglish: json['TITLE_HINGLISH'],
        audioUrl: json['AUDIO_URL'],
        duas: (json['TEXT'] as List).map((d) => DuaItem.fromJson(d)).toList(),
      );
}
