import '../models/hadith.dart';
import '../services/hadith_link.dart';

/// One step of an act of worship, with the hadith cited for it.
class IbadatStep {
  const IbadatStep({
    required this.title,
    this.method,
    this.arabic,
    this.translation,
    this.translationUr,
    this.keyPoint,
    this.refs = const <HadithRef>[],
    this.practiceDiffers,
  });

  final String title;

  /// The tareeqa — what the worshipper actually does.
  final String? method;

  /// What is said at this step.
  final String? arabic;

  /// Meaning of [arabic] in English, and in Urdu.
  ///
  /// Urdu was missing entirely: an Urdu reader saw Arabic and then an English
  /// translation, which is the wrong way round for most of this app's users.
  /// Where translationUr is null the English is shown, so partial coverage
  /// degrades sensibly instead of leaving a blank.
  final String? translation;
  final String? translationUr;

  /// A short hadith worth quoting at this step in its own right.
  final String? keyPoint;

  final List<HadithRef> refs;

  /// Set where the schools of fiqh differ. The app states the agreed sequence
  /// and marks the contested details rather than presenting one school's
  /// position as the only one.
  final String? practiceDiffers;
}

class IbadatSection {
  const IbadatSection({required this.title, required this.steps});
  final String title;
  final List<IbadatStep> steps;
}

class IbadatGuide {
  const IbadatGuide({
    required this.pillar,
    required this.sections,
    this.reviewed = false,
  });

  final String pillar;
  final List<IbadatSection> sections;

  /// FALSE until an aalim has checked both the text and every citation. While
  /// false the screen says so at the top, because a worship guide that looks
  /// authoritative before it has been checked is worse than one that admits
  /// what it is.
  final bool reviewed;
}

/// NAMAZ — DRAFT, NOT VERIFIED.
///
/// Step text and translations supplied by the app owner. Hadith numbers were
/// found by SEARCHING THE APP'S OWN BUNDLED ARABIC TEXT for the exact phrase of
/// each dua, with diacritics normalised, then reading each result to confirm it
/// is about this step of the prayer and not merely a passage containing the same
/// words. Contextual matches were discarded — for example Muslim 1258 mentions
/// pointing with a finger but concerns a Friday sermon, and Abu Dawud 4857
/// carries the Sana wording but is about leaving a gathering.
///
/// Every number below was then checked to exist in the dataset, AND checked
/// against the grading data. NOTHING GRADED DAIF IS CITED.
///
/// That rule removed the citations usually quoted for the ruku and sujud
/// tasbihat — the Ibn Mas'ud "say it three times" narration at Abu Dawud 886,
/// Ibn Majah 890 and Tirmidhi 261, which every grader in this data calls Daif.
/// The Hudhaifah narration was used instead: Sahih Muslim 1814 carries both
/// tasbihat, with Abu Dawud 871/874 and Nasa'i 1046/1069 alongside, all graded
/// Sahih.
///
/// Hasan is kept. Sahih and Hasan are both acceptable for practice; only Daif
/// is excluded. Abu Dawud 722, Tirmidhi 243 and Ibn Majah 806 carry Hasan from
/// at least one grader and Sahih from others — if a stricter Sahih-only rule is
/// ever wanted, those three are the ones to revisit.
///
/// An accurate citation is still not a verified statement that this hadith is
/// the EVIDENCE for this step. That remains a scholarly judgement and is what
/// the aalim is reviewing.
class IbadatContent {
  IbadatContent._();

