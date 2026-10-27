class ProphetStorySource {
  const ProphetStorySource(
      {required this.kind,
      this.surah,
      this.start,
      this.end,
      this.book,
      this.number,
      this.editionLabel});
  final String kind;
  final int? surah, start, end, number;
  final String? book, editionLabel;
  String get label => kind == 'quran'
      ? 'Quran $surah:$start${end != start ? '–$end' : ''}'
      : '${book == 'muslim' ? 'Sahih Muslim' : 'Sahih al-Bukhari'} ${editionLabel ?? number}';
  factory ProphetStorySource.fromJson(Map<String, dynamic> j) =>
      ProphetStorySource(
          kind: j['kind'] as String,
          surah: j['surah'] as int?,
          start: j['start'] as int?,
          end: j['end'] as int?,
          book: j['book'] as String?,
          number: j['number'] as int?,
          editionLabel: j['editionLabel'] as String?);
}

class ProphetStoryPage {
  const ProphetStoryPage(
      {required this.id,
      required this.title,
      required this.scene,
      required this.roman,
      required this.english,
      required this.sources,
      this.titleEnglish = '',
      this.noteRoman,
      this.noteEnglish});
  final String id, title, scene, roman, english, titleEnglish;
  final String? noteRoman, noteEnglish;
  final List<ProphetStorySource> sources;
  String get image => 'assets/prophet_stories/scenes/$scene.webp';
  factory ProphetStoryPage.fromJson(Map<String, dynamic> j) => ProphetStoryPage(
      id: j['id'] as String,
      title: j['title'] as String,
      titleEnglish: j['titleEnglish'] as String? ?? '',
      scene: j['scene'] as String,
      roman: j['roman'] as String,
      english: j['english'] as String,
      noteRoman: j['noteRoman'] as String?,
      noteEnglish: j['noteEnglish'] as String?,
      sources: (j['sources'] as List)
          .map((v) =>
              ProphetStorySource.fromJson(Map<String, dynamic>.from(v as Map)))
          .toList());
}

class ProphetStory {
  const ProphetStory(
      {required this.id,
      required this.name,
      required this.birthNote,
      required this.birthNoteEnglish,
      required this.pages,
      this.teaser = '',
      this.openingRoman = '',
      this.openingEnglish = ''});
  final String id,
      name,
      birthNote,
      birthNoteEnglish,
      teaser,
      openingRoman,
      openingEnglish;
  final List<ProphetStoryPage> pages;
  factory ProphetStory.fromJson(Map<String, dynamic> j) => ProphetStory(
      id: j['id'] as String,
      name: j['name'] as String,
      teaser: j['teaser'] as String? ?? '',
      openingRoman: j['openingRoman'] as String? ?? '',
      openingEnglish: j['openingEnglish'] as String? ?? '',
      birthNote: j['birthNote'] as String,
      birthNoteEnglish: j['birthNoteEnglish'] as String,
      pages: (j['pages'] as List)
          .map((v) =>
              ProphetStoryPage.fromJson(Map<String, dynamic>.from(v as Map)))
          .toList());
}
