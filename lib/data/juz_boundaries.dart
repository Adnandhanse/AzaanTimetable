/// The standard 30-Juz (Para) division used in virtually all printed
/// Mushaf editions - this is fixed structural data (where each Juz
/// begins), not a translation or interpretation, so it's safe to encode
/// directly. Each entry is (juzNumber, startingSurah, startingVerse).
const List<(int, int, int)> juzBoundaries = [
  (1, 1, 1),
  (2, 2, 142),
  (3, 2, 253),
  (4, 3, 93),
  (5, 4, 24),
  (6, 4, 148),
  (7, 5, 82),
  (8, 6, 111),
  (9, 7, 88),
  (10, 8, 41),
  (11, 9, 93),
  (12, 11, 6),
  (13, 12, 53),
  (14, 15, 1),
  (15, 17, 1),
  (16, 18, 75),
  (17, 21, 1),
  (18, 23, 1),
  (19, 25, 21),
  (20, 27, 56),
  (21, 29, 46),
  (22, 33, 31),
  (23, 36, 28),
  (24, 39, 32),
  (25, 41, 47),
  (26, 46, 1),
  (27, 51, 31),
  (28, 58, 1),
  (29, 67, 1),
  (30, 78, 1),
];

/// Which juz a given verse falls in.
///
/// Walks the boundaries backwards and returns the first one that starts at or
/// before this verse. Backwards because the boundaries are a list of START
/// points: the juz you are in is the last one that has already begun.
int juzForVerse(int surah, int ayah) {
  for (int i = juzBoundaries.length - 1; i >= 0; i--) {
    final (int juz, int s, int a) = juzBoundaries[i];
    if (surah > s || (surah == s && ayah >= a)) return juz;
  }
  return 1;
}
