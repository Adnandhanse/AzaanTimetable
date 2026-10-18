import 'package:flutter/material.dart';
import '../models/hadith.dart';
import 'hadith_chapters_screen.dart';

/// Kept for compatibility with older home-screen imports.
/// The classic book -> chapters -> hadith flow is now the only entry path.
class HadithGradeSectionsScreen extends StatelessWidget {
  const HadithGradeSectionsScreen({super.key, required this.book, required this.language});
  final HadithBook book;
  final HadithLanguage language;

  @override
  Widget build(BuildContext context) => HadithChaptersScreen(book: book, language: language);
}
