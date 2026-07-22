import 'package:flutter/material.dart';
import '../models/masjid.dart';
import 'update_prayer_times_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  final List<Masjid> managedMasjids;
  const AdminDashboardScreen({super.key, required this.managedMasjids});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Prayer Time Dashboard'),
        backgroundColor: const Color(0xFF14532D),
        foregroundColor: Colors.white,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: widget.managedMasjids.length,
        itemBuilder: (context, index) {
          final masjid = widget.managedMasjids[index];
          final verified = masjid.verificationStatus == 'Verified';
          return Card(
            child: ListTile(
              leading: Icon(
                verified ? Icons.verified : Icons.hourglass_top,
                color: verified ? Colors.green : Colors.orange,
              ),
              title: Text(masjid.name, style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text('${masjid.city} • ${masjid.verificationStatus}'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () async {
                await Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => UpdatePrayerTimesScreen(masjid: masjid),
                  ),
                );
                setState(() {}); // refresh after returning from edit screen
              },
            ),
          );
        },
      ),
    );
  }
}