  static const IbadatGuide namaz = IbadatGuide(
    pillar: 'Namaz',
    reviewed: false,
    sections: <IbadatSection>[
      IbadatSection(
        title: 'Shuru',
        steps: <IbadatStep>[
          IbadatStep(
            title: 'Takbeer-e-Tahrima',
            method:
                'Namaz shuru karte waqt "Allahu Akbar" kahte hue haath kandhon ya kaanon tak uthaye jate hain.',
            arabic: 'اللّٰهُ أَكْبَرُ',
            translation: 'Allah is the Greatest.',
            practiceDiffers:
                'Haath kandhon tak ya kaanon tak uthana, aur baad ke takbeers par uthana — in tafseelat mein fiqhi mazahib ka ikhtilaf hai.',
            refs: <HadithRef>[
              HadithRef(
                  book: HadithBook.bukhari,
                  number: 735,
                  note: 'Ibn Umar: raised both hands to shoulder level'),
              HadithRef(
                  book: HadithBook.bukhari,
                  number: 738,
                  note: 'Opening the prayer with takbir and raising the hands'),
              HadithRef(
                  book: HadithBook.muslim,
                  number: 861,
                  note: 'Raising the hands on beginning the prayer'),
              HadithRef(
                  book: HadithBook.abudawud,
                  number: 722,
                  note: 'Hands raised opposite the shoulders'),
              HadithRef(
                  book: HadithBook.tirmidhi,
                  number: 255,
                  note: 'Ibn Umar on opening the salat'),
            ],
          ),
          IbadatStep(
            title: 'Dua-e-Sana',
            arabic:
                'سُبْحَانَكَ اللَّهُمَّ وَبِحَمْدِكَ وَتَبَارَكَ اسْمُكَ وَتَعَالَى جَدُّكَ وَلَا إِلَهَ غَيْرُكَ',
            translation:
                'Glory is to You, O Allah, and praise. Blessed is Your Name, exalted is Your Majesty, and none has the right to be worshipped except You.',
            refs: <HadithRef>[
              HadithRef(
                  book: HadithBook.abudawud,
                  number: 776,
                  note: 'Aisha: what he said on beginning the prayer'),
              HadithRef(
                  book: HadithBook.tirmidhi,
                  number: 243,
                  note: 'Aisha: on opening the salat'),
              HadithRef(
                  book: HadithBook.ibnmajah,
                  number: 806,
                  note: 'Aisha: on starting the salat'),
            ],
          ),
        ],
      ),
      IbadatSection(
        title: 'Qiyam',
        steps: <IbadatStep>[
          IbadatStep(
            title: 'Surah Al-Fatihah',
            // ALL SEVEN VERSES, verbatim from the app's own quran_en.json.
            // It was the first two lines with an ellipsis, which is no use to
            // anyone actually trying to recite.
            arabic:
                'بِسۡمِ ٱللَّهِ ٱلرَّحۡمَٰنِ ٱلرَّحِيمِ\n'
                'ٱلۡحَمۡدُ لِلَّهِ رَبِّ ٱلۡعَٰلَمِينَ\n'
                'ٱلرَّحۡمَٰنِ ٱلرَّحِيمِ\n'
                'مَٰلِكِ يَوۡمِ ٱلدِّينِ\n'
                'إِيَّاكَ نَعۡبُدُ وَإِيَّاكَ نَسۡتَعِينُ\n'
                'ٱهۡدِنَا ٱلصِّرَٰطَ ٱلۡمُسۡتَقِيمَ\n'
                'صِرَٰطَ ٱلَّذِينَ أَنۡعَمۡتَ عَلَيۡهِمۡ غَيۡرِ ٱلۡمَغۡضُوبِ عَلَيۡهِمۡ وَلَا ٱلضَّآلِّينَ',
            translation:
                'In the name of Allah, the Entirely Merciful, the Especially Merciful. '
                'All praise is due to Allah, Lord of the worlds. '
                'The Entirely Merciful, the Especially Merciful. '
                'Sovereign of the Day of Recompense. '
                'It is You we worship and You we ask for help. '
                'Guide us to the straight path \u2014 '
                'the path of those upon whom You have bestowed favour, not of those who have evoked Your anger, nor of those who are astray.',
            keyPoint:
                '"There is no prayer for the one who does not recite Surah Al-Fatihah."',
            refs: <HadithRef>[
              HadithRef(
                  book: HadithBook.bukhari,
                  number: 756,
                  note: 'Whoever does not recite Al-Fatiha in his prayer'),
              HadithRef(
                  book: HadithBook.muslim,
                  number: 874,
                  note: 'Ubada b. as-Samit: he who does not recite it'),
            ],
          ),
        ],
      ),
      IbadatSection(
        title: 'Fatihah Ke Baad',
        steps: <IbadatStep>[
          IbadatStep(
            title: 'Ameen',
            method:
                'Surah Fatihah khatam hone par "Ameen" kaha jata hai. Imam ke Ameen kehne par muqtadi bhi Ameen kahein.',
            arabic: 'آمِينَ',
            translation: 'Ameen \u2014 accept it.',
            refs: <HadithRef>[
              HadithRef(book: HadithBook.bukhari, number: 780,
                  note: 'Say Amin when the imam says it'),
            ],
          ),
          IbadatStep(
            title: 'Qira\u2018at',
            method:
                'Pehli do rakaton mein Surah Fatihah ke baad koi aur surah ya chand aayaat padhi jati hain. Aakhri rakaton mein sirf Surah Fatihah.',
            refs: <HadithRef>[
              HadithRef(book: HadithBook.bukhari, number: 776,
                  note: 'Al-Fatiha followed by another surah in the first two rak\u2018at'),
              HadithRef(book: HadithBook.bukhari, number: 762,
                  note: 'Abu Qatada: what was recited in Zuhr and Asr'),
            ],
          ),
        ],
      ),
      IbadatSection(
        title: 'Ruku aur Sajdah',
        steps: <IbadatStep>[
          IbadatStep(
            title: 'Ruku',
            arabic: 'سُبْحَانَ رَبِّيَ الْعَظِيمِ',
            translation: 'Glory be to my Lord, the Most Great.',
            // The Ibn Mas'ud narration (Abu Dawud 886, Ibn Majah 890,
            // Tirmidhi 261) says "three times" and is the one usually quoted
            // for this — but every grader in this app's own data calls it
            // DAIF. Replaced with the Hudhaifah narration, which is in Sahih
            // Muslim and carries both tasbihat.
            refs: <HadithRef>[
              HadithRef(
                  book: HadithBook.muslim,
                  number: 1814,
                  note: 'Hudhaifah: what he said in ruku and sujud'),
              HadithRef(
                  book: HadithBook.abudawud,
                  number: 871,
                  note: 'Hudhaifah: what he said when bowing'),
              HadithRef(
                  book: HadithBook.nasai,
                  number: 1046,
                  note: 'Hudhaifah: he bowed and said it'),
            ],
          ),
          IbadatStep(
            title: 'Ruku Se Uthna',
            arabic:
                'سَمِعَ اللَّهُ لِمَنْ حَمِدَهُ\nرَبَّنَا وَلَكَ الْحَمْدُ',
            translation:
                'Allah hears the one who praises Him. / Our Lord, to You belongs all praise.',
            refs: <HadithRef>[
              HadithRef(
                  book: HadithBook.bukhari,
                  number: 734,
                  note:
                      'Say "Rabbana wa lakal hamd" when the imam says "Sami\u2018a Allahu liman hamidah"'),
              HadithRef(
                  book: HadithBook.bukhari,
                  number: 690,
                  note: 'Al-Bara on what followed the tasmi\u2018'),
              HadithRef(
                  book: HadithBook.muslim,
                  number: 868,
                  note: 'Abu Huraira: the order of the prayer'),
            ],
          ),
          IbadatStep(
            title: 'Sajdah',
            arabic: 'سُبْحَانَ رَبِّيَ الْأَعْلَى',
            translation: 'Glory be to my Lord, the Most High.',
            // Same substitution as Ruku, for the same reason.
            refs: <HadithRef>[
              HadithRef(
                  book: HadithBook.muslim,
                  number: 1814,
                  note: 'Hudhaifah: what he said in sujud and ruku'),
              HadithRef(
                  book: HadithBook.abudawud,
                  number: 874,
                  note: 'Hudhaifah on his night prayer'),
              HadithRef(
                  book: HadithBook.nasai,
                  number: 1069,
                  note: 'Hudhaifah: his night prayer with the Prophet'),
            ],
          ),
          IbadatStep(
            title: 'Do Sajdon Ke Darmiyan',
            arabic: 'رَبِّ اغْفِرْ لِي',
            translation: 'My Lord, forgive me.',
            refs: <HadithRef>[
              HadithRef(
                  book: HadithBook.ibnmajah,
                  number: 897,
                  note: 'Hudhaifah: what he said between the two prostrations'),
              HadithRef(
                  book: HadithBook.abudawud,
                  number: 874,
                  note: 'Hudhaifah on his night prayer'),
            ],
          ),
        ],
      ),
      IbadatSection(
        title: 'Qa\u2018da aur Salam',
        steps: <IbadatStep>[
          IbadatStep(
            title: 'Tashahhud',
            // Complete, from the Arabic of Bukhari 831 — the hadith cited
            // below it. Two verbatim fragments joined: the hadith carries the
            // narrator's aside "for when you say that, it reaches every
            // righteous servant in the heavens and the earth" between them,
            // which is a comment on the tashahhud rather than part of it. Both
            // fragments were checked to appear verbatim in the source.
            arabic:
                'التَّحِيَّاتُ لِلَّهِ وَالصَّلَوَاتُ وَالطَّيِّبَاتُ، '
                'السَّلَامُ عَلَيْكَ أَيُّهَا النَّبِيُّ وَرَحْمَةُ اللَّهِ وَبَرَكَاتُهُ، '
                'السَّلَامُ عَلَيْنَا وَعَلَى عِبَادِ اللَّهِ الصَّالِحِينَ، '
                'أَشْهَدُ أَنْ لَا إِلَهَ إِلَّا اللَّهُ، وَأَشْهَدُ أَنَّ مُحَمَّدًا عَبْدُهُ وَرَسُولُهُ',
            translation:
                'All compliments, prayers and pure words are due to Allah. '
                'Peace be upon you, O Prophet, and the mercy of Allah and His blessings. '
                'Peace be upon us and upon the righteous servants of Allah. '
                'I bear witness that there is no deity except Allah, and I bear witness that Muhammad is His servant and His Messenger.',
            refs: <HadithRef>[
              HadithRef(
                  book: HadithBook.bukhari,
                  number: 831,
                  note: 'Ibn Mas\u2018ud: what was recited behind the Prophet'),
              HadithRef(
                  book: HadithBook.muslim,
                  number: 897,
                  note: 'Ibn Mas\u2018ud: the tashahhud'),
              HadithRef(
                  book: HadithBook.abudawud,
                  number: 968,
                  note: 'Ibn Mas\u2018ud: on sitting during the prayer'),
            ],
          ),
          IbadatStep(
            title: 'Shahadat Ki Ungli',
            method: 'Tashahhud mein shahadat ki ungli se ishara karna.',
            refs: <HadithRef>[
              HadithRef(
                  book: HadithBook.muslim,
                  number: 1307,
                  note:
                      'Ibn az-Zubair: he pointed with his finger when sitting in prayer'),
              HadithRef(
                  book: HadithBook.abudawud,
                  number: 988,
                  note: 'Ibn az-Zubair: on sitting at the tashahhud'),
              HadithRef(
                  book: HadithBook.nasai,
                  number: 1161,
                  note: 'Ibn az-Zubair: what he did with his hands'),
            ],
          ),
          IbadatStep(
            title: 'Durood Ibrahim',
            // Complete, verbatim from the Arabic of Bukhari 3370.
            arabic:
                'اللَّهُمَّ صَلِّ عَلَى مُحَمَّدٍ وَعَلَى آلِ مُحَمَّدٍ، '
                'كَمَا صَلَّيْتَ عَلَى إِبْرَاهِيمَ وَعَلَى آلِ إِبْرَاهِيمَ، إِنَّكَ حَمِيدٌ مَجِيدٌ. '
                'اللَّهُمَّ بَارِكْ عَلَى مُحَمَّدٍ وَعَلَى آلِ مُحَمَّدٍ، '
                'كَمَا بَارَكْتَ عَلَى إِبْرَاهِيمَ وَعَلَى آلِ إِبْرَاهِيمَ، إِنَّكَ حَمِيدٌ مَجِيدٌ',
            translation:
                'O Allah, send blessings upon Muhammad and upon the family of Muhammad, '
                'as You sent blessings upon Ibrahim and upon the family of Ibrahim; You are Praiseworthy, Glorious. '
                'O Allah, bless Muhammad and the family of Muhammad, '
                'as You blessed Ibrahim and the family of Ibrahim; You are Praiseworthy, Glorious.',
            refs: <HadithRef>[
              HadithRef(
                  book: HadithBook.bukhari,
                  number: 3370,
                  note: 'Ka\u2018b b. Ujrah: how to invoke blessings'),
              HadithRef(
                  book: HadithBook.bukhari,
                  number: 4797,
                  note: 'We know how to greet you, but how to invoke blessings'),
              HadithRef(
                  book: HadithBook.muslim,
                  number: 908,
                  note: 'Ka\u2018b b. Ujrah: the words taught'),
            ],
          ),
          IbadatStep(
            title: 'Dua-e-Masura',
            method:
                'Durood ke baad, salam se pehle yeh dua padhi jati hai. Nabi \u0637 ne Abu Bakr Siddiq \u0631\u0636\u064A \u0627\u0644\u0644\u0647 \u0639\u0646\u0647 ko yehi dua sikhayi thi jab unhon ne namaz mein padhne ke liye dua maangi.',
            // The Arabic of Bukhari 834, WITH ONE CORRECTION.
            //
            // The dataset's Arabic for this hadith contains two U+FFFD
            // replacement characters where the word وَ should be — a genuine
            // encoding fault in the source file, not a reading difference. The
            // English transliteration in the same record reads "Wala
            // yaghfiru", which identifies the missing word beyond doubt.
            //
            // The correction is CONFIRMED AGAINST A PARALLEL NARRATION: the
            // same dua appears at Bukhari 6326, where the source is not
            // corrupted, and the reconstructed text matches it verbatim. So
            // nothing here was written from memory — the damaged word was
            // recovered from your own data, from a different copy of the same
            // hadith.
            arabic:
                'اللَّهُمَّ إِنِّي ظَلَمْتُ نَفْسِي ظُلْمًا كَثِيرًا وَلَا يَغْفِرُ الذُّنُوبَ إِلَّا أَنْتَ، '
                'فَاغْفِرْ لِي مَغْفِرَةً مِنْ عِنْدِكَ، وَارْحَمْنِي إِنَّكَ أَنْتَ الْغَفُورُ الرَّحِيمُ',
            translation:
                'O Allah, I have wronged myself greatly, and none forgives sins except You. '
                'So grant me forgiveness from Yourself and have mercy on me \u2014 You are the Forgiving, the Merciful.',
            refs: <HadithRef>[
              HadithRef(book: HadithBook.bukhari, number: 834,
                  note: 'Abu Bakr: teach me a supplication for my prayer'),
              HadithRef(book: HadithBook.bukhari, number: 6326,
                  note: 'The same, in the Book of Invocations'),
              HadithRef(book: HadithBook.muslim, number: 6869,
                  note: 'Abu Bakr: a supplication to recite in prayer'),
            ],
          ),
          IbadatStep(
            title: 'Salam',
            arabic: 'السَّلَامُ عَلَيْكُمْ وَرَحْمَةُ اللَّهِ',
            translation: 'Peace and mercy of Allah be upon you.',
            refs: <HadithRef>[
              HadithRef(
                  book: HadithBook.muslim,
                  number: 970,
                  note: 'Jabir b. Samura: what was pronounced'),
              HadithRef(
                  book: HadithBook.abudawud,
                  number: 996,
                  note: 'Ibn Mas\u2018ud: salam to the right and the left'),
              HadithRef(
                  book: HadithBook.ibnmajah,
                  number: 914,
                  note: 'Salam to the right and the left'),
            ],
          ),
        ],
      ),
      IbadatSection(
        title: 'Azkar Baad Namaz',
        steps: <IbadatStep>[
          IbadatStep(
            title: 'Istighfar aur Allahumma Antas-Salam',
            method:
                'Salam ke baad teen martaba "Astaghfirullah" kaha jata hai, phir yeh dua.',
            arabic:
                'أَسْتَغْفِرُ اللَّهَ \u00D7\u0663\n'
                'اللَّهُمَّ أَنْتَ السَّلَامُ وَمِنْكَ السَّلَامُ، تَبَارَكْتَ ذَا الْجَلَالِ وَالْإِكْرَامِ',
            translation:
                'I seek Allah\u2019s forgiveness (three times). O Allah, You are Peace and from You is peace. Blessed are You, O Possessor of Majesty and Honour.',
            translationUr:
                'میں اللہ سے مغفرت مانگتا ہوں (تین بار)۔ اے اللہ! تو سلامتی والا ہے اور تجھی سے سلامتی ہے۔ تو بابرکت ہے، اے جلال اور عزت والے۔',
            refs: <HadithRef>[
              HadithRef(book: HadithBook.muslim, number: 1334,
                  note: 'Thawban: he sought forgiveness three times, then said this'),
              HadithRef(book: HadithBook.nasai, number: 1337,
                  note: 'Thawban: what he said on finishing the prayer'),
            ],
          ),
          IbadatStep(
            title: 'La Ilaha Illallah Wahdahu',
            method: 'Har farz namaz ke baad Nabi \u0637 yeh padha karte the.',
            arabic:
                'لَا إِلَهَ إِلَّا اللَّهُ وَحْدَهُ لَا شَرِيكَ لَهُ، لَهُ الْمُلْكُ وَلَهُ الْحَمْدُ، وَهُوَ عَلَى كُلِّ شَيْءٍ قَدِيرٌ. '
                'اللَّهُمَّ لَا مَانِعَ لِمَا أَعْطَيْتَ، وَلَا مُعْطِيَ لِمَا مَنَعْتَ، وَلَا يَنْفَعُ ذَا الْجَدِّ مِنْكَ الْجَدُّ',
            translation:
                'There is no deity but Allah alone, with no partner. His is the dominion and His is the praise, and He is able to do all things. '
                'O Allah, none can withhold what You give, and none can give what You withhold, and no wealth or majesty can benefit anyone against You.',
            translationUr:
                'اللہ کے سوا کوئی معبود نہیں، وہ اکیلا ہے، اس کا کوئی شریک نہیں۔ اسی کی بادشاہی ہے اور اسی کے لیے تمام تعریف ہے، اور وہ ہر چیز پر قادر ہے۔ '
                'اے اللہ! جو تو دے اسے کوئی روکنے والا نہیں، اور جو تو روک لے اسے کوئی دینے والا نہیں، اور کسی مالدار کو اس کی دولت تیرے مقابلے میں نفع نہیں دے سکتی۔',
            refs: <HadithRef>[
              HadithRef(book: HadithBook.bukhari, number: 844,
                  note: 'Al-Mughira: what he said after every obligatory prayer'),
              HadithRef(book: HadithBook.bukhari, number: 6330,
                  note: 'The same, at the end of every prayer'),
            ],
          ),
          IbadatStep(
            title: 'Tasbeeh-e-Fatimi',
            method:
                'Har namaz ke baad 33 martaba SubhanAllah, 33 martaba Alhamdulillah aur 33 martaba Allahu Akbar.',
            arabic:
                'سُبْحَانَ اللَّهِ \u00D7\u0663\u0663\n'
                'الْحَمْدُ لِلَّهِ \u00D7\u0663\u0663\n'
                'اللَّهُ أَكْبَرُ \u00D7\u0663\u0663',
            translation:
                'Glory be to Allah (33 times). All praise is due to Allah (33 times). Allah is the Greatest (33 times).',
            translationUr:
                'اللہ پاک ہے (33 بار)۔ تمام تعریف اللہ کے لیے ہے (33 بار)۔ اللہ سب سے بڑا ہے (33 بار)۔',
            refs: <HadithRef>[
              HadithRef(book: HadithBook.bukhari, number: 843,
                  note: 'The poor emigrants: tasbih after every prayer'),
              HadithRef(book: HadithBook.muslim, number: 1347,
                  note: 'Abu Huraira: thirty-three times each'),
            ],
          ),
          IbadatStep(
            title: 'Ayat-ul-Kursi',
            method: 'Surah Al-Baqarah, aayat 255.',
            // NO HADITH CITED HERE, AND THAT IS DELIBERATE.
            //
            // The verse itself is Qur'an and beyond question. What could not be
            // cited is the narration about reciting it AFTER EVERY PRAYER: every
            // version of it in this app's data — Tirmidhi 2878, Tirmidhi 2879
            // and Ibn Majah 3549 — is graded DAIF by every grader.
            //
            // The narration usually quoted for this practice is in Nasa'i's
            // Amal al-Yawm wal-Laylah, which is not one of the six books and is
            // not in this dataset. So under the no-Daif rule there is nothing
            // here to cite, and rather than cite something weak the step simply
            // does not claim a hadith.
            arabic:
                'ٱللَّهُ لَآ إِلَٰهَ إِلَّا هُوَ ٱلۡحَيُّ ٱلۡقَيُّومُۚ لَا تَأۡخُذُهُۥ سِنَةٞ وَلَا نَوۡمٞۚ '
                'لَّهُۥ مَا فِي ٱلسَّمَٰوَٰتِ وَمَا فِي ٱلۡأَرۡضِۗ مَن ذَا ٱلَّذِي يَشۡفَعُ عِندَهُۥٓ إِلَّا بِإِذۡنِهِۦۚ '
                'يَعۡلَمُ مَا بَيۡنَ أَيۡدِيهِمۡ وَمَا خَلۡفَهُمۡۖ وَلَا يُحِيطُونَ بِشَيۡءٖ مِّنۡ عِلۡمِهِۦٓ إِلَّا بِمَا شَآءَۚ '
                'وَسِعَ كُرۡسِيُّهُ ٱلسَّمَٰوَٰتِ وَٱلۡأَرۡضَۖ وَلَا يَـُٔودُهُۥ حِفۡظُهُمَاۚ وَهُوَ ٱلۡعَلِيُّ ٱلۡعَظِيمُ',
            translation:
                'Allah \u2014 there is no deity except Him, the Ever-Living, the Sustainer of all existence. Neither drowsiness overtakes Him nor sleep. To Him belongs whatever is in the heavens and whatever is on the earth. Who is it that can intercede with Him except by His permission? He knows what is before them and what will be after them, and they encompass not a thing of His knowledge except for what He wills. His Kursi extends over the heavens and the earth, and their preservation tires Him not. And He is the Most High, the Most Great.',
            translationUr:
                'اللہ، وہ زندہ جاوید ہستی، جو تمام کائنات کو سنبھالے ہوئے ہے، اُس کے سوا کوئی خدا نہیں ہے۔ وہ نہ سوتا ہے اور نہ اُسے اونگھ لگتی ہے۔ زمین اور آسمانوں میں جو کچھ ہے، اُسی کا ہے۔ کون ہے جو اُس کی جناب میں اُس کی اجازت کے بغیر سفارش کر سکے؟ جو کچھ بندوں کے سامنے ہے اسے بھی وہ جانتا ہے اور جو کچھ اُن سے اوجھل ہے، اس سے بھی وہ واقف ہے۔ اُس کی حکومت آسمانوں اور زمین پر چھائی ہوئی ہے اور اُن کی نگہبانی اس کے لیے کوئی تھکا دینے والا کام نہیں ہے۔ بس وہی ایک بزرگ و برتر ذات ہے۔',
          ),
          IbadatStep(
            title: 'Mu\u2018awwidhat',
            method:
                'Surah Al-Ikhlas, Al-Falaq aur An-Nas. Nabi \u0637 ne har namaz ke baad inhein padhne ka hukm diya.',
            refs: <HadithRef>[
              HadithRef(book: HadithBook.abudawud, number: 1523,
                  note: 'Uqbah b. Amir: commanded to recite them after every prayer'),
              HadithRef(book: HadithBook.nasai, number: 1336,
                  note: 'Uqbah b. Amr: recite the Mu\u2018awwidhat after every prayer'),
            ],
          ),
        ],
      ),
    ],
  );

