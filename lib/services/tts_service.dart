import 'package:flutter_tts/flutter_tts.dart';

/// Reads TRANSLATIONS aloud. English and Urdu only.
///
/// WHY THERE IS NO ARABIC HERE, AND WHY THERE MUST NOT BE
///
/// Android's text-to-speech mispronounces Arabic badly — wrong vowels, wrong
/// stress, harakat ignored. Having a phone mispronounce the words of the
/// Prophet, or the Qur'an, inside a worship app is a religious problem rather
/// than a quality one. The Qur'an recitation in this app is a recording by a
/// qari for exactly that reason.
///
/// So this class only accepts a language code from a fixed list, and Arabic is
/// not on it. That is deliberate: a future change cannot casually start reading
/// Arabic aloud without deleting this comment first.
enum TtsLang { english, urdu }

class TtsService {
  TtsService._();

  static final FlutterTts _tts = FlutterTts();
  static bool _configured = false;

  /// Cached per language, because probing is slow and the answer never changes
  /// while the app is running.
  static final Map<TtsLang, bool> _available = <TtsLang, bool>{};

  static String _code(TtsLang l) =>
      l == TtsLang.english ? 'en-US' : 'ur-PK';

  static Future<void> _configure() async {
    if (_configured) return;
    _configured = true;
    try {
      await _tts.awaitSpeakCompletion(true);
      // Slightly slower than default. Hadith translations are long sentences
      // with unfamiliar names; default speed makes them hard to follow.
      await _tts.setSpeechRate(0.45);
      await _tts.setVolume(1.0);
      await _tts.setPitch(1.0);
    } catch (_) {}
  }

  /// Whether the device can actually speak this language.
  ///
  /// Urdu is frequently NOT installed — Google's TTS supports it but many
  /// handsets ship without the voice data. The UI must ask before offering the
  /// button, rather than presenting a control that silently does nothing.
  static Future<bool> isAvailable(TtsLang lang) async {
    final cached = _available[lang];
    if (cached != null) return cached;
    await _configure();
    bool ok = false;
    try {
      final dynamic result = await _tts.isLanguageAvailable(_code(lang));
      ok = result == true;
    } catch (_) {
      ok = false;
    }
    _available[lang] = ok;
    return ok;
  }

  /// Speaks [text] in [lang]. Returns false if it could not.
  ///
  /// Takes the language explicitly rather than guessing from the string,
  /// because guessing is how Arabic would eventually end up being read aloud.
  static Future<bool> speak(String text, TtsLang lang) async {
    if (text.trim().isEmpty) return false;
    await _configure();
    if (!await isAvailable(lang)) return false;
    try {
      await _tts.stop();
      await _tts.setLanguage(_code(lang));
      await _tts.speak(text);
      return true;
    } catch (_) {
      return false;
    }
  }

  static Future<void> stop() async {
    try {
      await _tts.stop();
    } catch (_) {}
  }

  /// Fired when speech finishes on its own, so a play button can reset itself
  /// rather than staying stuck on "playing".
  static void onComplete(void Function() callback) {
    try {
      _tts.setCompletionHandler(callback);
      _tts.setCancelHandler(callback);
      _tts.setErrorHandler((dynamic _) => callback());
    } catch (_) {}
  }
}
