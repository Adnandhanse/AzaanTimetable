import 'package:flutter/material.dart';
import '../models/masjid.dart';

class TimingReviewStatus extends StatelessWidget {
  final Masjid masjid;
  const TimingReviewStatus({super.key, required this.masjid});
  static String date(DateTime? value) {
    if (value == null) return 'Date available nahi hai';
    final d = value.toLocal();
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(d.day)}/${two(d.month)}/${d.year}, ${two(d.hour)}:${two(d.minute)}';
  }
  @override
  Widget build(BuildContext context) {
    final last = masjid.lastTimesCheckedAt;
    final pending = last == null || DateTime.now().difference(last).inDays >= 10;
    final color = pending ? Colors.orange.shade800 : const Color(0xFF1F5E4A);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(pending ? 'Timings check pending' : 'Timings checked',
            style: TextStyle(color: color, fontWeight: FontWeight.w600)),
        const SizedBox(height: 4),
        Text('Last changed: ${date(masjid.timesUpdatedAt)}',
            style: Theme.of(context).textTheme.bodySmall),
        Text('Last confirmed: ${date(masjid.timesConfirmedAt)}',
            style: Theme.of(context).textTheme.bodySmall),
      ]),
    );
  }
}
