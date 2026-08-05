import 'app_language.dart';

/// App-wide UI text translations. Content that's already sourced in
/// multiple languages (Quran, Hadith text itself) has its own language
/// picker already - this covers the surrounding UI chrome (headings,
/// button labels, prayer names) so the whole app feels native in
/// whichever language the user picks.
class S {
  static String _t(String en, String ur) => AppLanguageController.instance.isUrdu ? ur : en;
  static bool get isUrdu => AppLanguageController.instance.isUrdu;

  static String get appTitle => _t('Masjid Namaz Alarm', 'مسجد نماز الارم');
  static String get prayerTime => _t('Prayer Time', 'نماز کا وقت');
  static String get quran => _t('Quran', 'قرآن');
  static String get hadith => _t('Hadith', 'حدیث');
  static String get prayers => _t('Prayers', 'عبادات');
  static String get masjidAdmin => _t('Masjid Admin', 'مسجد ایڈمن');
  static String get settings => _t('Settings', 'ترتیبات');

  // --- Hadith screens -------------------------------------------------------
  //
  // These were hardcoded English in the screens I wrote, so they stayed English
  // even with the app set to Urdu. That is what made the headers look
  // half-translated.
  static String get searchChapterOrNumber =>
      _t('Chapter name, or a hadith number', 'باب کا نام یا حدیث نمبر');
  static String get searchHadithText =>
      _t('Search hadith text', 'حدیث کا متن تلاش کریں');
  static String get goToHadith => _t('GO TO HADITH', 'حدیث پر جائیں');
  static String get hadithWord => _t('Hadith', 'حدیث');
  static String get arabicEdition => _t('Arabic ed.', 'عربی ایڈیشن');
  static String get totalWord => _t('total', 'کل');
  static String get tapToReadFull => _t('Tap to read in full', 'مکمل پڑھنے کے لیے دبائیں');
  static String get collapse => _t('Collapse', 'بند کریں');
  static String get listenToTranslation =>
      _t('Listen to translation', 'ترجمہ سنیں');
  static String get stopWord => _t('Stop', 'روکیں');
  static String get gradings => _t('GRADINGS', 'درجات');
  static String get previousWord => _t('Previous', 'پچھلی');
  static String get nextWord => _t('Next', 'اگلی');
  static String get readWholeChapter =>
      _t('Read the whole chapter', 'پورا باب پڑھیں');
  static String get noTranslationAvailable => _t(
      'No translation available for this hadith in the offline dataset.',
      'اس حدیث کا ترجمہ آف لائن ڈیٹا میں موجود نہیں ہے۔');
  static String get chapterNamesEnglishNote => _t(
      'Chapter names are shown in English \u2014 the offline hadith dataset does not include Urdu chapter names. The hadith text itself is in Urdu.',
      'باب کے نام انگریزی میں ہیں \u2014 آف لائن حدیث ڈیٹا میں باب کے اردو نام شامل نہیں۔ حدیث کا متن اردو میں ہے۔');
  static String get urduTitlesUnverifiedNote => _t(
      'Urdu chapter names are a first draft and have not been checked by a scholar.',
      'باب کے اردو نام ابتدائی مسودہ ہیں اور کسی عالم نے ان کی تصدیق نہیں کی۔');
  // --- Zakat calculator ----------------------------------------------------
  static String get zakatCalculator => _t('Zakat Calculator', 'زکوٰۃ کیلکولیٹر');
  static String get zakatApplicable =>
      _t('Zakat Applicable', 'زکوٰۃ لاگو ہوتی ہے');
  static String get zakatNotApplicable =>
      _t('Zakat Not Applicable', 'زکوٰۃ لاگو نہیں ہوتی');
  static String get nisabBasis => _t('Nisab', 'نصاب');
  static String get silverNisab => _t('Silver Nisab (595g)', 'چاندی کا نصاب (595 گرام)');
  static String get goldNisab => _t('Gold Nisab (85g)', 'سونے کا نصاب (85 گرام)');
  static String get goldLabel => _t('Gold', 'سونا');
  static String get silverLabel => _t('Silver', 'چاندی');
  static String get cashLabel => _t('Cash / Savings', 'نقد / بچت');
  static String get liabilitiesLabel => _t('Liabilities / Debts', 'واجبات / قرض');
  static String get gramsLabel => _t('Grams', 'گرام');
  static String get purityLabel => _t('Purity', 'خالص پن');
  static String get karatLabel => _t('Karat', 'قیراط');
  static String get ratePerGram => _t('Rate per gram', 'فی گرام قیمت');
  static String get todaysRates => _t("Today's rates", 'آج کی قیمتیں');
  static String get updateRates => _t('Update rates', 'قیمتیں اپ ڈیٹ کریں');
  static String get netAssets => _t('Net assets', 'خالص مالیت');
  static String get nisabValue => _t('Nisab value', 'نصاب کی قیمت');
  static String get zakatDue => _t('Zakat due (2.5%)', 'واجب زکوٰۃ (2.5%)');
  static String get ratesNeeded => _t(
      'Enter today\'s gold and silver rate to begin.',
      'شروع کرنے کے لیے آج کی سونے اور چاندی کی قیمت درج کریں۔');
  static String get ratesStale => _t(
      'These rates are more than a day old. Update them before relying on the result.',
      'یہ قیمتیں ایک دن سے زیادہ پرانی ہیں۔ نتیجہ استعمال کرنے سے پہلے انہیں اپ ڈیٹ کریں۔');
  static String get zakatDisclaimer => _t(
      'This is an estimate based on the figures you entered. For anything uncertain, ask a scholar.',
      'یہ آپ کے درج کردہ اعداد پر مبنی ایک تخمینہ ہے۔ کسی بھی شک کی صورت میں عالم سے رجوع کریں۔');
  static String get save => _t('Save', 'محفوظ کریں');
  static String get rateIsFor => _t('This rate is for', 'یہ قیمت اس کے لیے ہے');
  static String get pureEquivalent => _t('Pure equivalent', 'خالص کے برابر');
  static String get breakdown => _t('Breakdown', 'تفصیل');
  static String get valueLabel => _t('Value', 'قیمت');
  static String get zakatOnThis => _t('Zakat 2.5%', 'زکوٰۃ 2.5%');
  static String get totalAssets => _t('Total assets', 'کل مالیت');
  static String get lessLiabilities => _t('Less liabilities', 'واجبات منہا');
  static String get breakdownNote => _t(
      'Zakat is due on the net total, not on each holding separately. These lines show where the amount comes from.',
      'زکوٰۃ خالص کل رقم پر واجب ہے، ہر مال پر الگ نہیں۔ یہ سطریں بتاتی ہیں کہ رقم کہاں سے آئی۔');

