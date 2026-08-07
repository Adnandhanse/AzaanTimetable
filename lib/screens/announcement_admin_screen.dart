import 'package:flutter/material.dart';

import '../models/masjid.dart';
import '../services/announcement_repository.dart';
import '../theme/app_theme.dart';
import '../widgets/ornaments.dart';

class AnnouncementAdminScreen extends StatefulWidget {
  const AnnouncementAdminScreen({super.key, required this.masjid});

  final Masjid masjid;

  @override
  State<AnnouncementAdminScreen> createState() =>
      _AnnouncementAdminScreenState();
}

class _AnnouncementAdminScreenState extends State<AnnouncementAdminScreen> {
  final _message = TextEditingController();
  Duration _lifetime = const Duration(days: 1);
  bool _posting = false;

  /// Deliberately short options.
  ///
  /// Most masjid announcements are about something happening today or this
  /// week. Offering "never expires" would guarantee a board full of last
  /// Ramadan's timetable, and the one time something urgent is posted it would
  /// be buried among stale notices nobody reads any more.
  static const List<(String, Duration)> _durations = <(String, Duration)>[
    ('Today', Duration(days: 1)),
    ('3 days', Duration(days: 3)),
    ('1 week', Duration(days: 7)),
    ('1 month', Duration(days: 30)),
  ];

  @override
  void dispose() {
    _message.dispose();
    super.dispose();
  }

  Future<void> _post() async {
    final text = _message.text.trim();
    if (text.isEmpty) return;
    setState(() => _posting = true);
    try {
      await AnnouncementRepository.post(
        masjidId: widget.masjid.id,
        message: text,
        lifetime: _lifetime,
      );
      _message.clear();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Announcement posted.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not post: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _posting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Announcements')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
        children: <Widget>[
          Text(
            'Followers of ${widget.masjid.name} will see this on their home screen, and be notified next time they open the app.',
            style: AppText.caption.copyWith(color: AppColors.textMuted),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _message,
            maxLines: 4,
            maxLength: 300,
            decoration: const InputDecoration(
              labelText: 'Message',
              hintText: 'e.g. Juma prayer will be at 1:30 PM this Friday',
              border: OutlineInputBorder(),
            ),
            style: AppText.body.copyWith(color: AppColors.text),
          ),
          const SizedBox(height: 6),
          Text('Show for', style: AppText.eyebrow.copyWith(color: AppColors.textMuted)),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            children: <Widget>[
              for (final (String label, Duration d) in _durations)
                ChoiceChip(
                  label: Text(label),
                  selected: _lifetime == d,
                  selectedColor: AppColors.emerald.withOpacity(0.15),
                  onSelected: (_) => setState(() => _lifetime = d),
                ),
            ],
          ),
          const SizedBox(height: 14),
          FilledButton.icon(
            onPressed: _posting ? null : _post,
            icon: const Icon(Icons.campaign_outlined, size: 18),
            label: Text(_posting ? 'Posting…' : 'Post announcement'),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.emerald,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape:
                  RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
            ),
          ),
          const SizedBox(height: 26),
          const SectionRule(label: 'Posted', trailingDiamond: true),
          const SizedBox(height: 10),
          StreamBuilder<List<Announcement>>(
            stream: AnnouncementRepository.streamAll(
                widget.masjid.id, widget.masjid.name),
            builder: (context, snap) {
              if (!snap.hasData) {
                return const Padding(
                  padding: EdgeInsets.all(20),
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              final list = snap.data!;
              if (list.isEmpty) {
                return Text('Nothing posted yet.',
                    style: AppText.caption.copyWith(color: AppColors.textFaint));
              }
              return Column(
                children: <Widget>[
                  for (final Announcement a in list)
                    Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(
                          color: a.isActive
                              ? AppColors.goldRule
                              : AppColors.goldRuleFaint,
                        ),
                      ),
                      padding: const EdgeInsets.fromLTRB(14, 12, 6, 12),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Text(
                                  a.message,
                                  style: AppText.body.copyWith(
                                    color: a.isActive
                                        ? AppColors.text
                                        : AppColors.textFaint,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  a.isActive
                                      ? 'Showing until ${a.expiresAt.day}/${a.expiresAt.month}'
                                      : 'Expired',
                                  style: AppText.caption.copyWith(
                                    color: a.isActive
                                        ? AppColors.emerald
                                        : AppColors.textFaint,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline, size: 19),
                            color: AppColors.chevron,
                            tooltip: 'Delete',
                            onPressed: () => AnnouncementRepository.delete(
                                widget.masjid.id, a.id),
                          ),
                        ],
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}
