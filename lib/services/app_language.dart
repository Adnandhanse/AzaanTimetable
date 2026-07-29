import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AppLanguage { english, urdu }

/// Global app language state - notifies all listening widgets when the
/// user switches language, and persists the choice locally so it's
/// remembered across app restarts.
class AppLanguageController extends ChangeNotifier {
  static final AppLanguageController instance = AppLanguageController._();
  AppLanguageController._();

  AppLanguage _language = AppLanguage.english;
  AppLanguage get language => _language;
  bool get isUrdu => _language == AppLanguage.urdu;

  static const _prefsKey = 'app_language';

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_prefsKey);
    _language = saved == 'urdu' ? AppLanguage.urdu : AppLanguage.english;
    notifyListeners();
  }

  Future<void> setLanguage(AppLanguage language) async {
    _language = language;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, language == AppLanguage.urdu ? 'urdu' : 'english');
  }
}
