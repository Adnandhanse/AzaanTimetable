import 'package:flutter/material.dart';

import '../models/hadith.dart';
import '../screens/hadith_list_screen.dart';
import '../theme/app_theme.dart';
import 'hadith_repository.dart';

/// A citation: a book and a hadith number, nothing more.
///
/// Deliberately not a chapter as well. The chapter is derivable from the number
/// and storing it would mean two facts that can disagree — and if they ever
/// did, the app would open the wrong hadith while looking perfectly correct.
class HadithRef {
  const HadithRef({required this.book, required this.number, this.note});

  final HadithBook book;
  final int number;

  /// Optional: why this hadith is cited here.
  final String? note;

  String get label => '${book.displayName} ${number}';
}

/// Opens a cited hadith in the normal reader.
///
/// This is the piece that makes references useful rather than decorative. A
/// citation the user has to go and find by hand is barely better than no
/// citation.
class HadithLink {
  HadithLink._();

  /// Loads the book, finds which chapter holds [ref], and opens the reader
  /// scrolled to that hadith with it outlined.
  ///
  /// Async and potentially slow — the collections are large — so it shows a
  /// blocking spinner. Doing it silently would look like a dead tap.
  static Future<void> open(
    BuildContext context,
    HadithRef ref, {
    HadithLanguage language = HadithLanguage.english,
  }) async {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    HadithCollection? collection;
    String? error;
    try {
      collection = await HadithRepository.loadCollection(ref.book, language);
    } catch (e) {
      error = e.toString();
    }

    if (!context.mounted) return;
    Navigator.of(context).pop(); // dismiss the spinner

    if (collection == null) {
      _complain(context, 'Could not open ${ref.book.displayName}: $error');
      return;
    }

    // Which chapter holds this number.
    HadithItem? item;
    for (final HadithItem h in collection.hadiths) {
      if (h.hadithNumber == ref.number) {
        item = h;
        break;
      }
    }
    if (item == null) {
      // A citation pointing at a hadith the data does not contain is a content
      // error, and saying so plainly is better than opening the wrong thing.
      _complain(context,
          'Hadith ${ref.number} was not found in ${ref.book.displayName}.');
      return;
    }

    HadithChapter? chapter;
    for (final HadithChapter c in collection.chapters) {
      if (c.number == item.chapterNumber) {
        chapter = c;
        break;
      }
    }
    chapter ??= HadithChapter(number: item.chapterNumber, title: 'Chapter ${item.chapterNumber}');

    if (!context.mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => HadithListScreen(
          collection: collection!,
          chapter: chapter!,
          bookKey: ref.book.fileKey,
          language: language == HadithLanguage.english ? 'eng' : 'urd',
          highlightHadithNumber: ref.number,
        ),
      ),
    );
  }

  static void _complain(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 4)),
    );
  }
}

/// A tappable citation. Looks like a link because it behaves like one.
class HadithRefChip extends StatelessWidget {
  const HadithRefChip({super.key, required this.ref});

  final HadithRef ref;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => HadithLink.open(context, ref),
        borderRadius: BorderRadius.circular(4),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 7),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const Padding(
                padding: EdgeInsets.only(top: 1),
                child: Icon(Icons.link, size: 15, color: AppColors.gold),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      ref.label,
                      style: AppText.body.copyWith(
                        color: AppColors.emerald,
                        decoration: TextDecoration.underline,
                        decorationColor: AppColors.gold,
                      ),
                    ),
                    if (ref.note != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 1),
                        child: Text(
                          ref.note!,
                          style: AppText.caption
                              .copyWith(color: AppColors.textMuted),
                        ),
                      ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, size: 16, color: AppColors.chevron),
            ],
          ),
        ),
      ),
    );
  }
}
