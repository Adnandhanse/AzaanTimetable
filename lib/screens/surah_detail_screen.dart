import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/app_strings.dart';
import '../data/sajdah_verses.dart';
import '../data/juz_boundaries.dart';
import '../widgets/mushaf_view.dart';
import 'package:audioplayers/audioplayers.dart';
import '../models/quran.dart';
import '../services/quran_local_data_service.dart';

class SurahDetailScreen extends StatefulWidget {
  final Surah surah;

  /// Where to land when resuming. Both optional — opening a surah normally
  /// passes neither.
  final double? initialOffset;
  final int? initialVerse;

  const SurahDetailScreen({
    super.key,
    required this.surah,
    this.initialOffset,
    this.initialVerse,
  });

  @override
  State<SurahDetailScreen> createState() => _SurahDetailScreenState();
}

class _SurahDetailScreenState extends State<SurahDetailScreen> {
  final AudioPlayer _player = AudioPlayer();
  final ScrollController _scroll = ScrollController();
  int? _playingVerse;
  final Map<int, String> _notes = {};

  /// The verse the reader explicitly marked in this surah, if any.
  int? _markedVerse;

  /// Which verse is on screen, so the juz in the title tracks the reading
  /// position instead of being stuck on the surah's first juz.
  int _visibleVerse = 1;

  /// Throttles the auto-save. Writing to shared_preferences on every scroll
  /// frame would hammer the disk for no benefit.
  DateTime _lastSave = DateTime.fromMillisecondsSinceEpoch(0);

