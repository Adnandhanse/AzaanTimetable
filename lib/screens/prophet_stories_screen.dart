import 'package:flutter/material.dart';
import '../models/prophet_story.dart';
import '../services/prophet_stories_repository.dart';
import '../theme/app_theme.dart';
import '../widgets/prophet_story_artwork.dart';
import 'prophet_story_reader_screen.dart';

class ProphetStoriesScreen extends StatefulWidget {
  const ProphetStoriesScreen({super.key});
  @override
  State<ProphetStoriesScreen> createState() => _ProphetStoriesScreenState();
}
class _ProphetStoriesScreenState extends State<ProphetStoriesScreen> {
  List<ProphetStory>? _books;
  final _progress = <String, Map<String, dynamic>>{};
  String _query = '';
  bool _failed = false, _navigating = false;
  @override
  void initState() { super.initState(); _load(); }
  Future<void> _load() async {
    try {
      final books = await ProphetStoriesRepository.load();
      final progress = <String, Map<String, dynamic>>{};
      for (final b in books) { progress[b.id] = await ProphetStoryProgress.read(b.id); }
      if (mounted) setState(() { _books = books; _progress.addAll(progress); _failed = false; });
    } catch (_) { if (mounted) setState(() => _failed = true); }
  }
  Future<void> _open(ProphetStory story) async {
    if (_navigating) return;
    _navigating = true;
    try {
    final saved = _progress[story.id]?['page'];
    final index = story.pages.indexWhere((p) => p.id == saved);
    await Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) =>
      ProphetStoryReaderScreen(story: story, initialPage: index < 0 ? 0 : index)));
    if (mounted) await _load();
    } finally { _navigating = false; }
  }
  @override
  Widget build(BuildContext context) {
    final books = _books?.where((b) => b.name.toLowerCase().contains(_query.toLowerCase()) ||
      b.id.contains(_query.toLowerCase())).toList();
    return Scaffold(appBar: AppBar(title: const Text('Prophet Stories')),
      body: _failed ? Center(child: TextButton(onPressed: () {
        setState(() => _failed = false); _load();
      }, child: const Text('Library nahi khuli · Dobara koshish karein')))
      : books == null ? const Center(child: CircularProgressIndicator())
      : ListView(padding: const EdgeInsets.fromLTRB(20, 12, 20, 32), children: [
        ClipRRect(borderRadius: BorderRadius.circular(24),
          child: ProphetStoryArtwork(
            image: 'assets/prophet_stories/scenes/valley.webp',
            title: 'Nabiyon ki kahaniyan',
            subtitle: '25 Anbiya · Quran aur sahih hadees se sabit waqiat')),
        const SizedBox(height: 16),
        const Text('Bachon aur badon ke liye. Har page par asal reference. '
          'Tasveeron mein sirf manazir aur cheezein hain; kisi jandar ki tasveer nahi.'),
        const SizedBox(height: 14),
        TextField(decoration: const InputDecoration(prefixIcon: Icon(Icons.search),
          hintText: 'Nabi ka naam talaash karein', border: OutlineInputBorder()),
          onChanged: (v) => setState(() => _query = v.trim())),
        const SizedBox(height: 16),
        if (books.isEmpty) const Text('Is naam se book nahi mili.'),
        ...books.map((b) {
          final saved = _progress[b.id] ?? {};
          final done = saved['completed'] == true;
          final index = b.pages.indexWhere((p) => p.id == saved['page']);
          return Card(margin: const EdgeInsets.only(bottom: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20),
              side: BorderSide(color: AppColors.goldRule)),
            clipBehavior: Clip.antiAlias,
            child: InkWell(onTap: () => _open(b), child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              ProphetStoryArtwork(image: b.pages.first.image, title: b.name),
              Padding(padding: const EdgeInsets.fromLTRB(18, 14, 18, 18), child: Row(children: [
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  if (b.id != 'muhammad') Text('Alayhis salam', style: AppText.caption),
                  if (b.teaser.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(b.teaser, style: AppText.body.copyWith(height: 1.6)),
                  ],
                  const SizedBox(height: 8),
                  Text('${b.pages.length} hisse · Roman Urdu / English', style: AppText.caption),
                  const SizedBox(height: 8),
                  Text(done ? 'Mukammal · Dobara parhein' : index >= 0
                    ? 'Jaari rakhein · Hissa ${index + 1}' : 'Kahani shuru karein',
                    style: AppText.body.copyWith(color: AppColors.emerald,
                      fontWeight: FontWeight.w600)),
                ])),
                const SizedBox(width: 10),
                Icon(done ? Icons.check_circle_outline : Icons.arrow_forward_rounded,
                  color: AppColors.gold),
              ])),
            ])));

        }),
        TextButton.icon(onPressed: () => showDialog<void>(context: context,
          builder: (ctx) => AlertDialog(title: const Text('Is library ke bare mein'),
            content: const SingleChildScrollView(child: Text(
              'Yeh Quran aur Sahih Bukhari/Muslim se muntakhab waqiat ka aasaan bayan hai, '
              'lafzi tarjuma ya har Nabi ki mukammal tareekhi biography nahi. '
              'Paidaish/bachpan ki tafseel sirf jahan source deta hai. '
              'Books ka order yaqini tareekhi chronology ka dawa nahi. '
              'Illustrations samjhane ke liye artistic manazir hain, asal jagahon ki exact tasveer nahi. '
              'Baaz milte-julte waqiat mein relevant environmental artwork dobara istemal hota hai.')),
            actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Theek hai'))])),
          icon: const Icon(Icons.info_outline), label: const Text('Sources aur illustrations')),
      ]));
  }
}
