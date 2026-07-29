class DuaItem {
  final String arabicText;
  final String translation;
  final String? audioUrl;

  DuaItem({required this.arabicText, required this.translation, this.audioUrl});

  factory DuaItem.fromJson(Map<String, dynamic> json) => DuaItem(
        arabicText: json['ARABIC_TEXT'] ?? '',
        translation: json['TRANSLATED_TEXT'] ?? '',
        audioUrl: json['AUDIO'],
      );
}

class DuaCategory {
  final int id;
  final String title;
  final String? audioUrl;
  final List<DuaItem> duas;

  DuaCategory({required this.id, required this.title, this.audioUrl, required this.duas});

  factory DuaCategory.fromJson(Map<String, dynamic> json) => DuaCategory(
        id: json['ID'],
        title: json['TITLE'] ?? '',
        audioUrl: json['AUDIO_URL'],
        duas: (json['TEXT'] as List).map((d) => DuaItem.fromJson(d)).toList(),
      );
}
