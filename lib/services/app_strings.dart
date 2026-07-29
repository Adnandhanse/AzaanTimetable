import 'app_language.dart';

/// App-wide UI text translations. Content that's already sourced in
/// multiple languages (Quran, Hadith text itself) has its own language
/// picker already - this covers the surrounding UI chrome (headings,
/// button labels, prayer names) so the whole app feels native in
/// whichever language the user picks.
class S {
  static String _t(String en, String ur) => AppLanguageController.instance.isUrdu ? ur : en;

  static String get appTitle => _t('Masjid Namaz Alarm', 'مسجد نماز الارم');
  static String get prayerTime => _t('Prayer Time', 'نماز کا وقت');
  static String get quran => _t('Quran', 'قرآن');
  static String get hadith => _t('Hadith', 'حدیث');
  static String get prayers => _t('Prayers', 'عبادات');
  static String get masjidAdmin => _t('Masjid Admin', 'مسجد ایڈمن');
  static String get settings => _t('Settings', 'ترتیبات');

  static String get todaysPrayerTimes => _t("Today's Prayer Times", 'آج کے نماز کے اوقات');
  static String get changeMasjid => _t('Change Masjid', 'مسجد تبدیل کریں');
  static String get getDirections => _t('Get Directions', 'راستہ دکھائیں');
  static String get findQiblaDirection => _t('Find Qibla Direction', 'قبلہ کی سمت معلوم کریں');
  static String get nearbyMasjid => _t('Nearby Masjid', 'قریبی مسجد');
  static String get viewFullPrayerSchedule => _t('View Full Prayer Schedule', 'مکمل نماز شیڈول دیکھیں');
  static String get noMasjidSelected => _t(
        'No masjid selected yet.\nTap "Change Masjid" below to follow one.',
        'ابھی تک کوئی مسجد منتخب نہیں کی گئی۔\nپیروی کرنے کے لیے نیچے "مسجد تبدیل کریں" پر ٹیپ کریں۔',
      );
  static String get nextPrayer => _t('Next Prayer', 'اگلی نماز');

  static String get fajr => _t('Fajr', 'فجر');
  static String get dhuhr => _t('Dhuhr', 'ظہر');
  static String get asr => _t('Asr', 'عصر');
  static String get maghrib => _t('Maghrib', 'مغرب');
  static String get isha => _t('Isha', 'عشاء');
  static String get juma => _t('Juma (Friday)', 'جمعہ');

  static String get verified => _t('Verified', 'تصدیق شدہ');
  static String get pendingVerification => _t('Pending Verification', 'توثیق زیر التواء');
}
