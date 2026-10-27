import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'package:geolocator/geolocator.dart';
import '../models/masjid.dart';
import '../utils/masjid_display.dart';
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
                hintText: 'Search by Name, Area or City',
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
                        ? 'Finding Your Location...'
                        : _userPosition == null
                            ? 'Find Nearby Masjid'
                            : 'Sorted by Distance ✓'),
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
                if (snapshot.hasError) {
                  return const Center(child: Padding(padding: EdgeInsets.all(24),
                    child: Text('Could not load masjids. Please check your connection and try again.',
                      textAlign: TextAlign.center)));
                }
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                var all = List<Masjid>.of(snapshot.data!);
                final query = _query.trim().toLowerCase();
                if (query.isNotEmpty) {
                  all = all
                      .where((m) =>
                          m.name.toLowerCase().contains(query) ||
                          m.address.toLowerCase().contains(query) ||
                          m.city.toLowerCase().contains(query))
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
                final bool nearbyOnly = _userPosition != null && query.isEmpty;
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
                    final distanceText = _userPosition != null
                        ? '${_distanceKm(masjid).toStringAsFixed(1)} km Away'
                        : null;
                    return ListTile(
                      leading: Icon(Icons.mosque, color: AppColors.emerald),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      title: Text(MasjidDisplay.name(masjid.name),
                        style: TextStyle(fontFamily: AppFonts.sans, fontSize: 14,
                          fontWeight: FontWeight.w600, height: 1.35, color: AppColors.text)),
                      subtitle: Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(MasjidDisplay.address(masjid.address, masjid.city),
                            maxLines: 2, overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontFamily: AppFonts.sans, fontSize: 13,
                              height: 1.45, color: AppColors.textMid)),
                          const SizedBox(height: 8),
                          Wrap(spacing: 12, runSpacing: 6, crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(color: AppColors.emerald.withOpacity(0.10),
                                  borderRadius: BorderRadius.circular(6)),
                                child: Row(mainAxisSize: MainAxisSize.min, children: [
                                  Icon(Icons.verified_outlined, size: 14, color: AppColors.emerald),
                                  const SizedBox(width: 4),
                                  Text(masjid.verificationStatus,
                                    style: TextStyle(fontFamily: AppFonts.sans, fontSize: 11,
                                      fontWeight: FontWeight.w600, color: AppColors.textMid)),
                                ]),
                              ),
                              if (distanceText != null) Text(distanceText,
                                style: TextStyle(fontSize: 12, color: AppColors.textMid)),
                            ]),
                        ]),
                      ),
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
