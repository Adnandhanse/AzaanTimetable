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

  /// Every AppColors getter picks its value from here, keyed by
  /// AppThemeController's current themeId. Adding a fully-designed theme
  /// from here on is just adding one more key to each of these maps - the
  /// const-removal/getter-conversion work (the actually large one-time
  /// cost) only had to happen once.
  static T _pick<T>(Map<String, T> options) =>
      options[AppThemeController.instance.themeId] ?? options['green_light']!;

  // page background
  static Color get ivory => _pick({
        'green_light': const Color(0xFFFAF7F0),
        'black_gold': const Color(0xFF0B1211),
        'green_dark': const Color(0xFF0D1B16),
        'blue': const Color(0xFFF2F6FB),
        'amber': const Color(0xFFFBF6EC),
        'purple': const Color(0xFFF7F4FA),
      });

  // cards, headers, nav bar
  static Color get white => _pick({
        'green_light': const Color(0xFFFFFFFF),
        'black_gold': const Color(0xFF101D1A),
        'green_dark': const Color(0xFF14261F),
        'blue': const Color(0xFFFFFFFF),
        'amber': const Color(0xFFFFFFFF),
        'purple': const Color(0xFFFFFFFF),
      });

  /// Sits between white and ivory - Material 3 surface containers (menus,
  /// bottom sheets, anything layered over the page).
  static Color get cream => _pick({
        'green_light': const Color(0xFFF4EFE3),
        'black_gold': const Color(0xFF16211D),
        'green_dark': const Color(0xFF182D25),
        'blue': const Color(0xFFE7EFF7),
        'amber': const Color(0xFFF5EBD6),
        'purple': const Color(0xFFEDE6F5),
      });

  // primary. Each theme keeps its own named colour as the actual primary
  // (blue is blue, amber is amber, purple is purple) rather than every
  // theme secretly still being green underneath - gold stays the one
  // constant across all of them as the shared "accent" identity, which is
  // what actually ties the themes together as one family.
  static Color get emerald => _pick({
        'green_light': const Color(0xFF0F5E3A),
        'black_gold': const Color(0xFF2A9D6F),
        'green_dark': const Color(0xFF34A874),
        'blue': const Color(0xFF1D5A8F),
        'amber': const Color(0xFFA9601A),
        'purple': const Color(0xFF6B3FA0),
      });

  static Color get emeraldTint => _pick({
        'green_light': const Color(0xFF2C6653),
        'black_gold': const Color(0xFF1F5E45),
        'green_dark': const Color(0xFF2A6B4C),
        'blue': const Color(0xFF3D7BAE),
        'amber': const Color(0xFFC67F33),
        'purple': const Color(0xFF8A63B8),
      });

  // accent, ornament - gold stays close to the same value across every
  // theme (see note on `emerald` above), only shifting where a theme's own
  // background genuinely needs a brighter or muted version for contrast.
  static Color get gold => _pick({
        'green_light': const Color(0xFFC79A2E),
        'black_gold': const Color(0xFFD4AF57),
        'green_dark': const Color(0xFFC9A227),
        'blue': const Color(0xFFC79A2E),
        'amber': const Color(0xFFC79A2E),
        'purple': const Color(0xFFC79A2E),
      });

  /// Muted, sophisticated gold used specifically for JAMAT time values -
  /// kept distinct from the brighter ornamental [gold] above so tuning one
  /// does not ripple into the other.
  static Color get champagneGold => _pick({
        'green_light': const Color(0xFFB08D57),
        'black_gold': const Color(0xFFC9A45C),
        'green_dark': const Color(0xFFB8963E),
        'blue': const Color(0xFFB08D57),
        'amber': const Color(0xFFB08D57),
        'purple': const Color(0xFFB08D57),
      });

  // Hairline borders / list separators.
  static Color get goldRule => _pick({
        'green_light': const Color(0xFFE8DFC9),
        'black_gold': const Color(0xFF2A3530),
        'green_dark': const Color(0xFF24382E),
        'blue': const Color(0xFFD9E3ED),
        'amber': const Color(0xFFEBDAB8),
        'purple': const Color(0xFFE1D5EE),
      });

  static Color get goldRuleFaint => _pick({
        'green_light': const Color(0xFFEFE7D3),
        'black_gold': const Color(0xFF1D2622),
        'green_dark': const Color(0xFF1A2921),
        'blue': const Color(0xFFEEF3F8),
        'amber': const Color(0xFFF5ECDA),
        'purple': const Color(0xFFF1EAF8),
      });

  static Color get goldPale => _pick({
        'green_light': const Color(0xFFD9C27E),
        'black_gold': const Color(0xFFE8CD8A),
        'green_dark': const Color(0xFFD9C27E),
        'blue': const Color(0xFFD9C27E),
        'amber': const Color(0xFFE0BC6E),
        'purple': const Color(0xFFD9C27E),
      });

  static Color get text => _pick({
        'green_light': const Color(0xFF1B1B1B),
        'black_gold': const Color(0xFFF4F0E5),
        'green_dark': const Color(0xFFEDEFE9),
        'blue': const Color(0xFF1B2430),
        'amber': const Color(0xFF2A1F12),
        'purple': const Color(0xFF241B2E),
      });

  static Color get textMid => _pick({
        'green_light': const Color(0xFF5C6560),
        'black_gold': const Color(0xFFC9C4B8),
        'green_dark': const Color(0xFFA9B6AC),
        'blue': const Color(0xFF4B5A68),
        'amber': const Color(0xFF6B5A40),
        'purple': const Color(0xFF5A4A6B),
      });

  static Color get textMuted => _pick({
        'green_light': const Color(0xFF6B6B6B),
        'black_gold': const Color(0xFF9C9686),
        'green_dark': const Color(0xFF8CA192),
        'blue': const Color(0xFF6B7684),
        'amber': const Color(0xFF7D6B4E),
        'purple': const Color(0xFF705E80),
      });

  static Color get textFaint => _pick({
        'green_light': const Color(0xFFB5AC98),
        'black_gold': const Color(0xFF6B6558),
        'green_dark': const Color(0xFF5E6D62),
        'blue': const Color(0xFFA8B4C0),
        'amber': const Color(0xFFBFAE8C),
        'purple': const Color(0xFFB7A6C4),
      });

  static Color get chevron => _pick({
        'green_light': const Color(0xFFC0B79F),
        'black_gold': const Color(0xFF8A8474),
        'green_dark': const Color(0xFF7E9184),
        'blue': const Color(0xFF9DAAB8),
        'amber': const Color(0xFFC2AE84),
        'purple': const Color(0xFFAC9BBC),
      });

  static Color get navInactive => _pick({
        'green_light': const Color(0xFFA9A192),
        'black_gold': const Color(0xFF6B6558),
        'green_dark': const Color(0xFF5E6D62),
        'blue': const Color(0xFF93A0AC),
        'amber': const Color(0xFFB0A080),
        'purple': const Color(0xFF9F8DB0),
      });

  static Color get onEmeraldMuted => _pick({
        'green_light': const Color(0xFFA9C0B6),
        'black_gold': const Color(0xFFB8C9BE),
        'green_dark': const Color(0xFFB8C9BE),
        'blue': const Color(0xFFB7CBDB),
        'amber': const Color(0xFFE8CFA6),
        'purple': const Color(0xFFD4C2E3),
      });

  static Color get kaabaBlack => const Color(0xFF000000); // same in every theme

  static Color get textDim => _pick({
        'green_light': const Color(0xFF8B8676),
        'black_gold': const Color(0xFF7A7568),
        'green_dark': const Color(0xFF6D7A70),
        'blue': const Color(0xFF7C8794),
        'amber': const Color(0xFF8F7C5C),
        'purple': const Color(0xFF8A7896),
      });

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
