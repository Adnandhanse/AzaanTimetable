import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:masjid_alarm_app/services/prayer_notification_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('existing users keep Azaan and all prayer alerts enabled', () async {
    expect(await PrayerNotificationPreferences.soundEnabled(), isTrue);
    for (final key in PrayerNotificationPreferences.keys) {
      expect(await PrayerNotificationPreferences.enabled(key), isTrue);
    }
  });

  test('sound off survives reload and can be enabled again', () async {
    await PrayerNotificationPreferences.setSoundEnabled(false);
    expect(await PrayerNotificationPreferences.soundEnabled(), isFalse);
    await PrayerNotificationPreferences.setSoundEnabled(true);
    expect(await PrayerNotificationPreferences.soundEnabled(), isTrue);
  });

  test('prayer choices are independent from each other and sound', () async {
    await PrayerNotificationPreferences.setEnabled('fajr', false);
    await PrayerNotificationPreferences.setSoundEnabled(false);
    expect(await PrayerNotificationPreferences.enabled('fajr'), isFalse);
    expect(await PrayerNotificationPreferences.enabled('asr'), isTrue);
    await PrayerNotificationPreferences.setEnabled('fajr', true);
    expect(await PrayerNotificationPreferences.enabled('fajr'), isTrue);
    expect(await PrayerNotificationPreferences.soundEnabled(), isFalse);
  });

  test('background service maps Friday label to stable preference key', () {
    expect(PrayerNotificationPreferences.keyForLabel('Juma (Friday)'), 'juma');
    expect(PrayerNotificationPreferences.keyForLabel('Dhuhr'), 'dhuhr');
  });
}
