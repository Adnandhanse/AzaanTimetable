import 'package:flutter/material.dart';
import '../models/masjid.dart';
import '../services/masjid_repository.dart';
import 'masjid_details_screen.dart';

class MasjidSearchScreen extends StatefulWidget {
  const MasjidSearchScreen({super.key});

  @override
  State<MasjidSearchScreen> createState() => _MasjidSearchScreenState();
}

class _MasjidSearchScreenState extends State<MasjidSearchScreen> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Search Masjid'),
        backgroundColor: const Color(0xFF14532D),
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              decoration: const InputDecoration(
                hintText: 'Search by masjid name or city',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: (v) => setState(() => _query = v),
            ),
          ),
          Expanded(
            child: StreamBuilder<List<Masjid>>(
              stream: MasjidRepository.streamAll(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final all = snapshot.data!;
                final filtered = _query.isEmpty
                    ? all
                    : all.where((m) =>
                        m.name.toLowerCase().contains(_query.toLowerCase()) ||
                        m.city.toLowerCase().contains(_query.toLowerCase())).toList();

                if (filtered.isEmpty) {
                  return const Center(child: Text('No masjids found'));
                }
                return ListView.builder(
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final masjid = filtered[index];
                    return ListTile(
                      leading: const Icon(Icons.mosque, color: Color(0xFF14532D)),
                      title: Text(masjid.name),
                      subtitle: Text('${masjid.city} • ${masjid.verificationStatus}'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () async {
                        final selected = await Navigator.of(context).push<bool>(
                          MaterialPageRoute(builder: (_) => MasjidDetailsScreen(masjid: masjid)),
                        );
                        if (selected == true && context.mounted) {
                          Navigator.of(context).pop(masjid);
                        }
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
