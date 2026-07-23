import 'package:flutter/material.dart';
import '../models/masjid.dart';
import '../services/masjid_repository.dart';
import '../services/auth_service.dart';
import 'super_admin_login_screen.dart';

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

  Future<void> _approve(Masjid m) async {
    await MasjidRepository.updateVerificationStatus(m.id, 'Verified');
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${m.name} approved and is now live.')));
  }

  Future<void> _reject(Masjid m) async {
    await MasjidRepository.updateVerificationStatus(m.id, 'Rejected');
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${m.name} rejected.')));
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
              return _buildList(snapshot.data!, showActions: true);
            },
          ),
          StreamBuilder<List<Masjid>>(
            stream: MasjidRepository.streamAll(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
              return _buildList(snapshot.data!, showActions: false);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildList(List<Masjid> masjids, {required bool showActions}) {
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
                  ],
                ),
                const SizedBox(height: 6),
                Text('${m.address}, ${m.city}', style: const TextStyle(color: Colors.grey)),
                const SizedBox(height: 4),
                Text('Admin: ${m.adminName} • ${m.adminMobile}', style: const TextStyle(color: Colors.grey, fontSize: 13)),
                if (m.registrationNo.isNotEmpty)
                  Text('Reg. No: ${m.registrationNo}', style: const TextStyle(color: Colors.grey, fontSize: 13)),
                if (showActions) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.close, color: Colors.red),
                          label: const Text('Reject', style: TextStyle(color: Colors.red)),
                          onPressed: () => _reject(m),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                          icon: const Icon(Icons.check, color: Colors.white),
                          label: const Text('Approve', style: TextStyle(color: Colors.white)),
                          onPressed: () => _approve(m),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}
