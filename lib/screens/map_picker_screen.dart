import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

/// Lets the admin visually confirm/adjust their masjid's exact location
/// on a free map (OpenStreetMap - no Google billing needed), the same
/// way ride-hailing/delivery apps get precise pins: the user pans the
/// map under a fixed center marker rather than trusting reverse-geocoded
/// text alone.
class MapPickerScreen extends StatefulWidget {
  final double initialLatitude;
  final double initialLongitude;

  const MapPickerScreen({super.key, required this.initialLatitude, required this.initialLongitude});

  @override
  State<MapPickerScreen> createState() => _MapPickerScreenState();
}

class _MapPickerScreenState extends State<MapPickerScreen> {
  late final MapController _mapController;
  late LatLng _center;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _center = LatLng(widget.initialLatitude, widget.initialLongitude);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Confirm Exact Location'),
        backgroundColor: const Color(0xFF14532D),
        foregroundColor: Colors.white,
      ),
      body: Stack(
        alignment: Alignment.center,
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _center,
              initialZoom: 18,
              onPositionChanged: (position, hasGesture) {
                if (position.center != null) {
                  _center = position.center!;
                }
              },
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.masjid_alarm_app',
              ),
            ],
          ),
          // Fixed center pin - the map moves underneath it, like Google Maps'
          // "confirm location" flow.
          const Padding(
            padding: EdgeInsets.only(bottom: 40),
            child: Icon(Icons.location_pin, size: 48, color: Color(0xFFD4AF37)),
          ),
          Positioned(
            top: 12,
            left: 16,
            right: 16,
            child: Card(
              color: Colors.white.withOpacity(0.95),
              child: const Padding(
                padding: EdgeInsets.all(10),
                child: Text(
                  'Move the map so the pin sits exactly on your masjid, then confirm.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13),
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 24,
            left: 16,
            right: 16,
            child: SizedBox(
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF14532D)),
                onPressed: () => Navigator.of(context).pop(_center),
                child: const Text('Confirm This Location', style: TextStyle(color: Colors.white, fontSize: 16)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
