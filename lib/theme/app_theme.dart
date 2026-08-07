import 'package:flutter/material.dart';

/// Direction A — "Illuminated".
///
/// Single source of truth for colour and type. If a screen needs something not
/// in here, that's a design decision, not a code decision — add it here rather
/// than inlining a hex value in a widget.
class AppColors {
  AppColors._();

  // Palette set to the exact values specified.
  static const Color ivory = Color(0xFFFAF7F0); // page background
  static const Color white = Color(0xFFFFFFFF); // cards, headers, nav bar

  /// Sits between white and ivory. Used for Material 3 surface containers —
  /// menus, bottom sheets, anything layered over the page — so they read as
  /// slightly recessed rather than picking up the seed-derived blue-green.
  static const Color cream = Color(0xFFF4EFE3);
  static const Color emerald = Color(0xFF0F5E3A); // primary
  static const Color emeraldTint = Color(0xFF2C6653); // ring track on emerald
  static const Color gold = Color(0xFFC79A2E); // accent, ornament
  static const Color goldRule = Color(0xFFE8DFC9); // hairline borders
  static const Color goldRuleFaint = Color(0xFFEFE7D3); // list separators
  static const Color goldPale = Color(0xFFD9C27E); // labels on emerald
  static const Color text = Color(0xFF1B1B1B);
  static const Color textMid = Color(0xFF5C6560);
  static const Color textMuted = Color(0xFF6B6B6B);
  static const Color textFaint = Color(0xFFB5AC98);
  static const Color chevron = Color(0xFFC0B79F);
  static const Color navInactive = Color(0xFFA9A192);
  static const Color onEmeraldMuted = Color(0xFFA9C0B6);
  static const Color kaabaBlack = Color(0xFF23241F);
  static const Color textDim = Color(0xFF8B8676);

  /// Kept for the exact-alarm warning banner. Amber carries meaning there, so
  /// it deliberately sits outside the palette.
  static const Color warningBg = Color(0xFFFFF3CD);
  static const Color warningFg = Color(0xFF8A5A00);
}

class AppFonts {
  AppFonts._();

  /// Display face — names, screen titles, all clock times.
  ///
  /// 'serif' is Android's built-in serif (Noto Serif). It needs no font file,
  /// so the build stays green with nothing added to assets.
  ///
  /// To upgrade to Cormorant Garamond: drop the two .ttf files into
  /// assets/fonts/, uncomment the Cormorant block in pubspec.yaml, and change
  /// this one line to 'Cormorant'. Nothing else in the app needs touching.
  static const String serif = 'serif';

  /// QUR'AN TEXT ONLY — the KFGQPC Madani Mushaf face.
  ///
  /// Kept separate from [arabic] deliberately. Qur'an should be set in the
  /// Mushaf face people recognise from print; hadith and duas should not,
  /// because setting a narration in the Mushaf face implies it carries the
  /// same status as revelation.
  static const String quran = 'UthmanicHafs';

  /// Urdu. Nastaliq is the script Urdu is actually written in — Naskh renders
  /// it legibly but wrongly, the way English set in Fraktur is legible but
  /// wrong.
  ///
  /// It needs far more line height than Latin or Naskh: the script descends
  /// steeply and letters overlap vertically, so 1.8 is a floor, not a
  /// preference.
  static const String urdu = 'NotoNastaliqUrdu';

  /// Already bundled — Inter-Variable.ttf.
  static const String sans = 'Inter';

  /// Already bundled — Amiri-Regular.ttf and Amiri-Bold.ttf.
  static const String arabic = 'Amiri';
}

class AppText {
  AppText._();

  /// Small tracked label. Uppercase at the call site.
  static const TextStyle eyebrow = TextStyle(
    fontFamily: AppFonts.sans,
    fontSize: 11,
    fontWeight: FontWeight.w500,
    letterSpacing: 1.6,
    height: 1.2,
  );

  static const TextStyle screenTitle = TextStyle(
    fontFamily: AppFonts.serif,
    fontSize: 22,
    fontWeight: FontWeight.w600,
    height: 1.15,
  );

  static const TextStyle displayName = TextStyle(
    fontFamily: AppFonts.serif,
    fontSize: 23,
    fontWeight: FontWeight.w600,
    height: 1.15,
  );

  /// The next-prayer time and the qibla bearing — the two numbers this app
  /// exists to show.
  static const TextStyle hero = TextStyle(
    fontFamily: AppFonts.serif,
    fontSize: 44,
    fontWeight: FontWeight.w600,
    height: 1.1,
    fontFeatures: <FontFeature>[FontFeature.tabularFigures()],
  );

  static const TextStyle rowTitle = TextStyle(
    fontFamily: AppFonts.serif,
    fontSize: 17,
    fontWeight: FontWeight.w600,
    height: 1.2,
  );

  static const TextStyle listTime = TextStyle(
    fontFamily: AppFonts.serif,
    fontSize: 19,
    fontWeight: FontWeight.w600,
    height: 1.2,
    fontFeatures: <FontFeature>[FontFeature.tabularFigures()],
  );

