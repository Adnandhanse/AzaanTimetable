import 'package:flutter/material.dart';
import '../models/masjid.dart';
import '../services/masjid_repository.dart';
import '../services/auth_service.dart';
import 'super_admin_login_screen.dart';
import 'super_admin_masjid_detail_screen.dart';

class SuperAdminDashboardScreen extends StatefulWidget {
  const SuperAdminDashboardScreen({super.key});

  @override
  State<SuperAdminDashboardScreen> createState() => _SuperAdminDashboardScreenState();
}

class _SuperAdminDashboardScreenState extends State<SuperAdminDashboardScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Platform Admin'),
        backgroundColor: const Color(0xFF0B1F14),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: () async {
              await AuthService.signOutAdmin();
              if (!context.mounted) return;
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const SuperAdminLoginScreen()),
                (route) => false,
              );
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFFD4AF37),
          labelColor: Colors.white,
          tabs: const [Tab(text: 'Pending'), Tab(text: 'All Masjids')],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          StreamBuilder<List<Masjid>>(
            stream: MasjidRepository.streamPending(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
              return _buildList(snapshot.data!);
            },
          ),
          StreamBuilder<List<Masjid>>(
            stream: MasjidRepository.streamAll(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
              return _buildList(snapshot.data!);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildList(List<Masjid> masjids) {
    if (masjids.isEmpty) {
      return const Center(child: Text('Nothing here right now.', style: TextStyle(color: Colors.grey)));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: masjids.length,
      itemBuilder: (context, index) {
        final m = masjids[index];
        Color statusColor;
        switch (m.verificationStatus) {
          case 'Verified':
            statusColor = Colors.green;
            break;
          case 'Rejected':
            statusColor = Colors.red;
            break;
          default:
            statusColor = Colors.orange;
        }
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: InkWell(
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => SuperAdminMasjidDetailScreen(masjid: m)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.mosque, color: Color(0xFF14532D)),
                      const SizedBox(width: 8),
                      Expanded(child: Text(m.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16))),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(color: statusColor.withOpacity(0.15), borderRadius: BorderRadius.circular(6)),
                        child: Text(m.verificationStatus, style: TextStyle(color: statusColor, fontSize: 12, fontWeight: FontWeight.w600)),
                      ),
                      const Icon(Icons.chevron_right, color: Colors.grey),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text('${m.address}, ${m.city}', style: const TextStyle(color: Colors.grey)),
                  const SizedBox(height: 4),
                  Text('Admin: ${m.adminName} • ${m.adminMobile}', style: const TextStyle(color: Colors.grey, fontSize: 13)),
                  if (m.registrationNo.isNotEmpty)
                    Text('Reg. No: ${m.registrationNo}', style: const TextStyle(color: Colors.grey, fontSize: 13)),
                  if (m.customAzanAudioUrl != null)
                    const Padding(
                      padding: EdgeInsets.only(top: 4),
                      child: Row(
                        children: [
                          Icon(Icons.audiotrack, size: 14, color: Colors.grey),
                          SizedBox(width: 4),
                          Text('Custom Azan audio uploaded', style: TextStyle(color: Colors.grey, fontSize: 12)),
                        ],
                      ),
                    ),
                  const Padding(
                    padding: EdgeInsets.only(top: 6),
                    child: Text('Tap for full details, audio, and approval', style: TextStyle(color: Color(0xFF14532D), fontSize: 12)),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
