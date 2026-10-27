import 'package:flutter/material.dart';
import '../models/masjid.dart';
import '../services/app_strings.dart';
import '../theme/app_theme.dart';

/// One quiet timestamp. Reminder delivery is automatic backend work.
class TimingReviewStatus extends StatelessWidget {
  final Masjid masjid;
  const TimingReviewStatus({super.key, required this.masjid});
  static String date(DateTime? value) {
    if (value == null) return S.tr('Not recorded', 'ریکارڈ نہیں ہوا');
    final d = value.toLocal();
    const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    return '${d.day} ${months[d.month - 1]} ${d.year}, ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
  }
  @override
  Widget build(BuildContext context) {
    if (masjid.timesUpdatedAt == null) return const SizedBox.shrink();
    return Padding(padding: const EdgeInsets.only(top: 5),
      child: Text('${S.tr('Last saved', 'آخری بار محفوظ')}: ${date(masjid.timesUpdatedAt)}',
        style: AppText.caption.copyWith(fontSize: 11, color: AppColors.textMid)));
  }
}