  // ===========================================================================
  // SHAHADAH
  // ===========================================================================
  static const IbadatGuide shahadah = IbadatGuide(
    pillar: 'Shahadah',
    reviewed: false,
    sections: <IbadatSection>[
      IbadatSection(
        title: 'Shahadah Kya Hai?',
        steps: <IbadatStep>[
          IbadatStep(
            title: 'Kalima Tayyiba',
            arabic: 'لَا إِلٰهَ إِلَّا اللّٰهُ مُحَمَّدٌ رَسُولُ اللّٰهِ',
            translation:
                'There is no deity worthy of worship except Allah, and Muhammad \u0637 is the Messenger of Allah.',
            refs: <HadithRef>[
              HadithRef(book: HadithBook.bukhari, number: 8,
                  note: 'Ibn Umar: Islam is built on five'),
              HadithRef(book: HadithBook.muslim, number: 111,
                  note: 'Ibn Umar: the five on which Islam is based'),
            ],
          ),
        ],
      ),
      IbadatSection(
        title: 'Shahadah Ki Ahmiyat',
        steps: <IbadatStep>[
          IbadatStep(
            title: 'Islam Ka Pehla Rukn',
            method: 'Islam ki bunyaad Shahadah par hai.',
            refs: <HadithRef>[
              HadithRef(book: HadithBook.bukhari, number: 8,
                  note: 'The first of the five'),
            ],
          ),
          IbadatStep(
            title: 'Jannat Ki Kunji',
            method:
                'Jo ikhlas ke saath Shahadah par mare uske liye Jannat ki basharat hai.',
            refs: <HadithRef>[
              HadithRef(book: HadithBook.muslim, number: 136,
                  note: 'Uthman: he who dies affirming it'),
            ],
          ),
          IbadatStep(
            title: 'Tawheed Ka Iqrar',
            method: 'Allah ko akela mabood maan lena.',
          ),
        ],
      ),
      IbadatSection(
        title: 'Shahadah Ke Mukhalif',
        steps: <IbadatStep>[
          IbadatStep(
            title: 'Shirk',
            method: 'Allah ke saath kisi ko shareek karna.',
            keyPoint:
                'Poocha gaya: sabse bada gunah kaunsa hai? Farmaya: Allah ke saath shareek thehrana.',
            refs: <HadithRef>[
              HadithRef(book: HadithBook.bukhari, number: 4477,
                  note: 'Abdullah: the greatest sin in the sight of Allah'),
              HadithRef(book: HadithBook.muslim, number: 257,
                  note: 'Abdullah: which sin is the gravest'),
            ],
          ),
        ],
      ),
    ],
  );

