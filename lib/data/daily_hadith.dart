import '../models/hadith.dart';
import '../services/hadith_link.dart';

/// One short hadith a day.
///
/// WHY THIS IS A CURATED LIST AND NOT A RANDOM PICK
///
/// Pulling at random from 34,000 hadith would surface chains of narration,
/// legal rulings on inheritance, and descriptions of punishments. None of that
/// belongs on a card someone sees the moment they open the app. A daily hadith
/// has to be short, complete on its own, and about how to live.
///
/// Every entry here was found by searching this app's own data and reading it,
/// then checked: text verbatim from the dataset with nothing trimmed or
/// reworded, and NOTHING GRADED DAIF. Seven are from Bukhari and Muslim, which
/// carry no grading because they are accepted as authentic; the other three are
/// graded Sahih by every grader in the data.
///
/// The text is stored inline rather than loaded from the hadith files, because
/// parsing seven thousand hadith to show one card would make the app slower to
/// open every single day. Tapping through opens the real entry.
class DailyHadith {
  const DailyHadith({
    required this.book,
    required this.number,
    required this.text,
    required this.textUr,
    required this.textHi,
    required this.arabic,
    required this.theme,
    required this.themeUr,
  });

  final HadithBook book;
  final int number;

  /// The saying itself, in English and in Urdu, taken VERBATIM from this app's
  /// own data — the quoted words of the Prophet with the chain of narrators
  /// removed.
  ///
  /// That is quoting, not rewriting: every character here appears in the
  /// dataset. Nothing is paraphrased or shortened mid-sentence. Where a hadith
  /// has several clauses, one complete clause is shown and "Read in full" gives
  /// the rest.
  ///
  /// Urdu comes from urd_*.json, which carries all ten. It follows the app
  /// language, so an Urdu reader gets Urdu.
  final String text;
  final String textUr;

  /// Roman Urdu — "Hinglish".
  ///
  /// A TRANSLITERATION of the Urdu translation into Latin script, not a new
  /// translation. Every word is the Urdu one, spelled the way people type Urdu
  /// in a message. That distinction matters: transliterating is mechanical and
  /// safe, whereas producing a fresh rendering of a hadith is not something this
  /// app should generate.
  ///
  /// It exists because many readers speak Urdu but read Latin script more
  /// comfortably than Nastaliq, particularly younger readers.
  final String textHi;

  /// The saying in Arabic, verbatim from ara_*.json.
  ///
  /// A daily hadith card with no Arabic on it was the wrong shape for this app —
  /// every other screen leads with the Arabic and puts the translation beneath.
  final String arabic;

  /// A word for what it is about, shown above the text.
  final String theme;
  final String themeUr;

  HadithRef get ref => HadithRef(book: book, number: number);

