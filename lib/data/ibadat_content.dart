import '../models/hadith.dart';
import '../services/hadith_link.dart';

/// One step of an act of worship, with the hadith cited for it.
class IbadatStep {
  const IbadatStep({
    required this.title,
    this.method,
    this.arabic,
    this.translation,
    this.keyPoint,
    this.refs = const <HadithRef>[],
    this.practiceDiffers,
  });

  final String title;

  /// The tareeqa — what the worshipper actually does.
  final String? method;

  /// What is said at this step.
  final String? arabic;

  /// Meaning of [arabic] in English.
  final String? translation;

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
            arabic:
                'بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ\nالْحَمْدُ لِلَّهِ رَبِّ الْعَالَمِينَ',
            translation:
                'In the Name of Allah, the Most Gracious, the Most Merciful. All praise is due to Allah, Lord of the worlds...',
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
            arabic: 'التَّحِيَّاتُ لِلَّهِ وَالصَّلَوَاتُ وَالطَّيِّبَاتُ...',
            translation:
                'All compliments, prayers and pure words are due to Allah...',
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
            arabic:
                'اللَّهُمَّ صَلِّ عَلَى مُحَمَّدٍ وَعَلَى آلِ مُحَمَّدٍ...',
            translation:
                'O Allah, send blessings upon Muhammad and the family of Muhammad...',
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
}