  @override
  void initState() {
    super.initState();
    _markedVerse = widget.initialVerse;
    _loadReadingMode();
    _loadNotes();
    _scroll.addListener(_onScroll);

    final double? jumpTo = widget.initialOffset;
    if (jumpTo != null && jumpTo > 0) {
      // After first layout, or the scroll view has no extent to jump into yet.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || !_scroll.hasClients) return;
        _scroll.jumpTo(jumpTo.clamp(0.0, _scroll.position.maxScrollExtent));
      });
    }
  }

  Future<void> _loadReadingMode() async {
    final bool arabicOnly = await QuranLocalDataService.getArabicOnly();
    if (!mounted) return;
    setState(() => _mushafMode = arabicOnly);
  }

  Future<void> _setReadingMode(bool arabicOnly) async {
    setState(() => _mushafMode = arabicOnly);
    await QuranLocalDataService.setArabicOnly(arabicOnly);
  }

  /// Rough estimate of which verse is in view, so the juz in the title tracks
  /// the reading position. Only used for a label, so an item or two out does not
  /// matter — and it costs nothing compared with measuring every row.
  void _updateVisibleVerse() {
    if (!_scroll.hasClients) return;
    final verses = widget.surah.verses;
    if (verses.isEmpty) return;
    final max = _scroll.position.maxScrollExtent;
    if (max <= 0) return;
    final frac = (_scroll.offset / max).clamp(0.0, 1.0);
    final idx = (frac * (verses.length - 1)).round();
    final v = verses[idx].number;
    if (v != _visibleVerse) setState(() => _visibleVerse = v);
  }

  void _onScroll() {
    _updateVisibleVerse();
    final DateTime now = DateTime.now();
    if (now.difference(_lastSave) < const Duration(seconds: 2)) return;
    _lastSave = now;
    _saveposition();
  }

  Future<void> _saveposition({int? verseNumber}) async {
    await QuranLocalDataService.saveLastRead(
      surahNumber: widget.surah.number,
      surahName: widget.surah.transliteration,
      verseNumber: verseNumber,
      scrollOffset: _scroll.hasClients ? _scroll.offset : 0,
    );
  }

  Future<void> _markVerse(int verseNumber) async {
    final bool unmark = _markedVerse == verseNumber;
    setState(() => _markedVerse = unmark ? null : verseNumber);
    if (unmark) {
      await QuranLocalDataService.clearLastRead();
    } else {
      await _saveposition(verseNumber: verseNumber);
    }
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(unmark
            ? 'Reading position cleared'
            : 'Saved — Continue reading will return to ${widget.surah.transliteration} $verseNumber'),
        duration: const Duration(seconds: 2),
      ),
    );
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
    // Last write wins, so leaving the screen records exactly where they were.
    _saveposition();
    _scroll.removeListener(_onScroll);
    _scroll.dispose();
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

  /// true = Arabic only (the default), false = verse-by-verse with translation.
  /// Loaded from preferences, so the reader's last choice sticks.
  bool _mushafMode = true;

  @override
  Widget build(BuildContext context) {
    final surah = widget.surah;
    return Scaffold(
      appBar: AppBar(
        // Surah on top, juz beneath.
        //
        // A surah can span several juz — Al-Baqarah covers three — so a single
        // fixed number would be wrong for most of it. This shows the juz of the
        // verse currently in view and updates as you read.
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('${surah.number}. ${surah.transliteration}'),
            Text(
              '${S.isUrdu ? 'پارہ' : 'Juz'} ${juzForVerse(surah.number, _visibleVerse)}',
              style: AppText.caption.copyWith(
                  fontSize: 11.5, color: AppColors.emerald),
            ),
          ],
        ),
        actions: [
          // Two ways to read the same surah. One control, so it is always
          // obvious which mode you are in.
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: TextButton.icon(
              onPressed: () => _setReadingMode(!_mushafMode),
              icon: Icon(
                _mushafMode ? Icons.list_alt_outlined : Icons.menu_book_outlined,
                size: 18,
                color: AppColors.emerald,
              ),
              label: Text(
                // Names what you get, not what you are in.
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
          ? MushafView(
              verses: surah.verses,
              // Worked out here because this screen knows the surah number;
              // MushafView only sees a flat list of verses.
              sajdahIndices: <int>{
                for (int i = 0; i < surah.verses.length; i++)
                  if (SajdahVerses.isSajdah(surah.number, surah.verses[i].number))
                    i,
              },
              markedIndex: _markedVerse == null
                  ? null
                  : surah.verses
                      .indexWhere((QuranVerse v) => v.number == _markedVerse),
              initialVerseIndex: widget.initialVerse == null
                  ? null
                  : surah.verses.indexWhere(
                      (QuranVerse v) => v.number == widget.initialVerse),
              onMarkIndex: (int index) =>
                  _markVerse(surah.verses[index].number),
            )
          : ListView(
        controller: _scroll,
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
                        // Sajdah marker. Red dot and label, beside the verse
                        // number, so it is visible while scrolling rather than
                        // only once you have read to the end of the ayah.
                        if (SajdahVerses.isSajdah(surah.number, verse.number))
                          Padding(
                            padding: const EdgeInsets.only(left: 10),
                            child: Tooltip(
                              message:
                                  SajdahVerses.noteFor(surah.number, verse.number) ??
                                      'Sajdah at-tilawah',
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 8,
                                    height: 8,
                                    decoration: const BoxDecoration(
                                      color: Color(0xFFB3261E),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 5),
                                  Text(
                                    S.isUrdu ? 'سجدہ' : 'Sajdah',
                                    style: AppText.caption.copyWith(
                                      color: const Color(0xFFB3261E),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  // An asterisk where the schools differ, so a
                                  // reader of either one is not told their
                                  // position is the only position.
                                  if (SajdahVerses.noteFor(
                                          surah.number, verse.number) !=
                                      null)
                                    Text(
                                      ' *',
                                      style: AppText.caption.copyWith(
                                          color: const Color(0xFFB3261E)),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        const Spacer(),
                        IconButton(
                          icon: Icon(isPlaying ? Icons.stop_circle : Icons.play_circle_outline, color: AppColors.emerald),
                          onPressed: () => _togglePlay(verse.number),
                        ),
                        IconButton(
                          icon: Icon(
                            hasNote ? Icons.note : Icons.note_add_outlined,
                            color: hasNote ? AppColors.gold : AppColors.chevron,
                          ),
                          tooltip: 'Note',
                          onPressed: () => _openNoteEditor(verse.number),
                        ),
                        // Explicitly mark where reading stopped. Scroll
                        // position is saved automatically too, but an offset
                        // stops meaning anything if the font size or the device
                        // changes — a verse number always survives.
                        IconButton(
                          icon: Icon(
                            _markedVerse == verse.number
                                ? Icons.bookmark
                                : Icons.bookmark_border,
                            color: _markedVerse == verse.number
                                ? AppColors.emerald
                                : AppColors.chevron,
                          ),
                          tooltip: 'Continue from here',
                          onPressed: () => _markVerse(verse.number),
                        ),
                      ],
                    ),
                    Text(
                      verse.arabicText,
                      textAlign: TextAlign.right,
                      textDirection: TextDirection.rtl,
                      style: AppText.quranAyah.copyWith(color: AppColors.text),
                    ),
                    const SizedBox(height: 8),
                    const Divider(),
                    const SizedBox(height: 4),
                    // Nastaliq for Urdu, Latin otherwise, decided from the text
                    // itself — this screen is never told which translation it
                    // was handed.
                    Text(
                      verse.translation,
                      textDirection: AppText.translationFor(verse.translation) ==
                              AppText.urduText
                          ? TextDirection.rtl
                          : TextDirection.ltr,
                      textAlign: AppText.translationFor(verse.translation) ==
                              AppText.urduText
                          ? TextAlign.right
                          : TextAlign.left,
                      style: AppText.translationFor(verse.translation)
                          .copyWith(color: AppColors.text),
                    ),
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
