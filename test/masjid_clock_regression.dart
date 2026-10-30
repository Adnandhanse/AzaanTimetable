// Run: dart run test/masjid_clock_regression.dart (after flutter pub get).
import '../lib/services/masjid_clock.dart';

import 'package:timezone/timezone.dart' as tz;

int checks = 0;
void equal(Object? actual, Object? expected, String name) {
  if (actual is DateTime && expected is DateTime
      ? !actual.isAtSameMomentAs(expected)
      : actual != expected)
    throw StateError('$name: $actual != $expected');
  checks++;
}

void main() {
  MasjidClock.initialize();
  equal(MasjidClock.zoneFor(19.033, 73.0297), 'Asia/Kolkata', 'Navi Mumbai');
  equal(MasjidClock.zoneFor(24.7136, 46.6753), 'Asia/Riyadh', 'Riyadh');
  equal(MasjidClock.zoneFor(51.5074, -0.1278), 'Europe/London', 'London');
  equal(MasjidClock.zoneFor(40.7128, -74.006), 'America/New_York', 'New York');
  equal(MasjidClock.zoneFor(-33.8688, 151.2093), 'Australia/Sydney', 'Sydney');
  equal(MasjidClock.parse('12:00 AM'), (0, 0), 'Midnight');
  equal(MasjidClock.parse('12:00 PM'), (12, 0), 'Noon');
  equal(MasjidClock.parse('10:00pm'), (22, 0), 'Compact AM/PM');
  equal(MasjidClock.parse('23:59'), (23, 59), '24-hour clock');
  for (final invalid in [
    '--:--',
    '',
    '25:00',
    '12:60',
    '00:30 AM',
    '13:00 PM',
  ]) {
    equal(MasjidClock.parse(invalid), null, 'Invalid $invalid');
  }
  final now = DateTime.utc(2026, 10, 29, 0);
  final saudi = MasjidClock.next('10:00 AM', 'Asia/Riyadh', now)!;
  equal(saudi.toUtc(), DateTime.utc(2026, 10, 29, 7), 'Saudi 10am UTC');
  final indian = tz.TZDateTime.from(
    saudi,
    MasjidClock.location('Asia/Kolkata'),
  );
  equal((indian.hour, indian.minute), (12, 30), 'Saudi 10am is India 12:30pm');
  final midnight = MasjidClock.next('11:30 PM', 'America/New_York', now)!;
  final india = tz.TZDateTime.from(
    midnight,
    MasjidClock.location('Asia/Kolkata'),
  );
  equal((india.day, india.hour), (29, 9), 'Cross-date conversion');
  // Friday in the mosque while it is still Thursday at the follower.
  final friday = MasjidClock.next(
    '12:30 AM',
    'Asia/Tokyo',
    DateTime.utc(2026, 10, 29, 12),
    fridayOnly: true,
  )!;
  equal(friday.weekday, DateTime.friday, 'Juma source weekday');
  equal(
    friday.toUtc().weekday,
    DateTime.thursday,
    'Juma destination previous day',
  );
  final dhuhr = MasjidClock.next(
    '12:30 PM',
    'Asia/Riyadh',
    DateTime.utc(2026, 10, 30, 0),
    skipFriday: true,
  )!;
  equal(dhuhr.weekday, DateTime.saturday, 'Dhuhr skips mosque Friday');
  equal(
    MasjidClock.next(
      '12:30 PM',
      'Asia/Riyadh',
      DateTime.utc(2026, 10, 30, 0),
    )!.weekday,
    DateTime.friday,
    'Dhuhr retained when no Juma configured',
  );
  final before = MasjidClock.onDate(
    '10:00 AM',
    'America/New_York',
    DateTime.utc(2026, 3, 7, 12),
  )!;
  final after = MasjidClock.onDate(
    '10:00 AM',
    'America/New_York',
    DateTime.utc(2026, 3, 7, 12),
    dayOffset: 1,
  )!;
  equal(after.hour, 10, 'Spring DST preserves wall clock');
  equal(after.difference(before).inHours, 23, 'Spring day is 23 hours');
  final autumn = MasjidClock.onDate(
    '10:00 AM',
    'America/New_York',
    DateTime.utc(2026, 10, 31, 12),
  )!;
  final nextDay = MasjidClock.onDate(
    '10:00 AM',
    'America/New_York',
    DateTime.utc(2026, 10, 31, 12),
    dayOffset: 1,
  )!;
  equal(nextDay.hour, 10, 'Autumn DST preserves wall clock');
  equal(nextDay.difference(autumn).inHours, 25, 'Autumn day is 25 hours');
  final passed = MasjidClock.next(
    '10:00 AM',
    'Asia/Riyadh',
    DateTime.utc(2026, 10, 29, 8),
  )!;
  equal(passed.day, 30, 'Past time advances mosque date');
  for (final coords in [
    (0.0, 0.0),
    (91.0, 5.0),
    (4.0, 181.0),
    (double.nan, 0.0),
  ]) {
    var rejected = false;
    try {
      MasjidClock.zoneFor(coords.$1, coords.$2);
    } catch (_) {
      rejected = true;
    }
    equal(rejected, true, 'Bad location rejected');
  }
  print('$checks timezone regression checks passed');
}
