import 'package:flutter/material.dart';
import 'home_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/app_theme.dart';
import 'announcement_admin_screen.dart';
import '../models/masjid.dart';
import '../services/masjid_repository.dart';
import 'update_prayer_times_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  final String adminMobile;
  const AdminDashboardScreen({super.key, required this.adminMobile});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  static String _updatedLabel(DateTime? t) {
    if (t == null) return 'Times never updated';
    final d = DateTime.now().difference(t);
    if (d.inMinutes < 60) return 'Updated just now';
    if (d.inHours < 24) return 'Updated ${d.inHours}h ago';
    if (d.inDays == 1) return 'Updated yesterday';
    if (d.inDays < 30) return 'Updated ${d.inDays} days ago';
    final months = d.inDays ~/ 30;
    return 'Updated $months month${months == 1 ? '' : 's'} ago';
  }

  /// Amber past a month, red past three. Prayer times drift with the seasons,
  /// so "not touched since spring" is a real problem rather than a cosmetic one.
  static Color _staleColour(DateTime? t) {
    if (t == null) return const Color(0xFFB3261E);
    final days = DateTime.now().difference(t).inDays;
    if (days >= 90) return const Color(0xFFB3261E);
    if (days >= 30) return AppColors.gold;
    return AppColors.textMuted;
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
          if (masjids.isEmpty) {
            return const Center(child: Text('No masjids found for this number.'));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: masjids.length,
            itemBuilder: (context, index) {
              final masjid = masjids[index];
              final verified = masjid.verificationStatus == 'Verified';
              return Card(
                child: ListTile(
                  leading: Icon(verified ? Icons.verified : Icons.hourglass_top, color: verified ? Colors.green : Colors.orange),
                  title: Text(masjid.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                  // Follower count is the number an imam actually wants: how
                  // many people are relying on the times he keeps. It is a
                  // count only — the app holds no record of WHO follows him.
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${masjid.city} • ${masjid.verificationStatus}'),
                      const SizedBox(height: 2),
                      // How long since the times were touched. The number an
                      // admin needs to see is not "when did I last log in" but
                      // "are my times still right" — and a masjid whose times
                      // were last edited in Ramadan is the one to chase.
                      Row(
                        children: [
                          Icon(Icons.update,
                              size: 14,
                              color: _staleColour(masjid.timesUpdatedAt)),
                          const SizedBox(width: 5),
                          Text(
                            _updatedLabel(masjid.timesUpdatedAt),
                            style: AppText.caption.copyWith(
                                color: _staleColour(masjid.timesUpdatedAt)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          const Icon(Icons.people_outline,
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
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute(
                              builder: (_) =>
                                  AnnouncementAdminScreen(masjid: masjid)),
                        ),
                      ),
                      const Icon(Icons.chevron_right),
                    ],
                  ),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => UpdatePrayerTimesScreen(masjid: masjid)),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
