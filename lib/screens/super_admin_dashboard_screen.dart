import 'package:flutter/material.dart';
import 'package:cloud_functions/cloud_functions.dart';
import '../models/masjid.dart';
import '../widgets/timing_review_status.dart';
import '../services/masjid_repository.dart';
import '../services/auth_service.dart';
import 'super_admin_login_screen.dart';
import 'ownership_transfers_screen.dart';
import 'super_admin_masjid_detail_screen.dart';

class SuperAdminDashboardScreen extends StatefulWidget {
  const SuperAdminDashboardScreen({super.key});

  @override
  State<SuperAdminDashboardScreen> createState() => _SuperAdminDashboardScreenState();
}

class _SuperAdminDashboardScreenState extends State<SuperAdminDashboardScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  String _query = '';
  final Set<String> _sendingReminderFor = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _searchController.addListener(() {
      setState(() => _query = _searchController.text.trim().toLowerCase());
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// Name, city, address, registration number, admin name, admin mobile -
  /// whichever of these a platform admin is likely to actually have on hand
  /// when they're looking for one specific masjid instead of scrolling.
  List<Masjid> _filtered(List<Masjid> masjids) {
    if (_query.isEmpty) return masjids;
    return masjids.where((m) {
      return m.name.toLowerCase().contains(_query) ||
          m.city.toLowerCase().contains(_query) ||
          m.address.toLowerCase().contains(_query) ||
          m.registrationNo.toLowerCase().contains(_query) ||
          m.adminName.toLowerCase().contains(_query) ||
          m.adminMobile.contains(_query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Platform Admin'),
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
          indicatorColor: const Color(0xFFC8A86B),
          labelColor: Colors.white,
          tabs: const [Tab(text: 'Pending'), Tab(text: 'All Masjids')],
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                icon: const Icon(Icons.swap_horiz_rounded),
                label: const Text('Review Ownership Requests'),
                style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(48)),
                onPressed: () => Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => const OwnershipTransfersScreen())),
              ),
            ),
          ),
          // ONE search bar above both tabs, not duplicated per tab - a
          // platform admin looking for a specific masjid does not care
          // which tab it happens to be sitting in.
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search by name, city, registration no., admin...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _query.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => _searchController.clear(),
                      ),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                StreamBuilder<List<Masjid>>(
                  stream: MasjidRepository.streamPending(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                    return _buildList(_filtered(snapshot.data!));
                  },
                ),
                StreamBuilder<List<Masjid>>(
                  stream: MasjidRepository.streamAll(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                    return _buildList(_filtered(snapshot.data!));
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _sendTimingReminder(Masjid masjid) async {
    if (masjid.verificationStatus != 'Verified' ||
        _sendingReminderFor.contains(masjid.id)) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Send timing reminder?'),
        content: Text(
          'Send a prayer timing update reminder to the registered admin devices of ${masjid.name}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Send reminder'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _sendingReminderFor.add(masjid.id));
    try {
      final result = await FirebaseFunctions.instanceFor(region: 'us-central1')
          .httpsCallable('sendManualPrayerTimingReminder')
          .call({'masjidId': masjid.id});
      if (!mounted) return;
      final sent = (result.data is Map) ? result.data['sent'] as int? ?? 0 : 0;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(sent > 0
              ? 'Reminder sent to $sent device(s) for ${masjid.name}.'
              : 'No active registered admin devices found for ${masjid.name}.'),
        ),
      );
    } on FirebaseFunctionsException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message ?? 'Could not send reminder.')),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not send reminder. Please try again.')),
      );
    } finally {
      if (mounted) setState(() => _sendingReminderFor.remove(masjid.id));
    }
  }

  Widget _buildList(List<Masjid> masjids) {
    if (masjids.isEmpty) {
      return Center(
        child: Text(
          _query.isEmpty ? 'Nothing here right now.' : 'No masjid matches "${_searchController.text.trim()}".',
          style: const TextStyle(color: Colors.grey),
          textAlign: TextAlign.center,
        ),
      );
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
                      const Icon(Icons.mosque, color: Color(0xFF1F5E4A)),
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
                  TimingReviewStatus(masjid: m),
                  if (m.verificationStatus == 'Verified')
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton.icon(
                        onPressed: _sendingReminderFor.contains(m.id)
                            ? null
                            : () => _sendTimingReminder(m),
                        icon: _sendingReminderFor.contains(m.id)
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.notifications_active_outlined),
                        label: Text(_sendingReminderFor.contains(m.id)
                            ? 'Sending...'
                            : 'Send Reminder'),
                      ),
                    ),
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
                    child: Text('Tap for full details, audio, and approval', style: TextStyle(color: Color(0xFF1F5E4A), fontSize: 12)),
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
