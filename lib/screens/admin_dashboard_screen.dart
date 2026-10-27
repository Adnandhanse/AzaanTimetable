import 'package:flutter/material.dart';
import 'home_screen.dart';
import '../services/timing_reminder_service.dart';
import '../services/admin_contact.dart';
import '../services/auth_service.dart';
import '../services/app_strings.dart';
import 'package:permission_handler/permission_handler.dart';
import '../widgets/timing_review_status.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/app_theme.dart';
import 'announcement_admin_screen.dart';
import '../models/masjid.dart';
import '../services/masjid_repository.dart';
import 'update_prayer_times_screen.dart';
import 'transfer_administration_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  final String adminMobile;
  const AdminDashboardScreen({super.key, required this.adminMobile});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen>
    with WidgetsBindingObserver {
  final Set<String> _confirming = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _enableReminders(requestPermission: true);
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed)
      _enableReminders(requestPermission: false);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> _enableReminders({bool requestPermission = true}) async {
    await TimingReminderService.enable(widget.adminMobile,
        requestPermission: requestPermission);
  }

  Future<void> _confirm(Masjid masjid) async {
    if (_confirming.contains(masjid.id)) return;
    setState(() => _confirming.add(masjid.id));
    try {
      await MasjidRepository.confirmPrayerTimes(masjid.id)
          .timeout(const Duration(seconds: 20));
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(S.tr(
                'Timings confirmed. The next check is due in 10 days.',
                'اوقات کی تصدیق ہو گئی۔ اگلا جائزہ دس دن بعد ہوگا۔'))));
    } catch (_) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(S.tr(
                'Could not save. Check your connection and try again.',
                'محفوظ نہیں ہو سکا۔ انٹرنیٹ دیکھ کر دوبارہ کوشش کریں۔'))));
    } finally {
      if (mounted) setState(() => _confirming.remove(masjid.id));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Prayer Time Dashboard'),
        actions: [
          // REQUIRED, now that the session persists.
          //
          // Without this an admin could never sign out — and on a shared phone,
          // or when a masjid changes who manages it, the previous admin would
          // stay signed in forever.
          IconButton(
            icon: const Icon(Icons.logout, size: 20),
            tooltip: 'Log out',
            onPressed: () async {
              final ok = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Log out?'),
                  content: const Text(
                      'You will need to enter your mobile number again to manage this masjid.'),
                  actions: [
                    TextButton(
                        onPressed: () => Navigator.of(ctx).pop(false),
                        child: const Text('Cancel')),
                    TextButton(
                        onPressed: () => Navigator.of(ctx).pop(true),
                        child: const Text('Log out')),
                  ],
                ),
              );
              if (ok != true) return;
              await TimingReminderService.disable();
              try {
                final prefs = await SharedPreferences.getInstance();
                await prefs.remove('admin_mobile');
              } catch (_) {}
              if (!context.mounted) return;
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const HomeScreen()),
                (route) => false,
              );
            },
          ),
        ],
      ),
      body: StreamBuilder<List<Masjid>>(
        stream: MasjidRepository.streamByAdminMobile(widget.adminMobile),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final masjids = snapshot.data!;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) TimingReminderService.enable(widget.adminMobile);
          });
          if (masjids.isEmpty) {
            return const Center(
                child: Text('No masjids found for this number.'));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: masjids.length,
            itemBuilder: (context, index) {
              final masjid = masjids[index];
              final verified = masjid.verificationStatus == 'Verified';
              final canManage =
                  AdminContact.owns(masjid, AuthService.currentUser);
              return Card(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    ListTile(
                      leading: Icon(
                          verified ? Icons.verified : Icons.hourglass_top,
                          color: verified ? Colors.green : Colors.orange),
                      title: Text(masjid.name,
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                      // Follower count is the number an imam actually wants: how
                      // many people are relying on the times he keeps. It is a
                      // count only — the app holds no record of WHO follows him.
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('${masjid.city} • ${masjid.verificationStatus}'),
                          if (!canManage)
                            const Text(
                                'Awaiting Platform Admin approval. Management becomes available after approval.'),
                          const SizedBox(height: 2),
                          // How long since the times were touched. The number an
                          // admin needs to see is not "when did I last log in" but
                          // "are my times still right" — and a masjid whose times
                          // were last edited in Ramadan is the one to chase.
                          TimingReviewStatus(masjid: masjid),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              Icon(Icons.people_outline,
                                  size: 14, color: AppColors.emerald),
                              const SizedBox(width: 5),
                              Text(
                                masjid.followerCount == 1
                                    ? '1 follower'
                                    : '${masjid.followerCount} followers',
                                style: AppText.caption
                                    .copyWith(color: AppColors.emerald),
                              ),
                            ],
                          ),
                        ],
                      ),
                      // Two things an admin does: change the times, and tell people
                      // something. Both reachable from the row rather than one
                      // being buried behind the other.
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.campaign_outlined, size: 20),
                            color: AppColors.gold,
                            tooltip: 'Announcements',
                            onPressed: !canManage
                                ? null
                                : () => Navigator.of(context).push(
                                      MaterialPageRoute(
                                          builder: (_) =>
                                              AnnouncementAdminScreen(
                                                  masjid: masjid)),
                                    ),
                          ),
                          const Icon(Icons.chevron_right),
                        ],
                      ),
                      onTap: !canManage
                          ? null
                          : () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                    builder: (_) => UpdatePrayerTimesScreen(
                                        masjid: masjid)),
                              );
                            },
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            OutlinedButton.icon(
                              icon: const Icon(Icons.check_circle_outline),
                              label: Text(_confirming.contains(masjid.id)
                                  ? S.tr('Saving…', 'محفوظ ہو رہا ہے…')
                                  : S.tr(
                                      'Timings Are Correct', 'اوقات درست ہیں')),
                              onPressed:
                                  !canManage || _confirming.contains(masjid.id)
                                      ? null
                                      : () => _confirm(masjid),
                            ),
                            if (canManage)
                              Padding(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 6),
                                  child: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Icon(Icons.notifications_none,
                                            size: 16,
                                            color: AppColors.textMuted),
                                        const SizedBox(width: 6),
                                        Expanded(
                                            child: Text(
                                                S.tr(
                                                    'Automatic check after 10 days; every 5 days until confirmed.',
                                                    'دس دن بعد خودکار یاددہانی؛ تصدیق تک ہر پانچ دن بعد۔'),
                                                style: AppText.caption.copyWith(
                                                    color: AppColors.textMid))),
                                      ])),
                            if (canManage)
                              ValueListenableBuilder<String>(
                                  valueListenable:
                                      TimingReminderService.deliveryState,
                                  builder: (context, status, _) {
                                    if (status == 'permission-required')
                                      return TextButton.icon(
                                          onPressed: () async {
                                            await openAppSettings();
                                          },
                                          icon: const Icon(
                                              Icons.settings_outlined,
                                              size: 16),
                                          label: Text(S.tr(
                                              'Allow Notifications in Phone Settings',
                                              'فون کی ترتیبات میں اطلاعات کی اجازت دیں')));
                                    if (status == 'retrying')
                                      return Padding(
                                          padding: const EdgeInsets.symmetric(
                                              vertical: 4),
                                          child: Text(
                                              S.tr(
                                                  'Connecting reminder delivery. Retrying automatically.',
                                                  'یاددہانی کے لیے رابطہ ہو رہا ہے۔ خودکار دوبارہ کوشش جاری ہے۔'),
                                              style: AppText.caption.copyWith(
                                                  color: AppColors.textMid)));
                                    if (status == 'pending-connection')
                                      return Padding(
                                          padding: const EdgeInsets.symmetric(
                                              vertical: 4),
                                          child: Text(
                                              S.tr(
                                                  'Reminder delivery is pending. We will retry when you reopen this screen.',
                                                  'یاددہانی کا رابطہ باقی ہے۔ صفحہ دوبارہ کھولنے پر کوشش ہوگی۔'),
                                              style: AppText.caption.copyWith(
                                                  color: AppColors.textMid)));
                                    return const SizedBox.shrink();
                                  }),
                          ]),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.emerald,
                          side: BorderSide(color: AppColors.emerald),
                          minimumSize: const Size.fromHeight(48),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 12),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        icon: const Icon(Icons.swap_horiz_rounded, size: 22),
                        label: const Text('Transfer ownership',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontWeight: FontWeight.w600)),
                        onPressed: !canManage
                            ? null
                            : () => Navigator.of(context).push(
                                MaterialPageRoute(
                                    builder: (_) =>
                                        TransferAdministrationScreen(
                                            masjid: masjid))),
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
