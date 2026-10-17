import 'package:shared_preferences/shared_preferences.dart';

/// Stable keys shared by the home page, scheduler and background isolate.
class PrayerNotificationPreferences {
  static const keys = ['fajr', 'dhuhr', 'asr', 'maghrib', 'isha', 'juma'];
  static Future<bool> soundEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.reload();
    return prefs.getBool('prayer_azan_enabled') ?? true;
  }
  static Future<void> setSoundEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    if (!await prefs.setBool('prayer_azan_enabled', value)) {
      throw StateError('Could not save Azaan setting');
    }
  }
  static String keyForLabel(String label) =>
      label.toLowerCase().contains('juma') ? 'juma' : label.toLowerCase();
  static Future<bool> enabled(String key) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.reload();
    return prefs.getBool('prayer_notification_$key') ?? true;
  }
  static Future<void> setEnabled(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    if (!await prefs.setBool('prayer_notification_$key', value)) {
      throw StateError('Could not save notification setting');
    }
  }
}