  static const TextStyle body = TextStyle(
    fontFamily: AppFonts.sans,
    fontSize: 13,
    height: 1.35,
  );

  static const TextStyle caption = TextStyle(
    fontFamily: AppFonts.sans,
    fontSize: 11.5,
    height: 1.3,
  );

  /// Arabic scripture, at reading size. Every Qur'an verse and every hadith
  /// body in the app uses this one style — if you change the reading size,
  /// change it here and it changes everywhere.
  static const TextStyle arabicVerse = TextStyle(
    fontFamily: AppFonts.arabic,
    fontSize: 23,
    height: 2.0,
  );

  /// A Qur'an ayah, in the Mushaf face.
  static const TextStyle quranAyah = TextStyle(
    fontFamily: AppFonts.quran,
    fontSize: 30,
    height: 2.0,
  );

  /// Urdu translation.
  ///
  /// 18sp with 2.0 line height. Nastaliq needs the room — at the 1.55 the Latin
  /// translation style uses, the descenders of one line collide with the line
  /// below and it becomes genuinely hard to read.
  static const TextStyle urduText = TextStyle(
    fontFamily: AppFonts.urdu,
    fontSize: 18,
    height: 2.0,
  );

  /// Large Arabic, for surah and book titles.
  static const TextStyle arabicTitle = TextStyle(
    fontFamily: AppFonts.arabic,
    fontSize: 30,
    fontWeight: FontWeight.w700,
    height: 1.5,
  );

  /// The English/Urdu/Hindi translation sitting under a verse or hadith.
  static const TextStyle translation = TextStyle(
    fontFamily: AppFonts.sans,
    fontSize: 14.5,
    height: 1.55,
  );

  /// Arabic sits small on the line, so it needs a larger size than the Latin
  /// text beside it to read as the same weight.
  static const TextStyle arabic = TextStyle(
    fontFamily: AppFonts.arabic,
    fontSize: 18,
    height: 1.9,
  );
}

class AppTheme {
  AppTheme._();

  static ThemeData light() {
    final ColorScheme scheme = ColorScheme.fromSeed(
      seedColor: AppColors.emerald,
      brightness: Brightness.light,
    ).copyWith(
      primary: AppColors.emerald,
      secondary: AppColors.gold,
      surface: AppColors.ivory,
      onSurface: AppColors.text,

      // THIS IS THE FIX FOR THE "BLUISH" CARDS.
      //
      // Material 3 ignores ThemeData.cardColor. Card, Dialog, BottomSheet and
      // friends take their background from these surfaceContainer tones, which
      // Flutter derives from the seed colour's tonal palette. A green seed
      // produces a desaturated blue-green — which is what was showing up on
      // the admin, hadith and surah screens.
      //
      // Pinning them to our own ivory/cream/white removes the tint everywhere
      // at once. Do not delete these lines to "simplify" the theme.
      surfaceContainerLowest: AppColors.white,
      surfaceContainerLow: AppColors.white,
      surfaceContainer: AppColors.cream,
      surfaceContainerHigh: AppColors.cream,
      surfaceContainerHighest: AppColors.ivory,

      // Stops Material tinting surfaces by elevation, which reintroduces the
      // same cast through a different route.
      surfaceTint: Colors.transparent,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: AppColors.ivory,
      primaryColor: AppColors.emerald,
      cardColor: AppColors.white,
      fontFamily: AppFonts.sans,
      iconTheme: const IconThemeData(color: AppColors.text),
      // Every Card in the app: white, flat, gold hairline, 4px corners.
      // ~20 screens use bare Card widgets, so this is what makes them agree.
      cardTheme: CardTheme(
        color: AppColors.white,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.transparent,
        elevation: 0,
        margin: const EdgeInsets.symmetric(vertical: 5),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4),
          side: const BorderSide(color: AppColors.goldRule),
        ),
      ),

      dialogTheme: DialogTheme(
        backgroundColor: AppColors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4),
          side: const BorderSide(color: AppColors.goldRule),
        ),
      ),

      // Every text field, so the admin forms stop looking like a different app.
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.white,
        isDense: true,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        hintStyle: AppText.body.copyWith(color: AppColors.textFaint),
        labelStyle: AppText.body.copyWith(color: AppColors.textMuted),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide: const BorderSide(color: AppColors.goldRule),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide: const BorderSide(color: AppColors.goldRule),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide: const BorderSide(color: AppColors.gold),
        ),
      ),

      listTileTheme: const ListTileThemeData(
        tileColor: Colors.transparent,
        iconColor: AppColors.emerald,
      ),

      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.white,
        foregroundColor: AppColors.emerald,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        titleTextStyle: AppText.screenTitle,
        shape: Border(bottom: BorderSide(color: AppColors.goldRule)),
      ),
      textTheme: Typography.material2021().black.apply(
            fontFamily: AppFonts.sans,
            bodyColor: AppColors.text,
            displayColor: AppColors.text,
          ),
    );
  }
}
