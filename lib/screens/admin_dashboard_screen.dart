import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/masjid.dart';
import '../services/admin_contact.dart';
import '../services/app_strings.dart';
import '../services/auth_service.dart';
import '../services/masjid_repository.dart';
import '../services/timing_reminder_service.dart';
import '../theme/app_theme.dart';
import '../widgets/timing_review_status.dart';
import 'announcement_admin_screen.dart';
import 'home_screen.dart';
import 'transfer_administration_screen.dart';
import 'update_prayer_times_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  final String adminMobile;
  const AdminDashboardScreen({super.key, required this.adminMobile});
  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> with WidgetsBindingObserver {
  late final Stream<List<Masjid>> _masjids;
  @override
  void initState() {
    super.initState();
    _masjids = MasjidRepository.streamByAdminMobile(widget.adminMobile);
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) TimingReminderService.enable(widget.adminMobile, requestPermission: true);
    });
  }
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) TimingReminderService.enable(widget.adminMobile);
  }
  @override
  void dispose() { WidgetsBinding.instance.removeObserver(this); super.dispose(); }
  Future<void> _logout() async {
    final ok = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(
      title: Text(S.tr('Log Out?', 'لاگ آؤٹ کریں؟')),
      content: Text(S.tr('You will need to sign in again to manage your masjid.', 'مسجد کا انتظام کرنے کے لیے دوبارہ لاگ ان کرنا ہوگا۔')),
      actions: [TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(S.tr('Cancel', 'منسوخ'))),
        TextButton(onPressed: () => Navigator.pop(ctx, true), child: Text(S.tr('Log Out', 'لاگ آؤٹ')))]));
    if (ok != true) return;
    await TimingReminderService.disable();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('admin_mobile');
    await AuthService.signOutAdmin();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (_) => const HomeScreen()), (_) => false);
  }
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(S.tr('Masjid Dashboard', 'مسجد ڈیش بورڈ')),
      actions: [IconButton(tooltip: S.tr('Log Out', 'لاگ آؤٹ'), onPressed: _logout, icon: const Icon(Icons.logout, size: 20))]),
    body: StreamBuilder<List<Masjid>>(stream: _masjids, builder: (context, snapshot) {
      if (snapshot.hasError) return Center(child: Text(S.tr('Could not load masjids. Please try again.', 'مساجد لوڈ نہیں ہو سکیں۔ دوبارہ کوشش کریں۔')));
      if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
      final masjids = snapshot.data!;
      if (masjids.isEmpty) return Center(child: Text(S.tr('No masjids found for this account.', 'اس اکاؤنٹ کے لیے کوئی مسجد نہیں ملی۔')));
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) TimingReminderService.enable(widget.adminMobile);
      });
      return ListView.separated(padding: const EdgeInsets.all(16), itemCount: masjids.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final m = masjids[index];
          final canManage = AdminContact.owns(m, AuthService.currentUser);
          return Card(margin: EdgeInsets.zero, shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12), side: BorderSide(color: AppColors.goldRule)),
            child: Padding(padding: const EdgeInsets.all(14), child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Icon(m.verificationStatus == 'Verified' ? Icons.verified_outlined : Icons.hourglass_top,
                    size: 20, color: AppColors.emerald),
                  const SizedBox(width: 10),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(m.name, style: TextStyle(fontFamily: AppFonts.sans, fontSize: 14,
                      fontWeight: FontWeight.w600, color: AppColors.text)),
                    const SizedBox(height: 4),
                    Text('${m.city} · ${m.verificationStatus}', style: AppText.caption.copyWith(color: AppColors.textMid)),
                    TimingReviewStatus(masjid: m),
                    if (!canManage) Text(S.tr('Awaiting Platform Admin approval.', 'پلیٹ فارم ایڈمن کی منظوری کا انتظار ہے۔'),
                      style: AppText.caption.copyWith(color: AppColors.textMid)),
                  ])),
                  if (canManage) IconButton(tooltip: S.tr('Announcements', 'اعلانات'),
                    icon: Icon(Icons.campaign_outlined, size: 20, color: AppColors.emerald),
                    onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => AnnouncementAdminScreen(masjid: m)))),
                ]),
                const SizedBox(height: 12),
                OutlinedButton.icon(onPressed: !canManage ? null : () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => UpdatePrayerTimesScreen(masjid: m))),
                  icon: const Icon(Icons.schedule, size: 17), label: Text(S.tr('Edit Prayer Times', 'نماز کے اوقات تبدیل کریں'))),
                Row(children: [
                  Icon(Icons.people_outline, size: 14, color: AppColors.textMid), const SizedBox(width: 5),
                  Expanded(child: Text('${m.followerCount} ${S.tr('followers', 'فالوورز')}',
                    style: AppText.caption.copyWith(color: AppColors.textMid))),
                  TextButton(onPressed: !canManage ? null : () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => TransferAdministrationScreen(masjid: m))),
                    child: Text(S.tr('Transfer Ownership', 'انتظام منتقل کریں'), style: const TextStyle(fontSize: 11))),
                ]),
              ])));
        });
    }));
}
