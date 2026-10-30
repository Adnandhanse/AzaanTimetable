import 'package:lat_lng_to_timezone/lat_lng_to_timezone.dart' as tzmap;
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

/// Mosque wall-clock times are interpreted at the mosque, never at the phone.
class MasjidClock {
  static bool _ready = false;
  static void initialize() {
    if (_ready) return;
    tzdata.initializeTimeZones();
    _ready = true;
  }

  static tz.Location location(String name) {
    initialize();
    const aliases = {
      'Asia/Calcutta': 'Asia/Kolkata',
      'Asia/Katmandu': 'Asia/Kathmandu',
      'Asia/Saigon': 'Asia/Ho_Chi_Minh',
      'Asia/Rangoon': 'Asia/Yangon',
    };
    return tz.getLocation(aliases[name] ?? name);
  }

  /// Offline lookup from the mosque's coordinates, not the admin's country
  /// code (an admin may have a foreign phone number).
  static String zoneFor(double latitude, double longitude) {
    if (!latitude.isFinite ||
        !longitude.isFinite ||
        latitude.abs() > 90 ||
        longitude.abs() > 180 ||
        (latitude == 0 && longitude == 0)) {
      throw StateError(
        'Masjid location is missing. Please update its location.',
      );
    }
    return location(tzmap.latLngToTimezoneString(latitude, longitude)).name;
  }

  static (int, int)? parse(String text) {
    final m = RegExp(
      r'^(\d{1,2}):(\d{2})(?:\s*(AM|PM))?$',
      caseSensitive: false,
    ).firstMatch(text.trim());
    if (m == null) return null;
    var hour = int.parse(m[1]!);
    final minute = int.parse(m[2]!);
    final period = m[3]?.toUpperCase();
    if (minute > 59 || (period == null ? hour > 23 : hour < 1 || hour > 12)) {
      return null;
    }
    if (period != null) hour = hour % 12 + (period == 'PM' ? 12 : 0);
    return (hour, minute);
  }

  static tz.TZDateTime? onDate(
    String text,
    String zone,
    DateTime instant, {
    int dayOffset = 0,
  }) {
    final hm = parse(text);
    if (hm == null) return null;
    final loc = location(zone);
    final day = tz.TZDateTime.from(instant, loc);
    // Calendar construction, not +24 hours: handles DST transitions.
    return tz.TZDateTime(
      loc,
      day.year,
      day.month,
      day.day + dayOffset,
      hm.$1,
      hm.$2,
    );
  }

  static tz.TZDateTime? next(
    String text,
    String zone,
    DateTime now, {
    bool fridayOnly = false,
    bool skipFriday = false,
  }) {
    for (var day = 0; day < 9; day++) {
      final at = onDate(text, zone, now, dayOffset: day);
      if (at == null) return null;
      if (!at.isAfter(now)) continue;
      if (fridayOnly && at.weekday != DateTime.friday) continue;
      if (skipFriday && at.weekday == DateTime.friday) continue;
      return at;
    }
    return null;
  }

  static String localDisplay(String text, String zone, DateTime now) {
    final at = next(text, zone, now);
    if (at == null) return text;
    final local = at.toLocal();
    return '${local.hour % 12 == 0 ? 12 : local.hour % 12}:'
        '${local.minute.toString().padLeft(2, '0')} ${local.hour < 12 ? 'AM' : 'PM'}';
  }
}
