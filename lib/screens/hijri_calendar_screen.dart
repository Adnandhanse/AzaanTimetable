import 'package:flutter/material.dart';
import 'package:hijri/hijri_calendar.dart';

import '../services/app_strings.dart';
import '../theme/app_theme.dart';
import '../widgets/ornaments.dart';

/// A month of the Hijri calendar, with the Gregorian date under each day.
///
/// The app already showed today's Hijri date in the banner, which answers "what
/// is the date" but not "when is the 15th" or "how far away is Ramadan" — the
/// questions people actually open a calendar for.
///
/// BUILT AROUND GREGORIAN DAYS, not Hijri ones. Hijri months are 29 or 30 days
/// depending on the month and year, and the package knows that, but iterating
/// Hijri days risks running off the end of a short month. Walking real dates
/// and asking each one what its Hijri date is cannot produce a day that does
/// not exist.
class HijriCalendarScreen extends StatefulWidget {
  const HijriCalendarScreen({super.key});

  @override
  State<HijriCalendarScreen> createState() => _HijriCalendarScreenState();
}

class _HijriCalendarScreenState extends State<HijriCalendarScreen> {
  /// The Gregorian day whose Hijri month is being shown.
  late DateTime _anchor;

  @override
  void initState() {
    super.initState();
    _anchor = DateTime.now();
  }

  HijriCalendar _hijri(DateTime d) => HijriCalendar.fromDate(d);

  /// Every Gregorian day belonging to the Hijri month that [_anchor] sits in.
  List<DateTime> get _daysInHijriMonth {
    final target = _hijri(_anchor);
    // Walk back to the first of the Hijri month, then forward until it changes.
    DateTime cursor = _anchor;
    while (_hijri(cursor).hDay > 1) {
      cursor = cursor.subtract(const Duration(days: 1));
    }
    final days = <DateTime>[];
    while (_hijri(cursor).hMonth == target.hMonth &&
        _hijri(cursor).hYear == target.hYear) {
      days.add(cursor);
      cursor = cursor.add(const Duration(days: 1));
      // 30 is the longest a Hijri month can be. A guard, not a limit — if the
      // package ever returned something odd this would stop an infinite loop
      // rather than hanging the screen.
      if (days.length > 30) break;
    }
    return days;
  }

  void _step(int months) {
    // Step by roughly a lunar month, then let the day-walk above snap to the
    // real boundary. Adding 29.5 days and correcting is safer than trying to
    // construct a Hijri date directly.
    setState(() => _anchor = _anchor.add(Duration(days: 29 * months)));
  }

  @override
  Widget build(BuildContext context) {
    final days = _daysInHijriMonth;
    final h = _hijri(_anchor);
    final today = DateTime.now();
    final bool urdu = S.isUrdu;

    // Which weekday the month starts on, so the grid lines up under S M T W...
    final int leading = days.isEmpty ? 0 : days.first.weekday % 7;

    return Scaffold(
      appBar: AppBar(title: Text(urdu ? 'اسلامی کیلنڈر' : 'Hijri Calendar')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
        children: <Widget>[
          Row(
            children: <Widget>[
              IconButton(
                icon: const Icon(Icons.chevron_left),
                color: AppColors.emerald,
                onPressed: () => _step(-1),
              ),
              Expanded(
                child: Column(
                  children: <Widget>[
                    Text('${h.longMonthName} ${h.hYear} AH',
                        style: AppText.displayName.copyWith(
                            fontSize: 20, color: AppColors.emerald)),
                    if (days.isNotEmpty)
                      Text(
                        _gregorianSpan(days),
                        style: AppText.caption
                            .copyWith(color: AppColors.textMuted),
                      ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right),
                color: AppColors.emerald,
                onPressed: () => _step(1),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const DiamondRule(),
          const SizedBox(height: 12),
          Row(
            children: <Widget>[
              for (final String d in const <String>[
                'S', 'M', 'T', 'W', 'T', 'F', 'S'
              ])
                Expanded(
                  child: Text(d,
                      textAlign: TextAlign.center,
                      style: AppText.eyebrow
                          .copyWith(color: AppColors.textFaint)),
                ),
            ],
          ),
          const SizedBox(height: 6),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: leading + days.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              childAspectRatio: 0.82,
            ),
            itemBuilder: (context, i) {
              if (i < leading) return const SizedBox.shrink();
              final DateTime g = days[i - leading];
              final HijriCalendar hd = _hijri(g);
              final bool isToday = g.year == today.year &&
                  g.month == today.month &&
                  g.day == today.day;
              // Friday matters more than a weekend in this calendar.
              final bool isFriday = g.weekday == DateTime.friday;

              return Container(
                margin: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: isToday ? AppColors.emerald : null,
                  borderRadius: BorderRadius.circular(8),
                  border: !isToday && isFriday
                      ? Border.all(color: AppColors.goldRule)
                      : null,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Text(
                      '${hd.hDay}',
                      style: AppText.listTime.copyWith(
                        fontSize: 16,
                        color: isToday
                            ? Colors.white
                            : (isFriday ? AppColors.emerald : AppColors.text),
                      ),
                    ),
                    // The Gregorian day underneath. Without it the calendar is
                    // unusable for planning — nobody else's diary is in Hijri.
                    Text(
                      '${g.day}',
                      style: AppText.caption.copyWith(
                        fontSize: 10,
                        color: isToday
                            ? Colors.white70
                            : AppColors.textFaint,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 18),
          const DiamondRule(),
          const SizedBox(height: 12),
          Text(
            urdu
                ? 'بڑا عدد اسلامی تاریخ ہے، چھوٹا عدد عیسوی تاریخ۔ جمعہ سنہری دائرے میں ہے۔'
                : 'The large number is the Hijri date, the small one Gregorian. Fridays are outlined.',
            style: AppText.caption.copyWith(color: AppColors.textMuted),
          ),
          const SizedBox(height: 10),
          Text(
            // Said plainly, because it is the single most common complaint
            // about any Hijri calendar in an app.
            urdu
                ? 'یہ حساب کے مطابق ہے۔ آپ کی مقامی مسجد کا چاند دیکھنے کا اعلان ایک دن آگے پیچھے ہو سکتا ہے۔'
                : 'These dates are calculated. Your local moon sighting may differ by a day.',
            style: AppText.caption.copyWith(color: AppColors.textFaint),
          ),
        ],
      ),
    );
  }

  String _gregorianSpan(List<DateTime> days) {
    const m = <String>[
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    final a = days.first;
    final b = days.last;
    if (a.month == b.month) {
      return '${a.day}\u2013${b.day} ${m[a.month]} ${a.year}';
    }
    return '${a.day} ${m[a.month]} \u2013 ${b.day} ${m[b.month]} ${b.year}';
  }
}