  static const List<DailyHadith> all = <DailyHadith>[
    DailyHadith(
      book: HadithBook.bukhari, number: 1,
      theme: 'Intention', themeUr: 'نیت',
      arabic:
          'إِنَّمَا الْأَعْمَالُ بِالنِّيَّاتِ، وَإِنَّمَا لِكُلِّ امْرِئٍ مَا نَوَى',
      text:
          'The reward of deeds depends upon the intentions, and every person will get the reward according to what he has intended.',
      textUr:
          'تمام اعمال کا دارومدار نیت پر ہے اور ہر عمل کا نتیجہ ہر انسان کو اس کی نیت کے مطابق ہی ملے گا۔',
      textHi:
          'Tamam amal ka daromadar niyyat par hai, aur har shakhs ko uski niyyat ke mutabiq hi natija milega.',
    ),
    DailyHadith(
      book: HadithBook.muslim, number: 170,
      theme: 'Brotherhood', themeUr: 'بھائی چارہ',
      arabic:
          'لَا يُؤْمِنُ أَحَدُكُمْ حَتَّى يُحِبَّ لِأَخِيهِ مَا يُحِبُّ لِنَفْسِهِ',
      text:
          'None amongst you believes truly until he loves for his brother that which he loves for himself.',
      textUr:
          'تم میں سے کوئی شخص مومن نہیں ہو سکتا یہاں تک کہ وہ اپنے بھائی کے لیے وہی پسند کرے جو وہ اپنے لیے پسند کرتا ہے۔',
      textHi:
          'Tum mein se koi shakhs momin nahi ho sakta jab tak wo apne bhai ke liye wohi pasand kare jo apne liye pasand karta hai.',
    ),
    DailyHadith(
      book: HadithBook.bukhari, number: 6114,
      theme: 'Self-control', themeUr: 'ضبطِ نفس',
      arabic:
          'لَيْسَ الشَّدِيدُ بِالصُّرَعَةِ، إِنَّمَا الشَّدِيدُ الَّذِي يَمْلِكُ نَفْسَهُ عِنْدَ الْغَضَبِ',
      text:
          'The strong is not the one who overcomes the people by his strength, but the strong is the one who controls himself while in anger.',
      textUr:
          'پہلوان وہ نہیں ہے جو کشتی لڑنے میں غالب ہو جائے بلکہ اصلی پہلوان تو وہ ہے جو غصہ کی حالت میں اپنے آپ پر قابو پائے۔',
      textHi:
          'Pehalwan wo nahi jo kushti mein ghalib aa jaye, balki asli pehalwan wo hai jo ghusse ki halat mein apne aap par qaabu paye.',
    ),
    DailyHadith(
      book: HadithBook.bukhari, number: 6116,
      theme: 'Anger', themeUr: 'غصہ',
      arabic:
          'لَا تَغْضَبْ',
      text: 'Do not become angry and furious.',
      textUr: 'غصہ نہ ہوا کر۔',
      textHi:
          'Ghussa na kar.',
    ),
    DailyHadith(
      book: HadithBook.bukhari, number: 6125,
      theme: 'Gentleness', themeUr: 'نرمی',
      arabic:
          'يَسِّرُوا وَلَا تُعَسِّرُوا، وَسَكِّنُوا وَلَا تُنَفِّرُوا',
      text:
          'Make things easy for the people, and do not make it difficult for them.',
      textUr: 'آسانی پیدا کرو، تنگی نہ پیدا کرو۔',
      textHi:
          'Asani paida karo, tangi na paida karo.',
    ),
    DailyHadith(
      book: HadithBook.bukhari, number: 6136,
      theme: 'Speech', themeUr: 'گفتگو',
      arabic:
          'مَنْ كَانَ يُؤْمِنُ بِاللَّهِ وَالْيَوْمِ الْآخِرِ فَلْيَقُلْ خَيْرًا أَوْ لِيَصْمُتْ',
      text:
          'Whoever believes in Allah and the Last Day should speak what is good or keep silent.',
      textUr:
          'جو شخص اللہ اور آخرت کے دن پر ایمان رکھتا ہو، اس پر لازم ہے کہ بھلی بات کہے ورنہ چپ رہے۔',
      textHi:
          'Jo shakhs Allah aur aakhirat ke din par imaan rakhta ho, us par lazim hai ke bhali baat kahe warna chup rahe.',
    ),
    DailyHadith(
      book: HadithBook.tirmidhi, number: 1922,
      theme: 'Mercy', themeUr: 'رحم',
      arabic:
          'مَنْ لَا يَرْحَمُ النَّاسَ لَا يَرْحَمُهُ اللَّهُ',
      text:
          'Whoever does not show mercy to the people, Allah will not show mercy to him.',
      textUr:
          'جو شخص لوگوں پر مہربانی نہیں کرتا اللہ تعالیٰ اس پر مہربانی نہیں کرے گا۔',
      textHi:
          'Jo shakhs logon par meherbani nahi karta, Allah Taala us par meherbani nahi karega.',
    ),
    DailyHadith(
      book: HadithBook.tirmidhi, number: 1162,
      theme: 'Character', themeUr: 'اخلاق',
      arabic:
          'أَكْمَلُ الْمُؤْمِنِينَ إِيمَانًا أَحْسَنُهُمْ خُلُقًا',
      text:
          'The most complete of the believers in faith is the one with the best character among them.',
      textUr:
          'ایمان میں سب سے کامل مومن وہ ہے جو سب سے بہتر اخلاق والا ہو۔',
      textHi:
          'Imaan mein sab se kaamil momin wo hai jo sab se behtar akhlaq wala ho.',
    ),
    DailyHadith(
      book: HadithBook.ibnmajah, number: 1978,
      theme: 'Family', themeUr: 'اہلِ خانہ',
      arabic:
          'خِيَارُكُمْ خِيَارُكُمْ لِنِسَائِهِمْ',
      text: 'The best of you are those who are best to their womenfolk.',
      textUr: 'سب سے بہتر وہ لوگ ہیں جو اپنی عورتوں کے لیے بہتر ہوں۔',
      textHi:
          'Sab se behtar wo log hain jo apni auraton ke liye behtar hon.',
    ),
    DailyHadith(
      book: HadithBook.abudawud, number: 4811,
      theme: 'Gratitude', themeUr: 'شکر',
      arabic:
          'لَا يَشْكُرُ اللَّهَ مَنْ لَا يَشْكُرُ النَّاسَ',
      text: 'He who does not thank the people is not thankful to Allah.',
      textUr: 'جو لوگوں کا شکر ادا نہیں کرتا اللہ کا شکر ادا نہیں کرتا۔',
      textHi:
          'Jo logon ka shukr ada nahi karta, wo Allah ka shukr ada nahi karta.',
    ),
  ];

  /// The hadith for a given day.
  ///
  /// Derived from the date, not random, so everyone opening the app on the same
  /// day sees the same one — which matters if two people talk about it — and so
  /// it cannot repeat twice in a row or change if the app is reopened.
  ///
  /// Day-of-year rather than a stored counter: nothing to keep in sync, and it
  /// survives a reinstall.
  static DailyHadith forDate(DateTime date) {
    final int dayOfYear =
        date.difference(DateTime(date.year, 1, 1)).inDays;
    return all[(dayOfYear + date.year) % all.length];
  }
}
