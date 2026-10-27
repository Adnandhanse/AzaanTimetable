import 'package:flutter/material.dart';
import '../models/masjid.dart';
import '../services/app_strings.dart';
import '../theme/app_theme.dart';

class TimingReviewStatus extends StatelessWidget {
  final Masjid masjid;
  const TimingReviewStatus({super.key, required this.masjid});
  static String date(DateTime? value) {
    if (value == null) return S.tr('Not recorded', 'ریکارڈ نہیں ہوا');
    final d = value.toLocal();
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    return '${d.day} ${months[d.month - 1]} ${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    final last = masjid.lastTimesCheckedAt;
    final pending =
        last == null || DateTime.now().difference(last).inDays >= 10;
    return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Icon(pending ? Icons.schedule : Icons.check_circle_outline,
                size: 14, color: pending ? AppColors.gold : AppColors.emerald),
            const SizedBox(width: 5),
            Flexible(
                child: Text(
                    pending
                        ? S.tr('Review Due', 'جائزہ درکار ہے')
                        : S.tr('Timings Up to Date', 'اوقات تازہ ہیں'),
                    style: AppText.caption.copyWith(
                        color: AppColors.textMid,
                        fontWeight: FontWeight.w600))),
          ]),
          if (masjid.timesUpdatedAt != null)
            Padding(
                padding: const EdgeInsets.only(top: 5),
                child: Text(
                    '${S.tr('Updated', 'تبدیلی')}: ${date(masjid.timesUpdatedAt)}',
                    style: AppText.caption.copyWith(color: AppColors.textMid))),
          if (masjid.timesConfirmedAt != null)
            Padding(
                padding: const EdgeInsets.only(top: 3),
                child: Text(
                    '${S.tr('Confirmed', 'تصدیق')}: ${date(masjid.timesConfirmedAt)}',
                    style: AppText.caption.copyWith(color: AppColors.textMid))),
          if (last == null)
            Padding(
                padding: const EdgeInsets.only(top: 5),
                child: Text(
                    S.tr(
                        'Confirm the current timings to start a new review cycle.',
                        'نیا دور شروع کرنے کے لیے موجودہ اوقات کی تصدیق کریں۔'),
                    style: AppText.caption.copyWith(color: AppColors.textMid))),
        ]));
  }
}
