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
    setState(() {
      _loading = true;
      _error = null;
    });
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
      backgroundColor: const Color(0xFF0B1F14),
      appBar: AppBar(
        title: const Text('Qibla Direction'),
        backgroundColor: const Color(0xFF14532D),
        foregroundColor: Colors.white,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Colors.white))
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(_error!, textAlign: TextAlign.center, style: const TextStyle(color: Colors.redAccent)),
                        const SizedBox(height: 16),
                        ElevatedButton(onPressed: _findQiblaDirection, child: const Text('Try Again')),
                      ],
                    ),
                  ),
                )
              : StreamBuilder<CompassEvent>(
                  stream: FlutterCompass.events,
                  builder: (context, snapshot) {
                    if (!snapshot.hasData || snapshot.data!.heading == null) {
                      return const Center(
                        child: Text('Compass not available on this device.', style: TextStyle(color: Colors.white70)),
                      );
                    }
                    final heading = snapshot.data!.heading!;
                    // Angle to rotate the Kaaba marker so it points at
                    // Qibla relative to the phone's current heading.
                    var relativeAngle = _qiblaBearing! - heading;
                    relativeAngle = (relativeAngle + 360) % 360;
                    final isAligned = relativeAngle < 5 || relativeAngle > 355;

                    return Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '${_distanceKm!.toStringAsFixed(0)} km to Makkah',
                          style: const TextStyle(fontSize: 16, color: Colors.white70),
                        ),
                        const SizedBox(height: 8),
                        AnimatedOpacity(
                          opacity: isAligned ? 1 : 0,
                          duration: const Duration(milliseconds: 250),
                          child: const Text(
                            '✓ Facing Qibla',
                            style: TextStyle(color: Color(0xFFD4AF37), fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                        ),
                        const SizedBox(height: 20),
                        SizedBox(
                          width: 280,
                          height: 280,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              // Static outer dial with N/E/S/W - this dial
                              // rotates opposite to phone heading so North
                              // always points to true North visually.
                              AnimatedRotation(
                                turns: -heading / 360,
                                duration: const Duration(milliseconds: 150),
                                curve: Curves.easeOut,
                                child: Container(
                                  width: 280,
                                  height: 280,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: isAligned ? const Color(0xFFD4AF37) : Colors.white24,
                                      width: 3,
                                    ),
                                  ),
                                  child: Stack(
                                    children: [
                                      _compassLabel('N', Alignment.topCenter),
                                      _compassLabel('E', Alignment.centerRight),
                                      _compassLabel('S', Alignment.bottomCenter),
                                      _compassLabel('W', Alignment.centerLeft),
                                    ],
                                  ),
                                ),
                              ),
                              // Kaaba marker rotates to point at Qibla.
                              AnimatedRotation(
                                turns: relativeAngle / 360,
                                duration: const Duration(milliseconds: 150),
                                curve: Curves.easeOut,
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      width: 52,
                                      height: 52,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: isAligned ? const Color(0xFFD4AF37) : Colors.white54,
                                          width: 2,
                                        ),
                                      ),
                                      child: ClipOval(
                                        child: Image.asset('assets/images/kaaba_qibla.jpg', fit: BoxFit.cover),
                                      ),
                                    ),
                                    Container(
                                      width: 4,
                                      height: 100,
                                      color: isAligned ? const Color(0xFFD4AF37) : Colors.white54,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'Heading: ${heading.toStringAsFixed(0)}°  •  Qibla: ${_qiblaBearing!.toStringAsFixed(0)}°',
                          style: const TextStyle(color: Colors.white54, fontSize: 13),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Hold your phone flat and turn until the Kaaba icon\npoints straight up.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.white54, fontSize: 13),
                        ),
                      ],
                    );
                  },
                ),
    );
  }

  Widget _compassLabel(String label, Alignment alignment) {
    return Align(
      alignment: alignment,
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Text(
          label,
          style: TextStyle(
            color: label == 'N' ? const Color(0xFFD4AF37) : Colors.white70,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}
