import 'package:flutter/material.dart';
import 'app_theme_controller.dart';

/// Direction A — "Illuminated" (the light-green default) plus "Black & Gold"
/// (the dark theme). Which one is live is decided at runtime by
/// [AppThemeController], not at compile time — that is the whole point of
/// every value here being a `get` rather than a `const`.
///
/// EVERY CALL SITE ACROSS THE APP THAT USED TO WRITE
/// `SomeWidget(color: AppColors.x)` had its `const` keyword removed. That is
/// not optional cleanup - Dart requires every value inside a const
/// constructor to be a compile-time constant, and a get that reads
/// AppThemeController's current value at runtime is not one. This was a
/// deliberate, one-time, all-at-once change across every affected file
/// (there is no way to do it gradually - the moment any one AppColors
/// member becomes a get, every const reference to ANY AppColors member,
/// anywhere in the app, stops compiling until its const is removed).
///
/// If a screen needs something not in here, that is a design decision, not
/// a code decision - add it here (in BOTH palettes below) rather than
/// inlining a hex value in a widget.
class AppColors {
  AppColors._();

  static bool get _dark => AppThemeController.instance.isDark;

  // page background
  static Color get ivory => _dark ? const Color(0xFF0B1211) : const Color(0xFFFAF7F0);
  // cards, headers, nav bar
  static Color get white => _dark ? const Color(0xFF101D1A) : const Color(0xFFFFFFFF);

  /// Sits between white and ivory - Material 3 surface containers (menus,
  /// bottom sheets, anything layered over the page).
  static Color get cream => _dark ? const Color(0xFF16211D) : const Color(0xFFF4EFE3);

  // primary. In Black & Gold this stays a genuine emerald rather than
  // becoming another gold - the brief asks for gold as an ACCENT against a
  // dark ground, not for green to disappear from the palette; it is
  // brightened here purely so it still reads clearly against #0B1211.
  static Color get emerald => _dark ? const Color(0xFF2A9D6F) : const Color(0xFF0F5E3A);
  static Color get emeraldTint => _dark ? const Color(0xFF1F5E45) : const Color(0xFF2C6653);

  // accent, ornament - #D4AF57 is the exact champagne gold specified for
  // Black & Gold.
  static Color get gold => _dark ? const Color(0xFFD4AF57) : const Color(0xFFC79A2E);

  /// Muted, sophisticated gold used specifically for JAMAT time values -
  /// kept distinct from the brighter ornamental [gold] above so tuning one
  /// does not ripple into the other.
  static Color get champagneGold => _dark ? const Color(0xFFC9A45C) : const Color(0xFFB08D57);

  // Hairline borders / list separators. "Subtle gold outlines instead of
  // bright borders" in dark mode, per spec - a muted gold-gray, not the
  // bright accent gold itself.
  static Color get goldRule => _dark ? const Color(0xFF2A3530) : const Color(0xFFE8DFC9);
  static Color get goldRuleFaint => _dark ? const Color(0xFF1D2622) : const Color(0xFFEFE7D3);
  static Color get goldPale => _dark ? const Color(0xFFE8CD8A) : const Color(0xFFD9C27E);

  // #F4F0E5 warm off-white is the exact primary-text value specified.
  static Color get text => _dark ? const Color(0xFFF4F0E5) : const Color(0xFF1B1B1B);
  static Color get textMid => _dark ? const Color(0xFFC9C4B8) : const Color(0xFF5C6560);
  // muted gold/gray secondary text, per spec.
  static Color get textMuted => _dark ? const Color(0xFF9C9686) : const Color(0xFF6B6B6B);
  static Color get textFaint => _dark ? const Color(0xFF6B6558) : const Color(0xFFB5AC98);
  static Color get chevron => _dark ? const Color(0xFF8A8474) : const Color(0xFFC0B79F);
  static Color get navInactive => _dark ? const Color(0xFF6B6558) : const Color(0xFFA9A192);
  static Color get onEmeraldMuted => _dark ? const Color(0xFFB8C9BE) : const Color(0xFFA9C0B6);
  static Color get kaabaBlack => const Color(0xFF000000); // already black either way
  static Color get textDim => _dark ? const Color(0xFF7A7568) : const Color(0xFF8B8676);

  /// The exact-alarm warning banner. Amber carries meaning there regardless
  /// of theme, so it is NOT theme-switched - a warning should look like a
  /// warning in every palette.
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

  /// QUR'AN TEXT ONLY — PDMS Saleem QuranFont.
  ///
  /// Kept separate from [arabic] deliberately. Qur'an should be set in a
  /// dedicated Qur'an face; hadith and duas should not, because setting a
  /// narration in that face implies it carries the same status as
  /// revelation. The family name stays 'UthmanicHafs' (see pubspec.yaml) so
  /// this reference didn't need to change.
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
  /// Picks the right face for a translation by looking at the text itself.
  ///
  /// Urdu is written in Arabic script; English is not. Detecting that is more
  /// reliable than threading a language parameter through every screen, and it
  /// cannot fall out of step with what is actually being displayed — which is
  /// exactly what happened in the Qur'an reader, where the screen never knew
  /// which translation it had been given.
  ///
  /// Devanagari (Hindi) falls through to the Latin style, which renders it
  /// correctly with the system font.
  static TextStyle translationFor(String text) =>
      _isArabicScript(text) ? urduText : translation;

  static bool _isArabicScript(String text) {
    // Sample the first 60 characters rather than scanning a whole ayah: the
    // script is decided within the first word.
    final sample = text.length > 60 ? text.substring(0, 60) : text;
    for (final int c in sample.runes) {
      if (c >= 0x0600 && c <= 0x06FF) return true; // Arabic block
      if (c >= 0x0750 && c <= 0x077F) return true; // Arabic Supplement
      if (c >= 0xFB50 && c <= 0xFDFF) return true; // Presentation Forms-A
    }
    return false;
  }

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
      iconTheme: IconThemeData(color: AppColors.text),
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
          side: BorderSide(color: AppColors.goldRule),
        ),
      ),

      dialogTheme: DialogTheme(
        backgroundColor: AppColors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4),
          side: BorderSide(color: AppColors.goldRule),
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
          borderSide: BorderSide(color: AppColors.goldRule),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide: BorderSide(color: AppColors.goldRule),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide: BorderSide(color: AppColors.gold),
        ),
      ),

      listTileTheme: ListTileThemeData(
        tileColor: Colors.transparent,
        iconColor: AppColors.emerald,
      ),

      appBarTheme: AppBarTheme(
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