  // ===========================================================================
  // ROZA
  // ===========================================================================
  static const IbadatGuide roza = IbadatGuide(
    pillar: 'Roza',
    reviewed: false,
    sections: <IbadatSection>[
      IbadatSection(
        title: 'Roze Ki Ahmiyat',
        steps: <IbadatStep>[
          IbadatStep(
            title: 'Roza Dhal Hai',
            method: 'Roza gunahon aur jahannam se bachane wali dhal hai.',
            refs: <HadithRef>[
              HadithRef(book: HadithBook.bukhari, number: 1894,
                  note: 'Abu Huraira: fasting is a shield'),
              HadithRef(book: HadithBook.muslim, number: 2705,
                  note: 'Abu Huraira: fasting is a shield'),
            ],
          ),
          IbadatStep(
            title: 'Rayyan Ka Darwaza',
            method: 'Jannat mein rozedaron ke liye khaas darwaza.',
            refs: <HadithRef>[
              HadithRef(book: HadithBook.bukhari, number: 1896,
                  note: 'Sahl: a gate in Paradise called Ar-Rayyan'),
            ],
          ),
          IbadatStep(
            title: 'Sehri Mein Barkat Hai',
            method: 'Sehri karna Sunnat hai.',
            refs: <HadithRef>[
              HadithRef(book: HadithBook.bukhari, number: 1923,
                  note: 'Anas: take suhur, there is a blessing in it'),
              HadithRef(book: HadithBook.muslim, number: 2549,
                  note: 'Anas: take the meal before dawn'),
            ],
          ),
        ],
      ),
      IbadatSection(
        title: 'Roze Ka Tareeqa',
        steps: <IbadatStep>[
          // The "wa bisawmi ghadin nawaytu" niyyah has been REMOVED. It is in
          // none of the six books — searched all six, zero matches — so there
          // is nothing to cite and no reason to print it as though there were.
          //
          // Sahur itself is established: see "Sehri Mein Barkat Hai" above,
          // Bukhari 1923 and Muslim 2549. Taking sahur is sunnah; that
          // particular wording is not from these collections.
          IbadatStep(
            title: 'Sehri',
            method:
                'Subah Sadiq se pehle sehri karna. Niyyat dil ka irada hai — koi makhsoos alfaz zaroori nahi.',
            refs: <HadithRef>[
              HadithRef(book: HadithBook.bukhari, number: 1923,
                  note: 'Anas: take suhur, there is a blessing in it'),
            ],
          ),
          IbadatStep(
            title: 'Roza Rakhna',
            method:
                'Subah Sadiq se Maghrib tak khana, peena aur jima se ruk jana.',
          ),
          // The dua here is the one Abu Dawud 2357 ACTUALLY contains. The more
          // commonly printed "Allahumma inni laka sumtu" appears only at Abu
          // Dawud 2358, which all four graders call Daif.
          IbadatStep(
            title: 'Iftar',
            arabic:
                'ذَهَبَ الظَّمَأُ وَابْتَلَّتِ الْعُرُوقُ وَثَبَتَ الْأَجْرُ إِنْ شَاءَ اللَّهُ',
            translation:
                'Thirst has gone, the arteries are moist, and the reward is sure, if Allah wills.',
            refs: <HadithRef>[
              HadithRef(book: HadithBook.abudawud, number: 2357,
                  note: 'Ibn Umar: what he said when breaking the fast'),
            ],
          ),
          IbadatStep(
            title: 'Iftar Mein Jaldi',
            method: 'Iftar mein jaldi karna behtar hai.',
            refs: <HadithRef>[
              HadithRef(book: HadithBook.bukhari, number: 1957,
                  note: 'Sahl: people remain on the right path while they hasten it'),
              HadithRef(book: HadithBook.muslim, number: 2554,
                  note: 'Sahl b. Sa\u2018d: hastening the breaking of the fast'),
            ],
          ),
        ],
      ),
    ],
  );

