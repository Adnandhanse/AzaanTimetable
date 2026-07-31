import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:geolocator/geolocator.dart';
import '../theme/app_theme.dart';
import '../widgets/ornaments.dart';

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
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        throw Exception('Location permission is needed to find Qibla direction.');
      }
      if (!await Geolocator.isLocationServiceEnabled()) {
        throw Exception('Please turn on Location/GPS on your phone.');
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 20),
      );

      final bearing =
          _calculateQiblaBearing(position.latitude, position.longitude);
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
      appBar: AppBar(title: const Text('Qibla')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _buildError()
              : StreamBuilder<CompassEvent>(
                  stream: FlutterCompass.events,
                  builder: (context, snapshot) {
                    if (!snapshot.hasData || snapshot.data!.heading == null) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(28),
                          child: Text(
                            'Compass not available on this device.',
                            textAlign: TextAlign.center,
                            style: AppText.body
                                .copyWith(color: AppColors.textMuted),
                          ),
                        ),
                      );
                    }
                    final heading = snapshot.data!.heading!;
                    var relativeAngle = _qiblaBearing! - heading;
                    relativeAngle = (relativeAngle + 360) % 360;
                    final isAligned = relativeAngle < 5 || relativeAngle > 355;

                    return SingleChildScrollView(
                      child: Column(
                        children: [
                          const SizedBox(height: 18),
                          // Centred in a fixed square. The dial was
                          // drifting because the Column was stretching it.
                          Center(
                            child: _CompassDial(
                              headingTurns: -heading / 360,
                              qiblaTurns: relativeAngle / 360,
                              isAligned: isAligned,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            '${_qiblaBearing!.toStringAsFixed(0)}°',
                            style:
                                AppText.hero.copyWith(color: AppColors.emerald),
                          ),
                          Text(
                            _cardinalName(_qiblaBearing!).toUpperCase(),
                            style: AppText.eyebrow.copyWith(
                              fontSize: 12,
                              letterSpacing: 1.5,
                              color: AppColors.textMuted,
                            ),
                          ),
                          const SizedBox(height: 10),
                          AnimatedOpacity(
                            opacity: isAligned ? 1 : 0,
                            duration: const Duration(milliseconds: 250),
                            child: Container(
                              decoration: BoxDecoration(
                                color: AppColors.emerald,
                                borderRadius: BorderRadius.circular(3),
                              ),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 6),
                              child: Text(
                                'FACING QIBLA',
                                style: AppText.eyebrow
                                    .copyWith(color: AppColors.goldPale),
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                            child: Column(
                              children: [
                                const DiamondRule(),
                                const SizedBox(height: 14),
                                Row(
                                  children: [
                                    Expanded(
                                      child: _Stat(
                                        label: 'To Makkah',
                                        value:
                                            '${_distanceKm!.toStringAsFixed(0)} km',
                                      ),
                                    ),
                                    Container(
                                        width: 1,
                                        height: 34,
                                        color: AppColors.goldRule),
                                    Expanded(
                                      child: _Stat(
                                        label: 'Heading',
                                        value:
                                            '${heading.toStringAsFixed(0)}°',
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 18),
                                Text(
                                  'Hold your phone flat and turn until the Kaaba points straight up.',
                                  textAlign: TextAlign.center,
                                  style: AppText.caption
                                      .copyWith(color: AppColors.textMuted),
                                ),
                                const SizedBox(height: 24),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Medallion(icon: Icons.location_off_outlined, size: 52),
            const SizedBox(height: 16),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: AppText.body.copyWith(color: AppColors.textMuted),
            ),
            const SizedBox(height: 18),
            OutlinedButton(
              onPressed: _findQiblaDirection,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.emerald,
                side: const BorderSide(color: AppColors.gold),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4)),
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                textStyle: AppText.body,
              ),
              child: const Text('Try again'),
            ),
          ],
        ),
      ),
    );
  }

  String _cardinalName(double bearing) {
    const List<String> names = <String>[
      'North',
      'North east',
      'East',
      'South east',
      'South',
      'South west',
      'West',
      'North west',
    ];
    final int index = (((bearing + 22.5) % 360) / 45).floor();
    return names[index % 8];
  }
}

/// The compass.
///
/// The Kaaba photograph stays **upright and static** in the centre. Only the
/// rose ring and the qibla pointer rotate. Spinning a photograph of the Kaaba
/// upside down as the phone turns would look wrong, so the rose is drawn in
/// code around it instead of being baked into the image.
class _CompassDial extends StatelessWidget {
  const _CompassDial({
    required this.headingTurns,
    required this.qiblaTurns,
    required this.isAligned,
  });

  /// Negative heading — the rose turns opposite the phone so North stays north.
  final double headingTurns;

  /// Where the qibla is, relative to the phone.
  final double qiblaTurns;

  final bool isAligned;

  static const double _size = 300;
  static const double _medallion = 168;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: _size,
      height: _size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Rose: ticks and cardinals, rotating against the heading.
          AnimatedRotation(
            turns: headingTurns,
            duration: const Duration(milliseconds: 150),
            curve: Curves.easeOut,
            child: CustomPaint(
              size: const Size(_size, _size),
              painter: _RosePainter(isAligned: isAligned),
            ),
          ),

          // The Kaaba, upright, centred, never rotated.
          Container(
            width: _medallion,
            height: _medallion,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: isAligned ? AppColors.gold : AppColors.goldRule,
                width: isAligned ? 3 : 1.6,
              ),
            ),
            child: ClipOval(
              child: Image.asset(
                'assets/images/kaaba_dial.webp',
                fit: BoxFit.cover,
                semanticLabel: 'Photograph of the Kaaba',
              ),
            ),
          ),

          // Qibla pointer, rotating to the bearing. This is the only thing on
          // screen that tells you which way to face, so nothing else should
          // compete with it.
          AnimatedRotation(
            turns: qiblaTurns,
            duration: const Duration(milliseconds: 150),
            curve: Curves.easeOut,
            child: SizedBox(
              width: _size,
              height: _size,
              child: Align(
                alignment: Alignment.topCenter,
                child: Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: CustomPaint(
                    size: const Size(22, 28),
                    painter: _PointerPainter(isAligned: isAligned),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PointerPainter extends CustomPainter {
  const _PointerPainter({required this.isAligned});

  final bool isAligned;

  @override
  void paint(Canvas canvas, Size size) {
    final Path p = Path()
      ..moveTo(size.width / 2, 0)
      ..lineTo(size.width, size.height)
      ..lineTo(size.width / 2, size.height * 0.74)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(
      p,
      Paint()..color = isAligned ? AppColors.gold : AppColors.emerald,
    );
  }

  @override
  bool shouldRepaint(covariant _PointerPainter old) =>
      old.isAligned != isAligned;
}

/// Ticks every 6 degrees, longer every 30, with serif cardinals. Transparent
/// centre — the Kaaba medallion sits inside it.
class _RosePainter extends CustomPainter {
  const _RosePainter({required this.isAligned});

  final bool isAligned;

  @override
  void paint(Canvas canvas, Size size) {
    final Offset c = Offset(size.width / 2, size.height / 2);
    final double r = size.width / 2;

    canvas.drawCircle(
      c,
      r - 30,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = isAligned ? 2.4 : 1.4
        ..color = isAligned ? AppColors.gold : AppColors.goldRule,
    );

    final Paint minor = Paint()
      ..strokeWidth = 0.9
      ..color = const Color(0xFFDFD3B4);
    final Paint major = Paint()
      ..strokeWidth = 1.4
      ..color = AppColors.gold;

    for (int d = 0; d < 360; d += 6) {
      final bool isMajor = d % 30 == 0;
      final double a = (d - 90) * pi / 180;
      final double inner = isMajor ? r - 24 : r - 20;
      final double outer = r - 14;
      canvas.drawLine(
        c + Offset(cos(a) * inner, sin(a) * inner),
        c + Offset(cos(a) * outer, sin(a) * outer),
        isMajor ? major : minor,
      );
    }

    _cardinal(canvas, size, 'N', const Offset(0, -1), AppColors.emerald);
    _cardinal(canvas, size, 'S', const Offset(0, 1), AppColors.textMuted);
    _cardinal(canvas, size, 'E', const Offset(1, 0), AppColors.textMuted);
    _cardinal(canvas, size, 'W', const Offset(-1, 0), AppColors.textMuted);
  }

  void _cardinal(
      Canvas canvas, Size size, String letter, Offset dir, Color colour) {
    final TextPainter tp = TextPainter(
      text: TextSpan(
        text: letter,
        style: TextStyle(
          fontFamily: AppFonts.serif,
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: colour,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    final Offset centre = Offset(size.width / 2, size.height / 2);
    final double radius = size.width / 2 - 6;
    final Offset at = centre +
        Offset(dir.dx * radius, dir.dy * radius) -
        Offset(tp.width / 2, tp.height / 2);
    tp.paint(canvas, at);
  }

  @override
  bool shouldRepaint(covariant _RosePainter old) => old.isAligned != isAligned;
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label.toUpperCase(),
          style: AppText.eyebrow
              .copyWith(letterSpacing: 1.3, color: AppColors.textMuted),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: AppText.listTime.copyWith(fontSize: 20, color: AppColors.text),
        ),
      ],
    );
  }
}
