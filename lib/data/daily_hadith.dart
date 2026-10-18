import '../models/hadith.dart';
import '../services/hadith_link.dart';
import '../services/hadith_repository.dart';
import 'daily_hadith_selection.dart';
import 'daily_hadith_roman.dart';

/// Daily-life selections with offline text and links to original entries.
/// Existing excerpts matching the source criteria are retained. New entries contain the FULL bundled
/// text in Arabic/English/Urdu, without automatic quotation extraction.
/// Every supplied grader labels each new entry exactly Sahih; this is a check
/// against the bundled dataset, not an independent scholarly review.
/// Missing reviewed Roman transliterations are not generated automatically.
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
    this.romanIsAutomatic = false,
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

  /// True for generated Roman spelling, clearly labelled in the daily card.
  final bool romanIsAutomatic;

  /// The saying in Arabic, verbatim from ara_*.json.
  ///
  /// A daily hadith card with no Arabic on it was the wrong shape for this app —
  /// every other screen leads with the Arabic and puts the translation beneath.
  final String arabic;

  /// A word for what it is about, shown above the text.
  final String theme;
  final String themeUr;

  HadithRef get ref => HadithRef(book: book, number: number);

  /// Verbatim preview, not an AI-written summary. Where the source explicitly
  /// marks a quotation, start there rather than displaying only the isnad.
  String get previewArabic {
    final quote = arabic.indexOf('"');
    return quote >= 0 ? arabic.substring(quote + 1).trim() : arabic;
  }

  String get previewEnglish {
    final colon = text.indexOf(':');
    return colon >= 0 ? text.substring(colon + 1).trim() : text;
  }


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
      book: HadithBook.abudawud, number: 4782,
      theme: "Managing anger", themeUr: "غصے پر قابو",
      text: "Narrated AbuDharr: The Messenger of Allah (ﷺ) said to us: When one of you becomes angry while standing, he should sit down. If the anger leaves him, well and good; otherwise he should lie down",
      textUr: "ابوذر رضی اللہ عنہ کہتے ہیں کہ رسول اللہ صلی اللہ علیہ وسلم نے ہم سے فرمایا: جب تم میں سے کسی کو غصہ آئے اور وہ کھڑا ہو تو چاہیئے کہ بیٹھ جائے، اب اگر اس کا غصہ رفع ہو جائے ( تو بہتر ہے ) ورنہ پھر لیٹ جائے ۔",
      textHi: '', // No reviewed Roman transliteration for this entry.
      arabic: "حَدَّثَنَا أَحْمَدُ بْنُ حَنْبَلٍ، حَدَّثَنَا أَبُو مُعَاوِيَةَ، حَدَّثَنَا دَاوُدُ بْنُ أَبِي هِنْدٍ، عَنْ أَبِي حَرْبِ بْنِ الأَسْوَدِ، عَنْ أَبِي ذَرٍّ، قَالَ إِنَّ رَسُولَ اللَّهِ صلى الله عليه وسلم قَالَ لَنَا ‏ \"‏ إِذَا غَضِبَ أَحَدُكُمْ وَهُوَ قَائِمٌ فَلْيَجْلِسْ فَإِنْ ذَهَبَ عَنْهُ الْغَضَبُ وَإِلاَّ فَلْيَضْطَجِعْ ‏\"‏ ‏.‏",
    ),
    DailyHadith(
      book: HadithBook.abudawud, number: 4786,
      theme: "Kindness at home", themeUr: "گھر میں نرمی",
      text: "A’isha said:the Messenger of Allah (saws ) never struck a servant or a woman",
      textUr: "ام المؤمنین عائشہ رضی اللہ عنہا کہتی ہیں کہ رسول اللہ صلی اللہ علیہ وسلم نے نہ کبھی کسی خادم کو مارا، اور نہ کبھی کسی عورت کو۔",
      textHi: '', // No reviewed Roman transliteration for this entry.
      arabic: "حَدَّثَنَا مُسَدَّدٌ، حَدَّثَنَا يَزِيدُ بْنُ زُرَيْعٍ، حَدَّثَنَا مَعْمَرٌ، عَنِ الزُّهْرِيِّ، عَنْ عُرْوَةَ، عَنْ عَائِشَةَ، رضى الله عنها، قَالَتْ مَا ضَرَبَ رَسُولُ اللَّهِ صلى الله عليه وسلم خَادِمًا وَلاَ امْرَأَةً قَطُّ ‏.‏",
    ),
    DailyHadith(
      book: HadithBook.abudawud, number: 4807,
      theme: "Gentleness", themeUr: "نرمی",
      text: "Abd Allah b. Mughaffal reported the Messenger of Allah (ﷺ) as saying :Allah is gentle, likes gentleness, and gives for gentleness what he does not give for harshness",
      textUr: "عبداللہ بن مغفل رضی اللہ عنہ کہتے ہیں کہ رسول اللہ صلی اللہ علیہ وسلم نے فرمایا: اللہ رفیق ہے، رفق اور نرمی پسند کرتا ہے، اور اس پر وہ دیتا ہے، جو سختی پر نہیں دیتا ۱؎ ۔",
      textHi: '', // No reviewed Roman transliteration for this entry.
      arabic: "حَدَّثَنَا مُوسَى بْنُ إِسْمَاعِيلَ، حَدَّثَنَا حَمَّادٌ، عَنْ يُونُسَ، وَحُمَيْدٍ، عَنِ الْحَسَنِ، عَنْ عَبْدِ اللَّهِ بْنِ مُغَفَّلٍ، أَنَّ رَسُولَ اللَّهِ صلى الله عليه وسلم قَالَ ‏ \"‏ إِنَّ اللَّهَ رَفِيقٌ يُحِبُّ الرِّفْقَ وَيُعْطِي عَلَيْهِ مَا لاَ يُعْطِي عَلَى الْعُنْفِ ‏\"‏ ‏.‏",
    ),
    DailyHadith(
      book: HadithBook.abudawud, number: 4895,
      theme: "Humility", themeUr: "عاجزی",
      text: "Narrated Iyad ibn Himar (al-Mujashi'i): The Prophet (ﷺ) said: Allah has revealed to me that you must be humble, so that no one oppresses another and boasts over another",
      textUr: "عیاض بن حمار رضی اللہ عنہ کہتے ہیں کہ رسول اللہ صلی اللہ علیہ وسلم نے فرمایا: اللہ نے مجھ کو وحی کی ہے کہ تم لوگ تواضع اختیار کرو یہاں تک کہ تم میں سے کوئی کسی پر زیادتی نہ کرے اور نہ کوئی کسی پر فخر کرے ۔",
      textHi: '', // No reviewed Roman transliteration for this entry.
      arabic: "حَدَّثَنَا أَحْمَدُ بْنُ حَفْصٍ، قَالَ حَدَّثَنِي أَبِي، حَدَّثَنِي إِبْرَاهِيمُ بْنُ طَهْمَانَ، عَنِ الْحَجَّاجِ، عَنْ قَتَادَةَ، عَنْ يَزِيدَ بْنِ عَبْدِ اللَّهِ، عَنْ عِيَاضِ بْنِ حِمَارٍ، أَنَّهُ قَالَ قَالَ رَسُولُ اللَّهِ صلى الله عليه وسلم ‏ \"‏ إِنَّ اللَّهَ أَوْحَى إِلَىَّ أَنْ تَوَاضَعُوا حَتَّى لاَ يَبْغِيَ أَحَدٌ عَلَى أَحَدٍ وَلاَ يَفْخَرَ أَحَدٌ عَلَى أَحَدٍ ‏\"‏ ‏.‏",
    ),
    DailyHadith(
      book: HadithBook.abudawud, number: 5198,
      theme: "Greeting others", themeUr: "سلام کرنا",
      text: "Abu Hurairah reported the Messenger of Allah (May peace be upon him) as saying :The young should salute the old, the one who is passing by should salute the one who is sitting, and a small company should salute a large one",
      textUr: "ابوہریرہ رضی اللہ عنہ کہتے ہیں کہ رسول اللہ صلی اللہ علیہ وسلم نے فرمایا: چھوٹا بڑے کو سلام کرے گا، چلنے والا بیٹھے ہوئے کو، اور تھوڑے لوگ زیادہ لوگوں کو ۔",
      textHi: '', // No reviewed Roman transliteration for this entry.
      arabic: "حَدَّثَنَا أَحْمَدُ بْنُ حَنْبَلٍ، حَدَّثَنَا عَبْدُ الرَّزَّاقِ، أَخْبَرَنَا مَعْمَرٌ، عَنْ هَمَّامِ بْنِ مُنَبِّهٍ، عَنْ أَبِي هُرَيْرَةَ، قَالَ قَالَ رَسُولُ اللَّهِ صلى الله عليه وسلم ‏ \"‏ يُسَلِّمُ الصَّغِيرُ عَلَى الْكَبِيرِ وَالْمَارُّ عَلَى الْقَاعِدِ وَالْقَلِيلُ عَلَى الْكَثِيرِ ‏\"‏ ‏.‏",
    ),
    DailyHadith(
      book: HadithBook.ibnmajah, number: 3682,
      theme: "Helping others", themeUr: "دوسروں کی مدد",
      text: "It was narrated from Abu Hurayrah that the Prophet(ﷺ) said:\"There was a branch of a tree that annoyed the people. A man removed it, so he was admitted to Paradise",
      textUr: "ابوہریرہ رضی اللہ عنہ کہتے ہیں کہ نبی اکرم صلی اللہ علیہ وسلم نے فرمایا: راستے میں ایک درخت کی شاخ ( ٹہنی ) پڑی ہوئی تھی جس سے لوگوں کو تکلیف ہوتی تھی، ایک شخص نے اسے ہٹا دیا ( تاکہ مسافروں اور گزرنے والوں کو تکلیف نہ ہو ) اسی وجہ سے وہ جنت میں داخل کر دیا گیا ۔",
      textHi: '', // No reviewed Roman transliteration for this entry.
      arabic: "حَدَّثَنَا أَبُو بَكْرِ بْنُ أَبِي شَيْبَةَ، حَدَّثَنَا عَبْدُ اللَّهِ بْنُ نُمَيْرٍ، عَنِ الأَعْمَشِ، عَنْ أَبِي صَالِحٍ، عَنْ أَبِي هُرَيْرَةَ، عَنِ النَّبِيِّ ـ صلى الله عليه وسلم ـ قَالَ ‏ \"‏ كَانَ عَلَى الطَّرِيقِ غُصْنُ شَجَرَةٍ يُؤْذِي النَّاسَ فَأَمَاطَهَا رَجُلٌ فَأُدْخِلَ الْجَنَّةَ ‏\"‏ ‏.‏",
    ),
    DailyHadith(
      book: HadithBook.ibnmajah, number: 3686,
      theme: "Kindness to animals", themeUr: "جانوروں پر رحم",
      text: "It was narrated that Suraqah bin Ju'shum said:\"I asked the Messenger of Allah(ﷺ) about a lost camel that comes to my cisterns that I have prepared for my own camels - will I be rewarded if I give it some water to drink? He said: Yes, in every living being there is reward",
      textUr: "سراقہ بن جعشم رضی اللہ عنہ کہتے ہیں کہ میں نے رسول اللہ صلی اللہ علیہ وسلم سے گمشدہ اونٹوں کے متعلق پوچھا کہ وہ میرے حوض پر آتے ہیں جس کو میں نے اپنے اونٹوں کے لیے تیار کیا ہے، اگر میں ان اونٹوں کو پانی پینے دوں تو کیا اس کا بھی اجر مجھے ملے گا؟ آپ صلی اللہ علیہ وسلم نے فرمایا: ہاں! ہر کلیجہ والے جانور کے جس کو پیاس لگتی ہے، پانی پلانے میں ثواب ہے ۔",
      textHi: '', // No reviewed Roman transliteration for this entry.
      arabic: "حَدَّثَنَا أَبُو بَكْرِ بْنُ أَبِي شَيْبَةَ، حَدَّثَنَا عَبْدُ اللَّهِ بْنُ نُمَيْرٍ، حَدَّثَنَا مُحَمَّدُ بْنُ إِسْحَاقَ، عَنِ الزُّهْرِيِّ، عَنْ عَبْدِ الرَّحْمَنِ بْنِ جُعْشُمٍ، عَنْ أَبِيهِ، عَنْ عَمِّهِ، سُرَاقَةَ بْنِ جُعْشُمٍ قَالَ سَأَلْتُ رَسُولَ اللَّهِ ـ صلى الله عليه وسلم ـ عَنْ ضَالَّةِ الإِبِلِ تَغْشَى حِيَاضِي قَدْ لُطْتُهَا لإِبِلِي فَهَلْ لِي مِنْ أَجْرٍ إِنْ سَقَيْتُهَا فَقَالَ ‏ \"‏ نَعَمْ فِي كُلِّ ذَاتِ كَبِدٍ حَرَّى أَجْرٌ ‏\"‏ ‏.‏",
    ),
    DailyHadith(
      book: HadithBook.ibnmajah, number: 3700,
      theme: "Kindness to children", themeUr: "بچوں سے شفقت",
      text: "It was narrated that Anas said:\"The Messenger of Allah(ﷺ) came to us, and we were young boys, and he greeted us with (the greeting of) peace",
      textUr: "انس رضی اللہ عنہ کہتے ہیں کہ رسول اللہ صلی اللہ علیہ وسلم ہمارے پاس تشریف لائے، ( اس وقت ) ہم بچے تھے تو آپ نے ہمیں سلام کیا۔",
      textHi: '', // No reviewed Roman transliteration for this entry.
      arabic: "حَدَّثَنَا أَبُو بَكْرٍ، حَدَّثَنَا أَبُو خَالِدٍ الأَحْمَرُ، عَنْ حُمَيْدٍ، عَنْ أَنَسٍ، قَالَ أَتَانَا رَسُولُ اللَّهِ ـ صلى الله عليه وسلم ـ وَنَحْنُ صِبْيَانٌ فَسَلَّمَ عَلَيْنَا ‏.‏",
    ),
    DailyHadith(
      book: HadithBook.ibnmajah, number: 3792,
      theme: "Remembering Allah", themeUr: "اللہ کا ذکر",
      text: "It was narrated from Abu Hurairah that the Prophet(ﷺ) said:\"Allah says: 'I am with My slave when he remembers Me and his lips move saying My Name",
      textUr: "ابوہریرہ رضی اللہ عنہ کہتے ہیں کہ نبی اکرم صلی اللہ علیہ وسلم نے فرمایا: اللہ تعالیٰ ارشاد فرماتا ہے کہ میں اپنے بندے کے ساتھ ہوتا ہوں، جب وہ میرا ذکر کرتا ہے، اور اس کے ہونٹ میرے ذکر کی وجہ سے حرکت میں ہوتے ہیں ۔",
      textHi: '', // No reviewed Roman transliteration for this entry.
      arabic: "حَدَّثَنَا أَبُو بَكْرٍ، حَدَّثَنَا مُحَمَّدُ بْنُ مُصْعَبٍ، عَنِ الأَوْزَاعِيِّ، عَنْ إِسْمَاعِيلَ بْنِ عُبَيْدِ اللَّهِ، عَنْ أُمِّ الدَّرْدَاءِ، عَنْ أَبِي هُرَيْرَةَ، عَنِ النَّبِيِّ ـ صلى الله عليه وسلم ـ قَالَ ‏ \"‏ إِنَّ اللَّهَ عَزَّ وَجَلَّ يَقُولُ أَنَا مَعَ عَبْدِي إِذَا هُوَ ذَكَرَنِي وَتَحَرَّكَتْ بِي شَفَتَاهُ ‏\"‏ ‏.‏",
    ),
    DailyHadith(
      book: HadithBook.ibnmajah, number: 3812,
      theme: "Seeking forgiveness", themeUr: "استغفار",
      text: "It was narrated from Abu Hurairah that :the Messenger of Allah (ﷺ) said: \"Whoever says: Subhan Allahi wa bi hamdihi (Glory and praise is to Allah) one hundred times, his sins will be forgiven even if they were like the foam of the sea",
      textUr: "ابوہریرہ رضی اللہ عنہ کہتے ہیں کہ رسول اللہ صلی اللہ علیہ وسلم نے فرمایا: جو شخص سو بار «سبحان الله وبحمده» کہے تو اس کے گناہ معاف کر دئیے جائیں گے، اگرچہ سمندر کے جھاگ کے برابر ہی کیوں نہ ہوں ۔",
      textHi: '', // No reviewed Roman transliteration for this entry.
      arabic: "حَدَّثَنَا نَصْرُ بْنُ عَبْدِ الرَّحْمَنِ الْوَشَّاءُ، حَدَّثَنَا عَبْدُ الرَّحْمَنِ الْمُحَارِبِيُّ، عَنْ مَالِكِ بْنِ أَنَسٍ، عَنْ سُمَىٍّ، عَنْ أَبِي صَالِحٍ، عَنْ أَبِي هُرَيْرَةَ، قَالَ قَالَ رَسُولُ اللَّهِ ـ صلى الله عليه وسلم ـ ‏ \"‏ مَنْ قَالَ سُبْحَانَ اللَّهِ وَبِحَمْدِهِ مِائَةَ مَرَّةٍ غُفِرَتْ لَهُ ذُنُوبُهُ وَلَوْ كَانَتْ مِثْلَ زَبَدِ الْبَحْرِ ‏\"‏ ‏.‏",
    ),
    DailyHadith(
      book: HadithBook.ibnmajah, number: 3825,
      theme: "Trust in Allah", themeUr: "اللہ پر بھروسا",
      text: "It was narrated that Abu Dharr said:\"The Messenger of Allah (saas) said to me: \"Shall I not tell you of a treasure which is one of the treasures of Paradise?' I said: 'Yes, O Messenger of Allah.' He said: 'La hawla wa la quwwata illa billah (There is no power and no strength except with Allah).'\" (sahih)",
      textUr: "ابوذر رضی اللہ عنہ کہتے ہیں کہ رسول اللہ صلی اللہ علیہ وسلم نے مجھ سے فرمایا: کیا میں تمہیں وہ کلمہ نہ بتاؤں جو جنت کے خزانوں میں سے ایک خزانہ ہے ؟ میں نے عرض کیا: کیوں نہیں، ضرور بتائیے، اے اللہ کے رسول! آپ صلی اللہ علیہ وسلم نے فرمایا: وہ کلمہ «لا حول ولا قوة إلا بالله» ہے ۔",
      textHi: '', // No reviewed Roman transliteration for this entry.
      arabic: "حَدَّثَنَا عَلِيُّ بْنُ مُحَمَّدٍ، حَدَّثَنَا وَكِيعٌ، عَنِ الأَعْمَشِ، عَنْ مُجَاهِدٍ، عَنْ عَبْدِ الرَّحْمَنِ بْنِ أَبِي لَيْلَى، عَنْ أَبِي ذَرٍّ، قَالَ قَالَ لِي رَسُولُ اللَّهِ ـ صلى الله عليه وسلم ـ ‏\"‏ أَلاَ أَدُلُّكَ عَلَى كَنْزٍ مِنْ كُنُوزِ الْجَنَّةِ ‏\"‏ ‏.‏ قُلْتُ بَلَى يَا رَسُولَ اللَّهِ ‏.‏ قَالَ ‏\"‏ لاَ حَوْلَ وَلاَ قُوَّةَ إِلاَّ بِاللَّهِ ‏\"‏ ‏.‏",
    ),
    DailyHadith(
      book: HadithBook.ibnmajah, number: 3842,
      theme: "Seeking protection", themeUr: "پناہ کی دعا",
      text: "It was narrated from Abu Hurairah that :the Messenger of Allah (saas) said: \"Seek refuge with Allah from poverty, insufficiency and humiliation, and from wronging (others) and being wronged",
      textUr: "ابوہریرہ رضی اللہ عنہ کہتے ہیں کہ رسول اللہ صلی اللہ علیہ وسلم نے فرمایا: تم اللہ سے فقیری، مال کی کمی، ذلت، ظلم کرنے اور ظلم کئے جانے سے پناہ مانگو ۔",
      textHi: '', // No reviewed Roman transliteration for this entry.
      arabic: "حَدَّثَنَا أَبُو بَكْرٍ، حَدَّثَنَا مُحَمَّدُ بْنُ مُصْعَبٍ، عَنِ الأَوْزَاعِيِّ، عَنْ إِسْحَاقَ بْنِ عَبْدِ اللَّهِ، عَنْ جَعْفَرِ بْنِ عِيَاضٍ، عَنْ أَبِي هُرَيْرَةَ، قَالَ قَالَ رَسُولُ اللَّهِ ـ صلى الله عليه وسلم ـ ‏ \"‏ تَعَوَّذُوا بِاللَّهِ مِنَ الْفَقْرِ وَالْقِلَّةِ وَالذِّلَّةِ وَأَنْ تَظْلِمَ أَوْ تُظْلَمَ ‏\"‏ ‏.‏",
    ),
    DailyHadith(
      book: HadithBook.ibnmajah, number: 3983,
      theme: "Learning from experience", themeUr: "تجربے سے سبق",
      text: "It was narrated from Ibn ‘Umar that the Messenger of Allah (ﷺ) said:‘The believer should not be stung from the same hole twice.’”",
      textUr: "عبداللہ بن عمر رضی اللہ عنہما کہتے ہیں کہ رسول اللہ صلی اللہ علیہ وسلم نے فرمایا: مومن ایک سوراخ سے دو بار نہیں ڈسا جاتا ۱؎۔",
      textHi: '', // No reviewed Roman transliteration for this entry.
      arabic: "حَدَّثَنَا عُثْمَانُ بْنُ أَبِي شَيْبَةَ، قَالَ حَدَّثَنَا أَبُو أَحْمَدَ الزُّبَيْرِيُّ، حَدَّثَنَا زَمْعَةُ بْنُ صَالِحٍ، عَنِ الزُّهْرِيِّ، عَنْ سَالِمٍ، عَنِ ابْنِ عُمَرَ، قَالَ قَالَ رَسُولُ اللَّهِ ـ صلى الله عليه وسلم ـ ‏ \"‏ لاَ يُلْدَغُ الْمُؤْمِنُ مِنْ جُحْرٍ مَرَّتَيْنِ ‏\"‏ ‏.‏",
    ),
    DailyHadith(
      book: HadithBook.ibnmajah, number: 4032,
      theme: "Patience with people", themeUr: "لوگوں کے ساتھ صبر",
      text: "It was narrated from Ibn ‘Umar that the Messenger of Allah (ﷺ) said:“The believer who mixes with people and bears their annoyance with patience will have a greater reward than the believer who does not mix with people and does not put up with their annoyance.”",
      textUr: "عبداللہ بن عمر رضی اللہ عنہما کہتے ہیں کہ رسول اللہ صلی اللہ علیہ وسلم نے فرمایا: وہ مومن جو لوگوں سے مل جل کر رہتا ہے، اور ان کی ایذاء پر صبر کرتا ہے، تو اس کا ثواب اس مومن سے زیادہ ہے جو لوگوں سے الگ تھلگ رہتا ہے، اور ان کی ایذاء رسانی پر صبر نہیں کرتا ہے ۱؎۔",
      textHi: '', // No reviewed Roman transliteration for this entry.
      arabic: "حَدَّثَنَا عَلِيُّ بْنُ مَيْمُونٍ الرَّقِّيُّ، حَدَّثَنَا عَبْدُ الْوَاحِدِ بْنُ صَالِحٍ، حَدَّثَنَا إِسْحَاقُ بْنُ يُوسُفَ، عَنِ الأَعْمَشِ، عَنْ يَحْيَى بْنِ وَثَّابٍ، عَنِ ابْنِ عُمَرَ، قَالَ قَالَ رَسُولُ اللَّهِ ـ صلى الله عليه وسلم ـ ‏ \"‏ الْمُؤْمِنُ الَّذِي يُخَالِطُ النَّاسَ وَيَصْبِرُ عَلَى أَذَاهُمْ أَعْظَمُ أَجْرًا مِنَ الْمُؤْمِنِ الَّذِي لاَ يُخَالِطُ النَّاسَ وَلاَ يَصْبِرُ عَلَى أَذَاهُمْ ‏\"‏ ‏.‏",
    ),
    DailyHadith(
      book: HadithBook.ibnmajah, number: 4177,
      theme: "Making time to help", themeUr: "مدد کے لیے وقت",
      text: "It was narrated that Anas bin Malik said:“If a female slave among the people of Al-Madinah were to take the hand of the Messenger of Allah (ﷺ), he would not take his hand away from hers until she had taken him wherever she wanted in Al-Madinah so that her needs may be met.”",
      textUr: "انس بن مالک رضی اللہ عنہ کہتے ہیں کہ اگر اہل مدینہ میں سے کوئی ایک باندی رسول اللہ صلی اللہ علیہ وسلم کا ہاتھ پکڑتی تو آپ صلی اللہ علیہ وسلم اس سے اپنا ہاتھ نہ چھڑاتے، یہاں تک کہ وہ آپ کو اپنی ضرورت کے لیے جہاں چاہتی لے جاتی ۱؎۔",
      textHi: '', // No reviewed Roman transliteration for this entry.
      arabic: "حَدَّثَنَا نَصْرُ بْنُ عَلِيٍّ، حَدَّثَنَا عَبْدُ الصَّمَدِ، وَسَلْمُ بْنُ قُتَيْبَةَ، قَالاَ حَدَّثَنَا شُعْبَةُ، عَنْ عَلِيِّ بْنِ زَيْدٍ، عَنْ أَنَسِ بْنِ مَالِكٍ، قَالَ إِنْ كَانَتِ الأَمَةُ مِنْ أَهْلِ الْمَدِينَةِ لَتَأْخُذُ بِيَدِ رَسُولِ اللَّهِ ـ صلى الله عليه وسلم ـ فَمَا يَنْزِعُ يَدَهُ مِنْ يَدِهَا حَتَّى تَذْهَبَ بِهِ حَيْثُ شَاءَتْ مِنَ الْمَدِينَةِ فِي حَاجَتِهَا ‏.‏",
    ),
    DailyHadith(
      book: HadithBook.ibnmajah, number: 4184,
      theme: "Modesty and speech", themeUr: "حیا اور گفتگو",
      text: "It was narrated from Abu Bakrah that the Messenger of Allah (ﷺ) said:“Modesty is part of faith, and faith will be in Paradise. Obscenity in speech is part of harshness and harshness will be in Hell.’”",
      textUr: "ابوبکرہ رضی اللہ عنہ کہتے ہیں کہ رسول اللہ صلی اللہ علیہ وسلم نے فرمایا: حیاء ایمان سے ہے، اور ایمان کا بدلہ جنت ہے، اور فحش گوئی «جفا» ( ظلم و زیادتی ) ہے اور «جفا» ( ظلم زیادتی ) کا بدلہ جہنم ہے ۔",
      textHi: '', // No reviewed Roman transliteration for this entry.
      arabic: "حَدَّثَنَا إِسْمَاعِيلُ بْنُ مُوسَى، حَدَّثَنَا هُشَيْمٌ، عَنْ مَنْصُورٍ، عَنِ الْحَسَنِ، عَنْ أَبِي بَكْرَةَ، قَالَ قَالَ رَسُولُ اللَّهِ ـ صلى الله عليه وسلم ـ ‏ \"‏ الْحَيَاءُ مِنَ الإِيمَانِ وَالإِيمَانُ فِي الْجَنَّةِ وَالْبَذَاءُ مِنَ الْجَفَاءِ وَالْجَفَاءُ فِي النَّارِ ‏\"‏ ‏.‏",
    ),
    DailyHadith(
      book: HadithBook.ibnmajah, number: 4213,
      theme: "Respect for others", themeUr: "دوسروں کا احترام",
      text: "It was narrated from Abu Hurairah that the Messenger of Allah (ﷺ) said:“It is sufficient evil for a man to look down on his Muslim brother.”",
      textUr: "ابوہریرہ رضی اللہ عنہ کہتے ہیں کہ رسول اللہ صلی اللہ علیہ وسلم نے فرمایا: شر سے آدمی کے لیے یہی کافی ہے کہ وہ اپنے مسلم بھائی کی تحقیر کرے ۔",
      textHi: '', // No reviewed Roman transliteration for this entry.
      arabic: "حَدَّثَنَا يَعْقُوبُ بْنُ حُمَيْدٍ الْمَدَنِيُّ، حَدَّثَنَا عَبْدُ الْعَزِيزِ بْنُ مُحَمَّدٍ، عَنْ دَاوُدَ بْنِ قَيْسٍ، عَنْ أَبِي سَعِيدٍ، - مَوْلَى بَنِي عَامِرٍ - عَنْ أَبِي هُرَيْرَةَ، أَنَّ رَسُولَ اللَّهِ ـ صلى الله عليه وسلم ـ قَالَ ‏ \"‏ حَسْبُ امْرِئٍ مِنَ الشَّرِّ أَنْ يَحْقِرَ أَخَاهُ الْمُسْلِمَ ‏\"‏ ‏.‏",
    ),
    DailyHadith(
      book: HadithBook.ibnmajah, number: 4237,
      theme: "Small consistent deeds", themeUr: "چھوٹے مگر مستقل نیک کام",
      text: "It was narrated that Umm Salamah said:“By the One Who took his (ﷺ) soul, he did not die until most of his prayers were offered sitting down. And the most beloved of deeds to him was a righteous deed which a person persists in doing, even if it is something small.”",
      textUr: "ام المؤمنین ام سلمہ رضی اللہ عنہا کہتی ہیں کہ قسم ہے اس ( اللہ ) کی جو آپ صلی اللہ علیہ وسلم کو ( دنیا سے ) لے گیا! آپ جب فوت ہوئے تو آپ زیادہ نماز ( تہجد ) بیٹھ کر ادا فرماتے تھے۔ اور آپ کے نزدیک زیادہ پسندیدہ عمل وہ نیک عمل تھا جس پر بندہ ہمیشگی کرے اگرچہ تھوڑا ہو۔",
      textHi: '', // No reviewed Roman transliteration for this entry.
      arabic: "حَدَّثَنَا أَبُو بَكْرِ بْنُ أَبِي شَيْبَةَ، حَدَّثَنَا أَبُو الأَحْوَصِ، عَنْ أَبِي إِسْحَاقَ، عَنْ أَبِي سَلَمَةَ، عَنْ أُمِّ سَلَمَةَ، قَالَتْ ‏:‏ وَالَّذِي ذَهَبَ بِنَفْسِهِ ـ صلى الله عليه وسلم ـ مَا مَاتَ حَتَّى كَانَ أَكْثَرُ صَلاَتِهِ وَهُوَ جَالِسٌ وَكَانَ أَحَبَّ الأَعْمَالِ إِلَيْهِ، الْعَمَلُ الصَّالِحُ الَّذِي يَدُومُ عَلَيْهِ الْعَبْدُ وَإِنْ كَانَ يَسِيرًا ‏.‏",
    ),
    DailyHadith(
      book: HadithBook.tirmidhi, number: 1913,
      theme: "Caring for daughters", themeUr: "بیٹیوں کی دیکھ بھال",
      text: "Aishah narrated that the:Messenger of Allah said:\"Whoever is tried with something from daughters, and he is patient with them, they will be a barrier from the Fire for him",
      textUr: "ام المؤمنین عائشہ رضی الله عنہا کہتی ہیں کہ رسول اللہ صلی اللہ علیہ وسلم نے فرمایا: ”جو شخص لڑکیوں کی پرورش سے دوچار ہو، پھر ان کی پرورش سے آنے والی مصیبتوں پر صبر کرے تو یہ سب لڑکیاں اس کے لیے جہنم سے آڑ بنیں گی“۔ امام ترمذی کہتے ہیں: یہ حدیث حسن ہے۔",
      textHi: '', // No reviewed Roman transliteration for this entry.
      arabic: "حَدَّثَنَا الْعَلاَءُ بْنُ مَسْلَمَةَ الْبَغْدَادِيُّ، حَدَّثَنَا عَبْدُ الْمَجِيدِ بْنُ عَبْدِ الْعَزِيزِ، عَنْ مَعْمَرٍ، عَنِ الزُّهْرِيِّ، عَنْ عُرْوَةَ، عَنْ عَائِشَةَ، قَالَتْ قَالَ رَسُولُ اللَّهِ صلى الله عليه وسلم ‏ \"‏ مَنِ ابْتُلِيَ بِشَيْءٍ مِنَ الْبَنَاتِ فَصَبَرَ عَلَيْهِنَّ كُنَّ لَهُ حِجَابًا مِنَ النَّارِ ‏\"‏ ‏.‏ قَالَ أَبُو عِيسَى هَذَا حَدِيثٌ حَسَنٌ ‏.‏",
    ),
    DailyHadith(
      book: HadithBook.tirmidhi, number: 1914,
      theme: "Raising daughters", themeUr: "بیٹیوں کی پرورش",
      text: "Abu Bakr bin 'Ubaidullah bin Anas bin Malik narrated [from Anas] that:the Messenger of Allah said: \"Whoever raises two girls then I and he will enter Paradise like these two.\" And he indicated with his two fingers",
      textUr: "انس بن مالک رضی الله عنہ کہتے ہیں کہ رسول اللہ صلی اللہ علیہ وسلم نے فرمایا: ”جس نے دو لڑکیوں کی کفالت کی تو میں اور وہ جنت میں اس طرح داخل ہوں گے“، اور آپ نے کیفیت بتانے کے لیے اپنی دونوں انگلیوں ( شہادت اور درمیانی ) سے اشارہ کیا۔ امام ترمذی کہتے ہیں: ۱- یہ حدیث اس سند سے حسن غریب ہے، ۲- محمد بن عبید نے محمد بن عبدالعزیز کے واسطہ سے اسی سند سے کئی حدیثیں روایت کی ہے اور سند بیان کرتے ہوئے کہا ہے: «عن أبي بكر بن عبيد الله بن أنس» حالانکہ صحیح یوں ہے «عن عبيد الله بن أبي بكر بن أنس» ۔",
      textHi: '', // No reviewed Roman transliteration for this entry.
      arabic: "حَدَّثَنَا مُحَمَّدُ بْنُ وَزِيرٍ الْوَاسِطِيُّ، حَدَّثَنَا مُحَمَّدُ بْنُ عُبَيْدٍ، هُوَ الطَّنَافِسِيُّ حَدَّثَنَا مُحَمَّدُ بْنُ عَبْدِ الْعَزِيزِ الرَّاسِبِيُّ، عَنْ أَبِي بَكْرِ بْنِ عُبَيْدِ اللَّهِ بْنِ أَنَسِ بْنِ مَالِكٍ، عَنْ أَنَسٍ، قَالَ قَالَ رَسُولُ اللَّهِ صلى الله عليه وسلم ‏ \"‏ مَنْ عَالَ جَارِيَتَيْنِ دَخَلْتُ أَنَا وَهُوَ الْجَنَّةَ كَهَاتَيْنِ ‏\"‏ ‏.‏ وَأَشَارَ بِأَصْبُعَيْهِ ‏.‏ قَالَ أَبُو عِيسَى هَذَا حَدِيثٌ حَسَنٌ غَرِيبٌ مِنْ هَذَا الْوَجْهِ ‏.‏ وَقَدْ رَوَى مُحَمَّدُ بْنُ عُبَيْدٍ عَنْ مُحَمَّدِ بْنِ عَبْدِ الْعَزِيزِ غَيْرَ حَدِيثٍ بِهَذَا الإِسْنَادِ وَقَالَ عَنْ أَبِي بَكْرِ بْنِ عُبَيْدِ اللَّهِ بْنِ أَنَسٍ وَالصَّحِيحُ هُوَ عُبَيْدُ اللَّهِ بْنُ أَبِي بَكْرِ بْنِ أَنَسٍ ‏.‏",
    ),
    DailyHadith(
      book: HadithBook.tirmidhi, number: 3591,
      theme: "Good character", themeUr: "اچھے اخلاق",
      text: "Ziyad bin `Ilaqah narrated from his uncle, that he said:“[The Prophet (ﷺ)] used to say: ‘O Allah, I seek refuge in You from evil character, evil actions, and evil desires (Allāhumma innī a`ūdhu bika min munkarātil-akhlāqi wal-a`māli wal-ahwā’).’”",
      textUr: "زیاد بن علاقہ کے چچا قطبہ رضی الله عنہ کہتے ہیں کہ نبی اکرم صلی اللہ علیہ وسلم یہ دعا پڑھتے تھے: «اللهم إني أعوذ بك من منكرات الأخلاق والأعمال والأهواء» ”اے اللہ! میں تجھ سے بری عادتوں، برے کاموں اور بری خواہشوں سے پناہ مانگتا ہوں“۔ امام ترمذی کہتے ہیں: ۱- یہ حدیث حسن غریب ہے ۲- اور زیاد بن علاقہ کے چچا کا نام قطبہ بن مالک ہے اور یہ نبی اکرم صلی اللہ علیہ وسلم کے صحابہ میں سے ہیں۔",
      textHi: '', // No reviewed Roman transliteration for this entry.
      arabic: "حَدَّثَنَا سُفْيَانُ بْنُ وَكِيعٍ، حَدَّثَنَا أَحْمَدُ بْنُ بَشِيرٍ، وَأَبُو أُسَامَةَ عَنْ مِسْعَرٍ، عَنْ زِيَادِ بْنِ عِلاَقَةَ، عَنْ عَمِّهِ، قَالَ كَانَ النَّبِيُّ صلى الله عليه وسلم يَقُولُ ‏ \"‏ اللَّهُمَّ إِنِّي أَعُوذُ بِكَ مِنْ مُنْكَرَاتِ الأَخْلاَقِ وَالأَعْمَالِ وَالأَهْوَاءِ ‏\"‏ ‏.‏ قَالَ هَذَا حَدِيثٌ حَسَنٌ غَرِيبٌ ‏.‏ وَعَمُّ زِيَادِ بْنِ عِلاَقَةَ هُوَ قُطْبَةُ بْنُ مَالِكٍ صَاحِبُ النَّبِيِّ صلى الله عليه وسلم ‏.‏",
    ),
  ];

  static int get selectionCount => dailyHadithSelection.length;

  /// The index is small; load only today's book, off the UI thread through the
  /// existing repository. Original numbers/text remain in the bundled books.
  static Future<DailyHadith> loadForDate(DateTime date) async {
    final day = DateTime.utc(date.year, date.month, date.day);
    final dayIndex = day.difference(DateTime.utc(2020, 1, 1)).inDays;
    final selected = dailyHadithSelection[dayIndex % dailyHadithSelection.length];
    // Preserve reviewed short excerpts / Roman text where already available.
    for (final entry in all) {
      if (entry.book == selected.$1 && entry.number == selected.$2) {
        final reviewed = entry.textHi.trim().isNotEmpty;
        return DailyHadith(
          book: entry.book, number: entry.number,
          text: entry.text, textUr: entry.textUr,
          textHi: reviewed ? entry.textHi : _romanFor(entry.book, entry.number),
          arabic: entry.arabic, theme: entry.theme, themeUr: entry.themeUr,
          romanIsAutomatic: !reviewed,
        );
      }
    }
    final collections = await Future.wait([
      HadithRepository.loadCollection(selected.$1, HadithLanguage.english),
      HadithRepository.loadCollection(selected.$1, HadithLanguage.urdu),
    ]);
    final english = collections[0].hadiths.firstWhere((h) => h.hadithNumber == selected.$2);
    final urdu = collections[1].hadiths.firstWhere((h) => h.hadithNumber == selected.$2);
    return DailyHadith(
      book: selected.$1, number: selected.$2,
      text: english.text, textUr: urdu.text,
      textHi: _romanFor(selected.$1, selected.$2),
      romanIsAutomatic: true,
      arabic: english.arabicText,
      theme: selected.$3, themeUr: selected.$4,
    );
  }

  static String _romanFor(HadithBook book, int number) {
    final text = dailyHadithRoman['${book.fileKey}|$number'];
    if (text == null || text.trim().isEmpty) {
      throw StateError('Missing Roman Urdu for ${book.fileKey}|$number');
    }
    return text;
  }

  /// Stable local calendar-day rotation, continuous across New Year and DST.
  /// Repeats after the entire available collection, not a random daily draw.
  static DailyHadith forDate(DateTime date) {
    final day = DateTime.utc(date.year, date.month, date.day);
    final dayIndex = day.difference(DateTime.utc(2020, 1, 1)).inDays;
    final entry = all[dayIndex % all.length];
    if (entry.textHi.trim().isNotEmpty) return entry;
    return DailyHadith(
      book: entry.book, number: entry.number,
      text: entry.text, textUr: entry.textUr,
      textHi: _romanFor(entry.book, entry.number),
      arabic: entry.arabic, theme: entry.theme, themeUr: entry.themeUr,
      romanIsAutomatic: true,
    );
  }
}
