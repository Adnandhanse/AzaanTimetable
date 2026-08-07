import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'package:geolocator/geolocator.dart';
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
  Position? _userPosition;
  bool _isFindingNearby = false;
  String? _locationError;

  Future<void> _findNearby() async {
    setState(() {
      _isFindingNearby = true;
      _locationError = null;
    });
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
        throw Exception('Location permission denied.');
      }
      if (!await Geolocator.isLocationServiceEnabled()) {
        throw Exception('Please turn on Location/GPS on your phone.');
      }
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
        timeLimit: const Duration(seconds: 20),
      );
      if (!mounted) return;
      setState(() {
        _userPosition = position;
        _isFindingNearby = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isFindingNearby = false;
        _locationError = e.toString();
      });
    }
  }

  double _distanceKm(Masjid m) {
    if (_userPosition == null) return 0;
    return Geolocator.distanceBetween(
          _userPosition!.latitude,
          _userPosition!.longitude,
          m.latitude,
          m.longitude,
        ) /
        1000;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Search Masjid'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: TextField(
              decoration: const InputDecoration(
                hintText: 'Search by masjid name or city',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: (v) => setState(() => _query = v),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    icon: _isFindingNearby
                        ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.my_location),
                    label: Text(_isFindingNearby
                        ? 'Finding you...'
                        : _userPosition == null
                            ? 'Find Nearby Masjid'
                            : 'Sorted by distance ✓'),
                    onPressed: _isFindingNearby ? null : _findNearby,
                  ),
                ),
              ],
            ),
          ),
          if (_locationError != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Text(_locationError!, style: const TextStyle(color: Colors.red, fontSize: 12)),
            ),
          const SizedBox(height: 8),
          Expanded(
            child: StreamBuilder<List<Masjid>>(
              stream: MasjidRepository.streamVerified(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                var all = snapshot.data!;
                if (_query.isNotEmpty) {
                  all = all
                      .where((m) =>
                          m.name.toLowerCase().contains(_query.toLowerCase()) ||
                          m.city.toLowerCase().contains(_query.toLowerCase()))
                      .toList();
                }
                // WITHIN 7 km, nearest first.
                //
                // Only applied when browsing. A TYPED SEARCH IS NOT FILTERED BY
                // DISTANCE — someone searching by name is usually looking for a
                // specific masjid, often one they are travelling to, and hiding
                // it because it is 9 km away would look like the app does not
                // have it.
                //
                // Also skipped when there is no location fix, since with no
                // position every masjid would be filtered out and the list
                // would come back empty for no visible reason.
                final bool nearbyOnly = _userPosition != null && _query.isEmpty;
                if (_userPosition != null) {
                  if (nearbyOnly) {
                    all = all.where((m) => _distanceKm(m) <= 7.0).toList();
                  }
                  all.sort((a, b) => _distanceKm(a).compareTo(_distanceKm(b)));
                }

                if (all.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(28),
                      child: Text(
                        nearbyOnly
                            // Says WHY the list is empty and what to do, rather
                            // than implying no masjid exists anywhere.
                            ? 'No masjids registered within 7 km. Search by name to look further afield.'
                            : 'No masjids found',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  );
                }
                return ListView.builder(
                  itemCount: all.length,
                  itemBuilder: (context, index) {
                    final masjid = all[index];
                    final distanceText = _userPosition != null ? ' • ${_distanceKm(masjid).toStringAsFixed(1)} km away' : '';
                    return ListTile(
                      leading: Icon(Icons.mosque, color: AppColors.emerald),
                      title: Text(masjid.name),
                      // NO FOLLOWER COUNT HERE.
                      //
                      // It is the imam's number, not a public one. On a search
                      // list it turns choosing a masjid into a popularity
                      // contest, and quietly tells people which masjids are
                      // poorly attended. It stays on the admin dashboard.
                      subtitle: Text(
                          '${masjid.city} • ${masjid.verificationStatus}$distanceText'),
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
