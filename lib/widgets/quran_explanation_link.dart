import 'package:flutter/material.dart';
import '../models/quran.dart';
import '../services/app_strings.dart';
import '../theme/app_theme.dart';

/// Only source footnotes; never generates commentary or rewrites translation.
class QuranExplanationLink extends StatelessWidget {
  const QuranExplanationLink({super.key, required this.verse, required this.surah});
  final QuranVerse verse;
  final int surah;

  @override
  Widget build(BuildContext context) {
    if (verse.footnotes.trim().isEmpty) return const SizedBox.shrink();
    final rtl = RegExp(r'[\u0600-\u06FF]').hasMatch(verse.footnotes);
    final label = S.isUrdu ? 'تفسیر / وضاحت' : 'Tafseer / Explanation';
    final source = rtl
        ? 'QuranEnc.com • Urdu Junagarhi edition v1.1.3 • source footnotes'
        : 'QuranEnc.com • Hilali & Muhsin Khan v1.1.2 • source footnotes';
    return Align(
      alignment: rtl ? Alignment.centerRight : Alignment.centerLeft,
      child: TextButton(
        style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 0)),
        onPressed: () => showDialog<void>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: Text('$label • $surah:${verse.number}'),
            content: SizedBox(
              width: double.maxFinite,
              child: SingleChildScrollView(
                child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                  Text(
                    S.isUrdu
                        ? 'یہ اس ترجمے کے وضاحتی حواشی ہیں، الگ مکمل تفسیر نہیں۔'
                        : 'Explanatory notes supplied with this translation; not a separate complete tafsir.',
                    textDirection: S.isUrdu ? TextDirection.rtl : TextDirection.ltr,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 14),
                  SelectableText(
                    verse.footnotes,
                    textDirection: rtl ? TextDirection.rtl : TextDirection.ltr,
                    style: AppText.translationFor(verse.footnotes).copyWith(
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(source, style: Theme.of(context).textTheme.bodySmall),
                ]),
              ),
            ),
            actions: [TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(S.isUrdu ? 'بند کریں' : 'Close'),
            )],
          ),
        ),
        child: Text(label, style: const TextStyle(decoration: TextDecoration.underline)),
      ),
    );
  }
}