  // ===========================================================================
  // ZAKAT — the hadith side. The calculator is a separate screen.
  // ===========================================================================
  static const IbadatGuide zakat = IbadatGuide(
    pillar: 'Zakat',
    reviewed: false,
    sections: <IbadatSection>[
      IbadatSection(
        title: 'Zakat Kya Hai?',
        steps: <IbadatStep>[
          IbadatStep(
            title: 'Ta\u2018aruf',
            method:
                'Maal ka muqarrar hissa Allah ke hukm se mustahiq logon ko dena.',
            refs: <HadithRef>[
              HadithRef(book: HadithBook.bukhari, number: 8,
                  note: 'Zakat among the five on which Islam is built'),
              HadithRef(book: HadithBook.muslim, number: 111,
                  note: 'The five on which Islam is based'),
            ],
          ),
        ],
      ),
      IbadatSection(
        title: 'Zakat Ki Ahmiyat',
        steps: <IbadatStep>[
          IbadatStep(
            title: 'Islam Ka Teesra Rukn',
            method: 'Zakat Islam ke paanch arkaan mein se hai.',
            refs: <HadithRef>[
              HadithRef(book: HadithBook.bukhari, number: 8,
                  note: 'Ibn Umar: Islam is built on five'),
            ],
          ),
          IbadatStep(
            title: 'Maal Ko Paak Karti Hai',
            method: 'Zakat maal ko paak karti hai aur barkat ka sabab hai.',
          ),
          IbadatStep(
            title: 'Gareebon Ka Haq',
            method: 'Zakat mustahiqeen ka haq hai, ehsan nahi.',
          ),
        ],
      ),
      IbadatSection(
        title: 'Zakat Na Dene Par Wa\u2018eed',
        steps: <IbadatStep>[
          IbadatStep(
            title: 'Wa\u2018eed',
            method:
                'Jisne sona-chandi jama kiya aur uski zakat na di, Qayamat ke din us maal se azab diya jayega.',
            refs: <HadithRef>[
              HadithRef(book: HadithBook.muslim, number: 2290,
                  note: 'Abu Huraira: the owner of gold and silver who does not pay'),
            ],
          ),
        ],
      ),
    ],
  );

