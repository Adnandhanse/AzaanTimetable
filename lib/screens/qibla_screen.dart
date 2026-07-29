import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:geolocator/geolocator.dart';

/// The Kaaba's coordinates - fixed, well-established location.
const double _kaabaLat = 21.4225;
const double _kaabaLng = 39.8262;

class QiblaScreen extends StatefulWidget {
  const QiblaScreen({super.key});

  @override
  State<QiblaScreen> createState() => _QiblaScreenState();
}

class _QiblaScreenState extends State<QiblaScreen> {
  double? _qiblaBearing;
  double? _distanceKm;
  String? _error;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _findQiblaDirection();
  }

  Future<void> _findQiblaDirection() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
        throw Exception('Location permission is needed to find Qibla direction.');
      }
      if (!await Geolocator.isLocationServiceEnabled()) {
        throw Exception('Please turn on Location/GPS on your phone.');
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 20),
      );

      final bearing = _calculateQiblaBearing(position.latitude, position.longitude);
      final distance = Geolocator.distanceBetween(
            position.latitude,
            position.longitude,
            _kaabaLat,
            _kaabaLng,
          ) /
          1000;

      if (!mounted) return;
      setState(() {
        _qiblaBearing = bearing;
        _distanceKm = distance;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  /// Great-circle initial bearing from the user's location to the Kaaba.
  double _calculateQiblaBearing(double lat, double lng) {
    final lat1 = lat * pi / 180;
    final lat2 = _kaabaLat * pi / 180;
    final deltaLng = (_kaabaLng - lng) * pi / 180;

    final y = sin(deltaLng) * cos(lat2);
    final x = cos(lat1) * sin(lat2) - sin(lat1) * cos(lat2) * cos(deltaLng);
    var bearing = atan2(y, x) * 180 / pi;
    bearing = (bearing + 360) % 360;
    return bearing;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Qibla Direction'),
        backgroundColor: const Color(0xFF14532D),
        foregroundColor: Colors.white,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(_error!, textAlign: TextAlign.center, style: const TextStyle(color: Colors.red)),
                        const SizedBox(height: 16),
                        ElevatedButton(onPressed: _findQiblaDirection, child: const Text('Try Again')),
                      ],
                    ),
                  ),
                )
              : StreamBuilder<CompassEvent>(
                  stream: FlutterCompass.events,
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const Center(child: Text('Compass not available on this device.'));
                    }
                    final heading = snapshot.data!.heading ?? 0;
                    final angle = ((_qiblaBearing! - heading) * pi / 180);

                    return Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Distance to Makkah: ${_distanceKm!.toStringAsFixed(0)} km',
                          style: const TextStyle(fontSize: 16, color: Colors.grey),
                        ),
                        const SizedBox(height: 30),
                        SizedBox(
                          width: 260,
                          height: 260,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              Container(
                                width: 260,
                                height: 260,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(color: const Color(0xFF14532D), width: 3),
                                ),
                              ),
                              const Positioned(top: 12, child: Text('N', style: TextStyle(fontWeight: FontWeight.bold))),
                              Transform.rotate(
                                angle: angle,
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.mosque, size: 40, color: Color(0xFFD4AF37)),
                                    Container(width: 4, height: 90, color: const Color(0xFFD4AF37)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 30),
                        const Text(
                          'Rotate your phone flat until the Kaaba icon points up',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey),
                        ),
                      ],
                    );
                  },
                ),
    );
  }
}
