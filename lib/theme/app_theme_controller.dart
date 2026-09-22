import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Which theme is live, app-wide, right now.
///
/// A single instance, read by every AppColors getter. The Settings screen's
/// theme picker changes [themeId] and calls [notifyListeners] (via [setTheme]);
/// main.dart wraps the whole app in an AnimatedBuilder/ListenableBuilder
/// listening to this controller, so that one change rebuilds every screen at
/// once with the new palette.
///
/// SCOPE NOTE: only 'green_light' (the app's existing default) and
/// 'black_gold' actually have real, hand-specified colours in AppColors
/// right now. Blue / Amber / Purple / System Default are listed in the
/// Settings picker (matching the requested 7-option list) but are NOT
/// selectable yet - each needs its own exact palette decided before it can
/// be built the same careful way Black & Gold was, rather than guessing
/// hex values that were never asked for.
class AppThemeController extends ChangeNotifier {
  AppThemeController._();
  static final AppThemeController instance = AppThemeController._();

  static const String _prefsKey = 'app_theme_id';

  String _themeId = 'green_light';
  String get themeId => _themeId;
  bool get isDark => _themeId == 'black_gold';

  /// Call once, early (e.g. in main() before runApp), so the persisted
  /// choice is loaded before the first frame - otherwise the app would
  /// flash the default theme for a moment even for someone who picked
  /// Black & Gold last time.
  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _themeId = prefs.getString(_prefsKey) ?? 'green_light';
    notifyListeners();
  }

  Future<void> setTheme(String id) async {
    if (id == _themeId) return;
    _themeId = id;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, id);
  }
}