  static String get stepByStep => _t('Step by step', 'مرحلہ وار');
  static String get comingSoon => _t('Coming soon', 'جلد آ رہا ہے');
  static String get evidence => _t('EVIDENCE', 'دلائل');

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

  // Quran screen
  static String get bySurah => _t('By Surah', 'بالسورۃ');
  static String get byJuz => _t('By Juz', 'بالجزء');
  static String get favourites => _t('Favourites', 'پسندیدہ');
  static String get searchSurahHint => _t('Search Surah by name or number', 'سورۃ کا نام یا نمبر تلاش کریں');

  // Hadith screen
  static String get hadithBooks => _t('Hadith Books', 'کتب حدیث');
  static String get sixAuthenticBooks => _t('Kutub al-Sittah - The Six Authentic Books', 'کتب ستہ - چھ مستند کتابیں');
  static String get myBookmarks => _t('My Bookmarks', 'میرے پسندیدہ');
  static String get chapters => _t('Chapters', 'ابواب');

  // Prayers screen
  static String get fivePillars => _t('The Five Pillars of Islam', 'اسلام کے پانچ ارکان');
  static String get shahada => _t('Shahada', 'شہادت');
  static String get namaz => _t('Namaz (Salah)', 'نماز');
  static String get roza => _t('Roza (Sawm)', 'روزہ');
  static String get zakat => _t('Zakat', 'زکوٰۃ');
  static String get hajjUmrah => _t('Hajj / Umrah', 'حج / عمرہ');

  // Settings
  static String get appLanguage => _t('App Language', 'ایپ کی زبان');
  static String get azanSoundAlarm => _t('Azan Sound Alarm', 'اذان کی آواز');
  static String get vibrate => _t('Vibrate', 'وائبریٹ');
}
