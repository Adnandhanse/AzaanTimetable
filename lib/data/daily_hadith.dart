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
    required this.theme,
  });

  final HadithBook book;
  final int number;

  /// Verbatim from the dataset. Not shortened — trimming a hadith to fit a card
  /// is editing it.
  final String text;

  /// A word for what it is about, shown above the text.
  final String theme;

  HadithRef get ref => HadithRef(book: book, number: number);

  static const List<DailyHadith> all = <DailyHadith>[
    DailyHadith(
      book: HadithBook.bukhari,
      number: 1,
      theme: 'Intention',
      text:
          'Narrated \'Umar bin Al-Khattab: I heard Allah\'s Messenger (\uFDFA) saying, "The reward of deeds depends upon the intentions and every person will get the reward according to what he has intended."',
    ),
    DailyHadith(
      book: HadithBook.muslim,
      number: 170,
      theme: 'Brotherhood',
      text:
          'It is narrated on the authority of Anas b. Malik that the Prophet (\uFDFA) observed: "None amongst you believes (truly) until he loves for his brother" \u2014 or he said "for his neighbour" \u2014 "that which he loves for himself."',
    ),
    DailyHadith(
      book: HadithBook.bukhari,
      number: 6114,
      theme: 'Self-control',
      text:
          'Narrated Abu Huraira: Allah\'s Messenger (\uFDFA) said, "The strong is not the one who overcomes the people by his strength, but the strong is the one who controls himself while in anger."',
    ),
    DailyHadith(
      book: HadithBook.bukhari,
      number: 6116,
      theme: 'Anger',
      text:
          'Narrated Abu Huraira: A man said to the Prophet (\uFDFA), "Advise me!" The Prophet (\uFDFA) said, "Do not become angry and furious." The man asked again and again, and the Prophet (\uFDFA) said in each case, "Do not become angry and furious."',
    ),
    DailyHadith(
      book: HadithBook.bukhari,
      number: 6125,
      theme: 'Gentleness',
      text:
          'Narrated Anas bin Malik: The Prophet (\uFDFA) said, "Make things easy for the people, and do not make it difficult for them, and make them calm (with glad tidings) and do not repulse (them)."',
    ),
    DailyHadith(
      book: HadithBook.bukhari,
      number: 6136,
      theme: 'Neighbours and speech',
      text:
          'Narrated Abu Huraira: The Prophet (\uFDFA) said, "Whoever believes in Allah and the Last Day, should not hurt his neighbor; and whoever believes in Allah and the Last Day, should serve his guest generously; and whoever believes in Allah and the Last Day, should speak what is good or keep silent."',
    ),
    DailyHadith(
      book: HadithBook.tirmidhi,
      number: 1922,
      theme: 'Mercy',
      text:
          'Jarir bin Abdullah narrated that the Messenger of Allah (\uFDFA) said: "Whoever does not show mercy to the people, Allah will not show mercy to him."',
    ),
    DailyHadith(
      book: HadithBook.tirmidhi,
      number: 1162,
      theme: 'Character',
      text:
          'Abu Hurairah narrated that the Messenger of Allah (\uFDFA) said: "The most complete of the believers in faith is the one with the best character among them. And the best of you are those who are best to your women."',
    ),
    DailyHadith(
      book: HadithBook.ibnmajah,
      number: 1978,
      theme: 'Family',
      text:
          'It was narrated from \'Abdullah bin \'Amr that the Messenger of Allah (\uFDFA) said: "The best of you are those who are best to their womenfolk."',
    ),
    DailyHadith(
      book: HadithBook.abudawud,
      number: 4811,
      theme: 'Gratitude',
      text:
          'Narrated Abu Hurayrah: The Prophet (\uFDFA) said: "He who does not thank the people is not thankful to Allah."',
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