  // ===========================================================================
  // HAJJ
  // ===========================================================================
  static const IbadatGuide hajj = IbadatGuide(
    pillar: 'Hajj',
    reviewed: false,
    sections: <IbadatSection>[
      IbadatSection(
        title: 'Hajj Ki Ahmiyat',
        steps: <IbadatStep>[
          IbadatStep(
            title: 'Hajj Mabroor Ka Badla Jannat',
            refs: <HadithRef>[
              HadithRef(book: HadithBook.bukhari, number: 1773,
                  note: 'Abu Huraira: hajj mabroor has no reward but Paradise'),
              HadithRef(book: HadithBook.muslim, number: 3289,
                  note: 'Abu Huraira: the accepted hajj'),
            ],
          ),
          IbadatStep(
            title: 'Gunahon Se Paak Ho Kar Lautna',
            refs: <HadithRef>[
              HadithRef(book: HadithBook.bukhari, number: 1521,
                  note: 'Returns like the day his mother bore him'),
              HadithRef(book: HadithBook.bukhari, number: 1820,
                  note: 'Whoever performs hajj to this Kaaba'),
            ],
          ),
          IbadatStep(
            title: 'Islam Ka Panchwa Rukn',
            refs: <HadithRef>[
              HadithRef(book: HadithBook.bukhari, number: 8,
                  note: 'Hajj among the five'),
            ],
          ),
        ],
      ),
      IbadatSection(
        title: 'Hajj Ka Tareeqa',
        steps: <IbadatStep>[
          IbadatStep(title: 'Ihram',
              method: 'Ihram bandhna aur mahdood cheezon se ruk jana.'),
          IbadatStep(
            title: 'Talbiyah',
            arabic: 'لَبَّيْكَ اللَّهُمَّ لَبَّيْكَ',
            translation: 'Here I am, O Allah, here I am.',
            refs: <HadithRef>[
              HadithRef(book: HadithBook.bukhari, number: 1549,
                  note: 'Ibn Umar: the talbiyah of the Messenger of Allah'),
              HadithRef(book: HadithBook.muslim, number: 2811,
                  note: 'Ibn Umar: the wording of the talbiyah'),
            ],
          ),
          IbadatStep(title: 'Tawaf', method: 'Kaaba ke saat chakkar.'),
          IbadatStep(title: 'Sa\u2018i',
              method: 'Safa aur Marwah ke darmiyan saat chakkar.'),
          IbadatStep(title: 'Mina', method: '8 Zilhajj ko Mina mein qiyam.'),
          IbadatStep(
            title: 'Arafah',
            method: 'Hajj ka sabse aham rukn — 9 Zilhajj ko Arafah mein wuquf.',
            keyPoint: '"Hajj Arafah hai."',
            refs: <HadithRef>[
              HadithRef(book: HadithBook.tirmidhi, number: 889,
                  note: 'Abdur-Rahman b. Ya\u2018mar: hajj is Arafah'),
              HadithRef(book: HadithBook.nasai, number: 3016,
                  note: 'Abdur-Rahman b. Ya\u2018mar at Arafat'),
              HadithRef(book: HadithBook.ibnmajah, number: 3015,
                  note: 'Abdur-Rahman b. Ya\u2018mar Dili'),
            ],
          ),
          IbadatStep(title: 'Muzdalifah', method: 'Raat Muzdalifah mein guzarna.'),
          IbadatStep(title: 'Rami', method: 'Jamrat par kankariyan marna.'),
          IbadatStep(title: 'Qurbani', method: 'Qurbani karna.'),
          IbadatStep(title: 'Halq / Qasr', method: 'Sar mundwana ya baal katwana.'),
          IbadatStep(title: 'Tawaf-e-Ziyarah',
              method: 'Tawaf-e-Ziyarah — Hajj ka rukn.'),
        ],
      ),
    ],
  );

