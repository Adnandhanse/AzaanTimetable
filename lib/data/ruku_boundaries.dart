/// Where each Ruku' (paragraph, marked ﻉ in Indo-Pak Mushafs) begins.
///
/// PARTIAL DATA — READ BEFORE EXTENDING.
///
/// There is no bundled, machine-readable source for Ruku boundaries in this
/// app, and I could not fetch one I could verify (the sites that publish a
/// complete 558-entry table either block automated fetches or are too large
/// to check). Rather than fill in 114 surahs from memory - risky for a
/// Qur'an app, since a wrong boundary here is a wrong boundary shown to
/// someone reading - this table only carries spans I could confirm from
/// independently agreeing sources:
///   * Surah 1 (Al-Fatihah) - complete. 1 ruku, all 7 ayat.
///   * Surah 2 (Al-Baqarah) - rukus 1-8 and 11-35. Rukus 9-10 (ayah 72-86)
///     and 36-40 (ayah 261 to the end of the surah) are marked UNKNOWN
///     rather than guessed, because I only had one source for those spans
///     and could not cross-check it.
///
/// A `null` ruku number marks an UNKNOWN span. [rukuAt] returns null for any
/// verse in an unknown span, or in a surah not listed here at all - the
/// side indicator simply does not show rather than risking a wrong one.
///
/// TO EXTEND: add more (surahNumber, startVerse, rukuNumberInSurah) rows
/// below, in ascending verse order per surah, from a verified source. A
/// verse-level dataset that tags each ayah with its own ruku number (several
/// exist) is the easiest to check this against and convert from.
const List<(int, int, int?)> _rukuStarts = <(int, int, int?)>[
  // Surah 1 - Al-Fatihah. 1 ruku total.
  (1, 1, 1),

  // Surah 2 - Al-Baqarah. 40 rukus total; verified for 1-8 and 11-35 only.
  (2, 1, 1),
  (2, 8, 2),
  (2, 21, 3),
  (2, 30, 4),
  (2, 40, 5),
  (2, 47, 6),
  (2, 60, 7),
  (2, 62, 8),
  (2, 72, null), // Rukus 9-10 - not independently verified.
  (2, 87, 11),
  (2, 97, 12),
  (2, 104, 13),
  (2, 113, 14),
  (2, 122, 15),
  (2, 130, 16),
  (2, 142, 17),
  (2, 148, 18),
  (2, 153, 19),
  (2, 164, 20),
  (2, 168, 21),
  (2, 177, 22),
  (2, 183, 23),
  (2, 189, 24),
  (2, 197, 25),
  (2, 211, 26),
  (2, 217, 27),
  (2, 222, 28),
  (2, 229, 29),
  (2, 232, 30),
  (2, 236, 31),
  (2, 243, 32),
  (2, 249, 33),
  (2, 254, 34),
  (2, 258, 35),
  (2, 261, null), // Rukus 36-40 - not independently verified.
];

/// The Ruku' active at `surahNumber:verseNumber`, if this table covers it.
///
/// Returns (rukuNumberInSurah, startVerse, endVerse). [endVerse] is null
/// when this is the last verified span for the surah — which may mean it
/// really is the surah's last ruku, or may just mean the table runs out
/// there. The caller cannot tell which, so callers should not claim to know
/// where an open-ended span ends.
(int, int, int?)? rukuAt(int surahNumber, int verseNumber) {
  (int, int, int?)? current;
  (int, int, int?)? next;

  for (final (int surah, int start, int? ruku) in _rukuStarts) {
    if (surah != surahNumber) continue;
    if (start <= verseNumber) {
      current = (surah, start, ruku);
    } else {
      next = (surah, start, ruku);
      break;
    }
  }

  if (current == null || current.$3 == null) return null;

  final int? end = (next != null && next.$1 == surahNumber) ? next.$2 - 1 : null;
  return (current.$3!, current.$2, end);
}
