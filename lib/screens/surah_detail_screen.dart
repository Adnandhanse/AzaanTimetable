import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/mushaf_view.dart';
import 'package:audioplayers/audioplayers.dart';
import '../models/quran.dart';
import '../services/quran_local_data_service.dart';

class SurahDetailScreen extends StatefulWidget {
  final Surah surah;
  const SurahDetailScreen({super.key, required this.surah});

  @override
  State<SurahDetailScreen> createState() => _SurahDetailScreenState();
}

class _SurahDetailScreenState extends State<SurahDetailScreen> {
  final AudioPlayer _player = AudioPlayer();
  int? _playingVerse;
  final Map<int, String> _notes = {};

  @override
  void initState() {
    super.initState();
    _loadNotes();
  }

  Future<void> _loadNotes() async {
    final allNotes = await QuranLocalDataService.getAllNotes();
    if (!mounted) return;
    setState(() {
      for (final verse in widget.surah.verses) {
        final note = allNotes['${widget.surah.number}-${verse.number}'];
        if (note != null) _notes[verse.number] = note;
      }
    });
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  /// Streams recitation audio (Mishary Alafasy) when online - this is
  /// the one part of the Quran section that needs internet, since
  /// bundling audio for the entire Quran offline would make the app
  /// enormous. Reading (Arabic + translation) always works offline.
  Future<void> _togglePlay(int verseNumber) async {
    if (_playingVerse == verseNumber) {
      await _player.stop();
      setState(() => _playingVerse = null);
      return;
    }
    final surahStr = widget.surah.number.toString().padLeft(3, '0');
    final verseStr = verseNumber.toString().padLeft(3, '0');
    final url = 'https://everyayah.com/data/Alafasy_128kbps/$surahStr$verseStr.mp3';
    try {
      await _player.stop();
      await _player.play(UrlSource(url));
      setState(() => _playingVerse = verseNumber);
      _player.onPlayerComplete.listen((_) {
        if (mounted) setState(() => _playingVerse = null);
      });
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not play audio - check your internet connection.')),
        );
      }
    }
  }

  Future<void> _openNoteEditor(int verseNumber) async {
    final controller = TextEditingController(text: _notes[verseNumber] ?? '');
    final result = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Note for ${widget.surah.number}:$verseNumber'),
        content: TextField(
          controller: controller,
          maxLines: 4,
          decoration: const InputDecoration(hintText: 'Write your note here...'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.of(context).pop(controller.text), child: const Text('Save')),
        ],
      ),
    );
    if (result != null) {
      await QuranLocalDataService.saveNote(widget.surah.number, verseNumber, result);
      setState(() {
        if (result.trim().isEmpty) {
          _notes.remove(verseNumber);
        } else {
          _notes[verseNumber] = result;
        }
      });
    }
  }

  /// false = verse-by-verse with translation, true = Arabic-only continuous.
  bool _mushafMode = false;

  @override
  Widget build(BuildContext context) {
    final surah = widget.surah;
    return Scaffold(
      appBar: AppBar(
        title: Text('${surah.number}. ${surah.transliteration}'),
        actions: [
          // Two ways to read the same surah. One control, so it is always
          // obvious which mode you are in.
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: TextButton.icon(
              onPressed: () => setState(() => _mushafMode = !_mushafMode),
              icon: Icon(
                _mushafMode ? Icons.list_alt_outlined : Icons.menu_book_outlined,
                size: 18,
                color: AppColors.emerald,
              ),
              label: Text(
                _mushafMode ? 'Translation' : 'Arabic only',
                style: AppText.caption.copyWith(color: AppColors.emerald),
              ),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
          ),
        ],
      ),
      body: _mushafMode
          ? MushafView(surah: surah)
          : ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            color: AppColors.white,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Text(surah.arabicName, style: AppText.arabicTitle.copyWith(color: AppColors.emerald)),
                  const SizedBox(height: 4),
                  Text(
                    '${surah.englishMeaning} • ${surah.type.isNotEmpty ? '${surah.type[0].toUpperCase()}${surah.type.substring(1)}' : ''} • ${surah.totalVerses} verses',
                    style: const TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          ...surah.verses.map((verse) {
            final hasNote = _notes.containsKey(verse.number);
            final isPlaying = _playingVerse == verse.number;
            return Card(
              margin: const EdgeInsets.only(bottom: 10),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          '${surah.number}.${verse.number}',
                          style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.emerald),
                        ),
                        const Spacer(),
                        IconButton(
                          icon: Icon(isPlaying ? Icons.stop_circle : Icons.play_circle_outline, color: AppColors.emerald),
                          onPressed: () => _togglePlay(verse.number),
                        ),
                        IconButton(
                          icon: Icon(
                            hasNote ? Icons.note : Icons.note_add_outlined,
                            color: hasNote ? AppColors.gold : Colors.grey,
                          ),
                          onPressed: () => _openNoteEditor(verse.number),
                        ),
                      ],
                    ),
                    Text(
                      verse.arabicText,
                      textAlign: TextAlign.right,
                      textDirection: TextDirection.rtl,
                      style: AppText.arabicVerse.copyWith(color: AppColors.text),
                    ),
                    const SizedBox(height: 8),
                    const Divider(),
                    const SizedBox(height: 4),
                    Text(verse.translation, style: AppText.translation.copyWith(color: AppColors.text)),
                    if (hasNote) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(color: const Color(0xFFFFF7ED), borderRadius: BorderRadius.circular(6)),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.sticky_note_2, size: 16, color: Colors.orange),
                            const SizedBox(width: 6),
                            Expanded(child: Text(_notes[verse.number]!, style: const TextStyle(fontSize: 13))),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}