  // ===========================================================================
  // UMRAH
  // ===========================================================================
  static const IbadatGuide umrah = IbadatGuide(
    pillar: 'Umrah',
    reviewed: false,
    sections: <IbadatSection>[
      IbadatSection(
        title: 'Umrah Ka Tareeqa',
        steps: <IbadatStep>[
          IbadatStep(title: 'Ihram', method: 'Ihram bandhna.'),
          IbadatStep(
            title: 'Talbiyah',
            arabic: 'لَبَّيْكَ اللَّهُمَّ لَبَّيْكَ',
            translation: 'Here I am, O Allah, here I am.',
            refs: <HadithRef>[
              HadithRef(book: HadithBook.bukhari, number: 1549,
                  note: 'Ibn Umar: the talbiyah'),
              HadithRef(book: HadithBook.muslim, number: 2811,
                  note: 'Ibn Umar: the wording of the talbiyah'),
            ],
          ),
          IbadatStep(title: 'Tawaf', method: 'Kaaba ke saat chakkar.'),
          IbadatStep(title: 'Sa\u2018i',
              method: 'Safa aur Marwah ke darmiyan saat chakkar.'),
          IbadatStep(title: 'Halq / Qasr', method: 'Baal katwana.'),
        ],
      ),
      IbadatSection(
        title: 'Umrah Ki Ahmiyat',
        steps: <IbadatStep>[
          IbadatStep(
            title: 'Ek Umrah Se Doosre Umrah Tak Kaffarah',
            refs: <HadithRef>[
              HadithRef(book: HadithBook.bukhari, number: 1773,
                  note: 'Abu Huraira: umrah is an expiation for what is between'),
              HadithRef(book: HadithBook.muslim, number: 3289,
                  note: 'Abu Huraira: from one umrah to the next'),
            ],
          ),
          IbadatStep(
            title: 'Ramadan Mein Umrah',
            method: 'Ramadan mein Umrah ka ajar Hajj ke barabar bataya gaya.',
            refs: <HadithRef>[
              HadithRef(book: HadithBook.bukhari, number: 1782,
                  note: 'Ibn Abbas: what the Prophet said to Umm Sinan'),
              HadithRef(book: HadithBook.tirmidhi, number: 939,
                  note: 'Umm Ma\u2018qil: umrah in Ramadan is equal to hajj'),
            ],
          ),
        ],
      ),
    ],
  );

