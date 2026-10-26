/// Display-only formatting. Never changes names or addresses in Firestore.
class MasjidDisplay {
  MasjidDisplay._();

  // Capitalize Latin word starts without damaging acronyms (ISCON, UAE),
  // existing mixed case, apostrophes, numbers or non-Latin scripts.
  static String name(String value) => value.trim().replaceAllMapped(
    RegExp(r"(^|[\s-])([a-z])"),
    (m) => '${m[1]}${m[2]!.toUpperCase()}',
  );

  static String address(String address, String city) {
    final parts = address.split(RegExp(r'[,\r\n]+'))
        .map((v) => v.trim()).where((v) => v.isNotEmpty).toList();
    final cityText = city.trim();
    // Append the stored city only if it is not already a complete address part.
    // Also handles an address ending in "City PIN" without repeating the city.
    final cityLower = cityText.toLowerCase();
    final hasCity = cityText.isNotEmpty && parts.any((p) {
      final lower = p.toLowerCase();
      return lower == cityLower || lower.startsWith('$cityLower ') ||
          lower.endsWith(' $cityLower');
    });
    if (cityText.isNotEmpty && !hasCity) parts.add(cityText);
    return parts.isEmpty ? 'Address Not Available' : parts.join(', ');
  }
}
