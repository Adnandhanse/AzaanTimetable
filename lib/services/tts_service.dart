import 'package:flutter_tts/flutter_tts.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

  static const _rateKey = 'tts_speech_rate';

  /// The speeds offered. 0.45 is the default and roughly natural for this
  /// engine; 0.35 is for someone following along word by word, 0.75 for a
  /// re-read.
  ///
  /// Deliberately a short list rather than a slider. A slider invites fiddling
  /// and lands people on rates that are unintelligible, and the difference
  /// between 0.52 and 0.55 is not something anyone can hear.
  static const List<(String, double)> speeds = <(String, double)>[
    ('0.75\u00d7', 0.35),
    ('1\u00d7', 0.45),
    ('1.25\u00d7', 0.6),
    ('1.5\u00d7', 0.75),
  ];

  static Future<double> speechRate() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getDouble(_rateKey) ?? 0.45;
    } catch (_) {
      return 0.45;
    }
  }

  static Future<void> setSpeechRate(double rate) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble(_rateKey, rate);
      await _tts.setSpeechRate(rate);
    } catch (_) {}
  }

  static Future<void> _configure() async {
    if (_configured) return;
    _configured = true;
    try {
      await _tts.awaitSpeakCompletion(true);
      // Slower than the engine default. Hadith translations are long sentences
      // full of unfamiliar names; at default speed they are hard to follow.
      await _tts.setSpeechRate(await speechRate());
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
      // Re-applied on every utterance: a rate changed mid-listen should take
      // effect on the next play, not on the next app launch.
      await _tts.setSpeechRate(await speechRate());
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