  // ===========================================================================
  // NAMAZ-E-JANAZA
  // ===========================================================================
  static const IbadatGuide janaza = IbadatGuide(
    pillar: 'Namaz-e-Janaza',
    reviewed: false,
    sections: <IbadatSection>[
      IbadatSection(
        title: 'Janaze Ki Ahmiyat',
        steps: <IbadatStep>[
          IbadatStep(
            title: 'Ajar',
            method:
                'Jo janaze mein shareek ho aur namaz-e-janaza padhe uske liye ek qirat ajar hai.',
            refs: <HadithRef>[
              HadithRef(book: HadithBook.bukhari, number: 1325,
                  note: 'Abu Huraira: a qirat for whoever prays over it'),
            ],
          ),
        ],
      ),
      IbadatSection(
        title: 'Janaze Ka Tareeqa',
        steps: <IbadatStep>[
          IbadatStep(
            title: 'Saf Bandi Aur Niyyat',
            method:
                'Janaza saamne rakh kar imam ke peeche safein banayi jati hain. Namaz-e-janaza mein na ruku hai na sajdah — poori namaz khade ho kar chaar takbeeron mein hoti hai.',
            refs: <HadithRef>[
              HadithRef(book: HadithBook.bukhari, number: 1245,
                  note: 'Najashi: he lined them up and said four takbirs'),
              HadithRef(book: HadithBook.muslim, number: 2204,
                  note: 'Abu Huraira: four takbirs over the Negus'),
            ],
          ),
          IbadatStep(
            title: 'Pehli Takbeer',
            method:
                'Haath uthakar "Allahu Akbar" kahein, phir haath baandh kar Sana padhein.',
            arabic: 'اللّٰهُ أَكْبَرُ',
            translation: 'Allah is the Greatest.',
            practiceDiffers:
                'Pehli takbeer ke baad kya padha jaye — Hanafi mazhab mein Sana, aur Shafi\u2018i mazhab mein Surah Al-Fatihah. Yeh ikhtilaf mashhoor hai.',
            refs: <HadithRef>[
              HadithRef(book: HadithBook.bukhari, number: 1318,
                  note: 'He went forward and they lined up; four takbirs'),
            ],
          ),
          IbadatStep(
            title: 'Doosri Takbeer',
            method: 'Doosri takbeer ke baad Durood Ibrahim padhein.',
            // Same complete Durood as in the namaz guide, from Bukhari 3370.
            arabic:
                'اللَّهُمَّ صَلِّ عَلَى مُحَمَّدٍ وَعَلَى آلِ مُحَمَّدٍ، '
                'كَمَا صَلَّيْتَ عَلَى إِبْرَاهِيمَ وَعَلَى آلِ إِبْرَاهِيمَ، إِنَّكَ حَمِيدٌ مَجِيدٌ. '
                'اللَّهُمَّ بَارِكْ عَلَى مُحَمَّدٍ وَعَلَى آلِ مُحَمَّدٍ، '
                'كَمَا بَارَكْتَ عَلَى إِبْرَاهِيمَ وَعَلَى آلِ إِبْرَاهِيمَ، إِنَّكَ حَمِيدٌ مَجِيدٌ',
            translation:
                'O Allah, send blessings upon Muhammad and upon the family of Muhammad, '
                'as You sent blessings upon Ibrahim and upon the family of Ibrahim; You are Praiseworthy, Glorious. '
                'O Allah, bless Muhammad and the family of Muhammad, '
                'as You blessed Ibrahim and the family of Ibrahim; You are Praiseworthy, Glorious.',
            refs: <HadithRef>[
              HadithRef(book: HadithBook.bukhari, number: 3370,
                  note: 'Ka\u2018b b. Ujrah: how to invoke blessings'),
              HadithRef(book: HadithBook.muslim, number: 908,
                  note: 'The words taught for sending blessings'),
            ],
          ),
          IbadatStep(
            title: 'Teesri Takbeer \u2014 Mayyit Ke Liye Dua',
            method:
                'Teesri takbeer ke baad mayyit ke liye dua ki jati hai. Yeh dua Sunan an-Nasa\u2019i mein aayi hai.',
            // THE SHORT GENERAL DUA, from Sunan an-Nasa'i 1986.
            //
            // This covers everyone present at the janaza \u2014 the living and
            // the dead, present and absent, young and old, male and female \u2014
            // rather than naming the deceased alone, so it needs no
            // masculine/feminine swap depending on who is being prayed over.
            arabic:
                'اَللّٰهُمَّ اغْفِرْ لِحَيِّنَا وَمَيِّتِنَا وَشَاهِدِنَا وَغَائِبِنَا وَصَغِيْرِنَا وَكَبِيْرِنَا وَذَكَرِنَا وَأُنْثَانَاؕ '
                'اَللّٰهُمَّ مَنْ أَحْيَيْتَهُ مِنَّا فَأَحْيِهِ عَلَى الْإِسْلَامِ وَمَنْ تَوَفَّيْتَهُ مِنَّا فَتَوَفَّهُ عَلَى الْإِيْمَانِؕ',
            translation:
                'O Allah, forgive our living and our dead, those present and those absent, our young and our old, our males and our females. '
                'O Allah, whomever among us You keep alive, keep him alive upon Islam, and whomever among us You cause to die, let him die upon faith.',
            translationUr:
                'اے اللہ! ہمارے زندہ اور ہمارے مردہ کو، ہمارے حاضر اور ہمارے غائب کو، ہمارے چھوٹے اور ہمارے بڑے کو، اور ہمارے مرد اور ہماری عورت کو بخش دے۔ '
                'اے اللہ! ہم میں سے جسے تو زندہ رکھے، اسے اسلام پر زندہ رکھ، اور جسے تو ہم میں سے وفات دے، اسے ایمان پر وفات دے۔',
            refs: <HadithRef>[
              HadithRef(book: HadithBook.nasai, number: 1986,
                  note: 'The shorter general dua for the living and the dead'),
            ],
          ),
          IbadatStep(
            title: 'Chauthi Takbeer Aur Salam',
            method:
                'Chauthi takbeer ke baad thodi der thehar kar dono taraf salam pher dein.',
            arabic: 'السَّلَامُ عَلَيْكُمْ وَرَحْمَةُ اللَّهِ',
            translation: 'Peace and mercy of Allah be upon you.',
            refs: <HadithRef>[
              HadithRef(book: HadithBook.bukhari, number: 1333,
                  note: 'Four takbirs, then the prayer was complete'),
            ],
          ),
        ],
      ),
    ],
  );

  // ===========================================================================
  // NAMAZ-E-EIDAIN
  // ===========================================================================
  static const IbadatGuide eidain = IbadatGuide(
    pillar: 'Namaz-e-Eidain',
    reviewed: false,
    sections: <IbadatSection>[
      IbadatSection(
        title: 'Eid Ki Namaz Ka Tareeqa',
        steps: <IbadatStep>[
          IbadatStep(
            title: 'Eidgah Jana',
            method:
                'Eid ki namaz ke liye Eidgah ya khule maidan mein jana Sunnat hai.',
            refs: <HadithRef>[
              HadithRef(book: HadithBook.bukhari, number: 351,
                  note: 'Umm Atiyya: going out to the musalla on the two Eids'),
            ],
          ),
          IbadatStep(
            title: 'Na Azan Na Iqamat',
            method:
                'Eid ki namaz ke liye na azan hai na iqamat — seedhe namaz shuru ki jati hai.',
            refs: <HadithRef>[
              HadithRef(book: HadithBook.muslim, number: 2049,
                  note: 'Ibn Abbas and Jabir: there was no adhan for the two Eids'),
              HadithRef(book: HadithBook.muslim, number: 2050,
                  note: 'Ata: no adhan on Eid al-Fitr'),
            ],
          ),
          IbadatStep(
            title: 'Do Rakat',
            method:
                'Eid ki namaz do rakat hai. Nabi \u0637 ne is se pehle ya baad koi namaz nahi padhi.',
            refs: <HadithRef>[
              HadithRef(book: HadithBook.bukhari, number: 964,
                  note: 'Ibn Abbas: two rak\u2018at, none before or after'),
              HadithRef(book: HadithBook.bukhari, number: 989,
                  note: 'Ibn Abbas: two rak\u2018at on the day of Eid al-Fitr'),
            ],
          ),
          IbadatStep(
            title: 'Zaid Takbeerein',
            method:
                'Pehli rakat mein qira\u2018at se pehle saat takbeerein, aur '
                'doosri rakat mein paanch \u2014 jaisa in ahadees mein aaya hai. '
                'Har takbeer par haath uthaye jate hain.',
            refs: <HadithRef>[
              HadithRef(book: HadithBook.ibnmajah, number: 1279,
                  note: 'Seven in the first rak\u2018ah and five in the second'),
              HadithRef(book: HadithBook.tirmidhi, number: 536,
                  note: 'Seven before the recitation, five in the last'),
            ],
          ),
          IbadatStep(
            title: 'Khutba Namaz Ke Baad',
            method:
                'Juma ke bar-aks Eid ka khutba namaz ke BAAD hota hai, pehle nahi.',
            refs: <HadithRef>[
              HadithRef(book: HadithBook.bukhari, number: 962,
                  note: 'Ibn Abbas: all of them prayed before the khutba'),
              HadithRef(book: HadithBook.bukhari, number: 963,
                  note: 'Ibn Umar: the two Eid prayers before the sermon'),
              HadithRef(book: HadithBook.muslim, number: 2052,
                  note: 'The Eid prayers were before the sermon'),
            ],
          ),
        ],
      ),
    ],
  );
}
