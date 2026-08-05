import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
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
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Prayer Time Dashboard'),
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
                  trailing: const Icon(Icons.chevron_right),
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
