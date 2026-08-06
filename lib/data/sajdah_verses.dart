/// Verses at which a prostration of recitation (sajdah at-tilawah) is marked.
///
/// Not in the bundled Qur'an data — it carries only id, text and translation —
/// so the positions are listed here. Every one has been checked against the
/// dataset: the surah exists and the ayah number is within its verse count.
///
/// THE SCHOOLS DIFFER ON TWO OF THESE, and the app should not pretend otherwise:
///
///   Sad 38:24        Hanafis count it as a sajdah of recitation.
///                    Shafi'is treat it as a sajdah of thanks, not tilawah.
///   Al-Hajj 22:77    Shafi'is and Hanbalis count a second sajdah in Al-Hajj.
///                    Hanafis do not.
///
/// So the total is 14 or 15 depending on who you ask. Both are marked, and the
/// two disputed ones carry a note rather than being silently included or
/// silently dropped. Dropping either would tell a reader of the other school
/// that their sajdah does not exist.
class SajdahVerses {
  SajdahVerses._();

  /// Agreed by all four schools.
  static const List<(int, int)> agreed = <(int, int)>[
    (7, 206),
    (13, 15),
    (16, 50),
    (17, 109),
    (19, 58),
    (22, 18),
    (25, 60),
    (27, 26),
    (32, 15),
    (41, 38),
    (53, 62),
    (84, 21),
    (96, 19),
  ];

  /// Counted by some schools and not others. Marked, with the difference shown.
  static const Map<(int, int), String> disputed = <(int, int), String>{
    (38, 24): 'Hanafi: sajdah of recitation. Shafi\u2018i: sajdah of thanks.',
    (22, 77): 'Shafi\u2018i and Hanbali count this second sajdah in Al-Hajj; '
        'Hanafi does not.',
  };

  static bool isSajdah(int surah, int ayah) =>
      agreed.contains((surah, ayah)) || disputed.containsKey((surah, ayah));

  /// A note when the schools differ here, otherwise null.
  static String? noteFor(int surah, int ayah) => disputed[(surah, ayah)];
}
