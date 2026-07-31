import 'dart:math' as math;
import 'dart:ui' show PathOperation;

import 'package:flutter/material.dart';

/// Which time of day to show. Driven by the masjid's own prayer times rather
/// than raw clock hours, so it matches what the masjid actually announces and
/// stays correct in any city or season.
enum SkyPhase {
  /// Fajr → Dhuhr. Warm light, glow rising on the left, birds crossing.
  morning,

  /// Dhuhr → Asr. Cool overhead light, nothing moving. Deliberately still.
  midday,

  /// Asr → Isha. Amber light, glow sinking on the right, birds crossing back.
  evening,

  /// Isha → Fajr. Darkened, stars, crescent.
  night,
}

/// The Home header picture: the Masjid an-Nabawi photograph with the time of day
/// animated **on top of it**.
///
/// Why on top and not behind: the photograph has its own golden-hour sky with
/// detailed cloud structure, and the minarets have intricate silhouettes. Any
/// automatic sky mask would come out ragged around them, so the sun cannot rise
/// *through* the image. Instead the crop is tight to the architecture — very
/// little sky is in frame — and the animation reads as changing light on the
/// building rather than a changing sky.
///
/// Evening looks native, because the source photograph is already golden hour.
/// Midday is the weakest of the four, because it is cooling down a warm image.
class SkyArtwork extends StatefulWidget {
  const SkyArtwork({
    super.key,
    required this.phase,
    this.height = 200,
  });

  final SkyPhase phase;
  final double height;

  @override
  State<SkyArtwork> createState() => _SkyArtworkState();
}

class _SkyArtworkState extends State<SkyArtwork>
    with TickerProviderStateMixin {
  /// One-shot: the glow travels into position when the screen opens, so opening
  /// the app at dawn shows a sunrise rather than a sun already parked.
  late final AnimationController _entry;

  /// Continuous: birds crossing, stars twinkling. Flutter mutes tickers when the
  /// app is backgrounded, so this does not run in your pocket.
  late final AnimationController _loop;

  late final List<_Star> _stars;

  @override
  void initState() {
    super.initState();
    _entry = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2600),
    )..forward();
    _loop = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 16),
    )..repeat();

    // Fixed seed. Home rebuilds every second from the clock timer, and
    // unseeded stars would leap to new positions once a second.
    final math.Random rnd = math.Random(7);
    _stars = List<_Star>.generate(
      30,
      (int i) => _Star(
        dx: rnd.nextDouble(),
        dy: rnd.nextDouble() * 0.46,
        radius: 0.6 + rnd.nextDouble() * 1.2,
        phase: rnd.nextDouble() * math.pi * 2,
      ),
    );
  }

  @override
  void didUpdateWidget(SkyArtwork oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Crossing into a new phase replays the glow's travel, so leaving the app
    // open across Maghrib actually shows the light go down.
    if (oldWidget.phase != widget.phase) {
      _entry
        ..reset()
        ..forward();
    }
  }

  @override
  void dispose() {
    _entry.dispose();
    _loop.dispose();
    super.dispose();
  }

  /// How strongly to tint the photograph, per phase. Evening is lightest
  /// because the source image is already this colour; night is heaviest
  /// because it has to turn day into night.
  static const Map<SkyPhase, (Color, Color, double)> _wash =
      <SkyPhase, (Color, Color, double)>{
    SkyPhase.morning: (Color(0xFFFFC98A), Color(0xFFFFE9C9), 0.26),
    SkyPhase.midday: (Color(0xFF9CC6E8), Color(0xFFE6F2FA), 0.30),
    SkyPhase.evening: (Color(0xFFF0A25A), Color(0xFFFFD9A0), 0.16),
    SkyPhase.night: (Color(0xFF0B1630), Color(0xFF24365C), 0.62),
  };

  @override
  Widget build(BuildContext context) {
    final Curve glowCurve = widget.phase == SkyPhase.evening
        ? Curves.easeInCubic // setting: gathers speed as it drops
        : Curves.easeOutCubic; // rising: slows as it climbs

    final (Color top, Color bottom, double strength) w = _wash[widget.phase]!;

    return RepaintBoundary(
      child: SizedBox(
        height: widget.height,
        width: double.infinity,
        child: Stack(
          fit: StackFit.expand,
          children: <Widget>[
            // The photograph. bottomCenter so the plaza line never moves and
            // only sky crops on short screens. Never BoxFit.fill.
            Image.asset(
              'assets/images/nabawi_header.webp',
              fit: BoxFit.cover,
              alignment: Alignment.bottomCenter,
              semanticsLabel: 'Photograph of Masjid an-Nabawi',
              frameBuilder: (_, Widget child, int? frame, bool wasSync) {
                if (wasSync || frame != null) return child;
                // Without this the header flashes white on first launch.
                return const ColoredBox(color: Color(0xFFF3EDDD));
              },
            ),

            // Time-of-day wash.
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: <Color>[
                    w.$1.withOpacity(w.$3),
                    w.$2.withOpacity(w.$3 * 0.55),
                  ],
                ),
              ),
            ),

            // Travelling glow, stars, crescent.
            AnimatedBuilder(
              animation: Listenable.merge(<Listenable>[_entry, _loop]),
              builder: (BuildContext context, Widget? _) => CustomPaint(
                painter: _LightPainter(
                  phase: widget.phase,
                  glowT: glowCurve.transform(_entry.value),
                  loopT: _loop.value,
                  stars: _stars,
                ),
              ),
            ),

            // Birds, only at the two phases that asked for them.
            if (widget.phase == SkyPhase.morning ||
                widget.phase == SkyPhase.evening)
              AnimatedBuilder(
                animation: _loop,
                builder: (BuildContext context, Widget? _) => CustomPaint(
                  painter: _BirdsPainter(
                    t: _loop.value,
                    rightToLeft: widget.phase == SkyPhase.evening,
                    dark: false,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _Star {
  const _Star({
    required this.dx,
    required this.dy,
    required this.radius,
    required this.phase,
  });

  /// Fractions of width and height, so stars scale with the header.
  final double dx;
  final double dy;
  final double radius;

  /// Offset into the twinkle cycle, so they do not all pulse together.
  final double phase;
}

class _LightPainter extends CustomPainter {
  const _LightPainter({
    required this.phase,
    required this.glowT,
    required this.loopT,
    required this.stars,
  });

  final SkyPhase phase;

  /// 0 → start of the glow's travel, 1 → settled.
  final double glowT;

  /// 0..1, continuous. Drives twinkle.
  final double loopT;

  final List<_Star> stars;

  @override
  void paint(Canvas canvas, Size size) {
    if (phase == SkyPhase.night) {
      _paintStars(canvas, size);
      _paintCrescent(canvas, size);
      return;
    }
    _paintGlow(canvas, size);
  }

  void _paintGlow(Canvas canvas, Size size) {
    // A switch expression returning a record: same result as assigning late
    // finals inside a switch, without the assignment-analysis edge cases.
    final (Offset from, Offset to, Color colour, double strength) g =
        switch (phase) {
      // Up out of the horizon on the left.
      SkyPhase.morning => (
          Offset(size.width * 0.20, size.height * 1.05),
          Offset(size.width * 0.24, size.height * 0.40),
          const Color(0xFFFFD79A),
          0.55,
        ),
      // Overhead and still.
      SkyPhase.midday => (
          Offset(size.width * 0.5, size.height * 0.10),
          Offset(size.width * 0.5, size.height * 0.10),
          const Color(0xFFFFF6DC),
          0.40,
        ),
      // Down to the horizon on the right, where the photograph's own sun is,
      // so the two reinforce each other instead of fighting.
      SkyPhase.evening => (
          Offset(size.width * 0.78, size.height * 0.34),
          Offset(size.width * 0.86, size.height * 0.86),
          const Color(0xFFFFB765),
          0.60,
        ),
      SkyPhase.night => (Offset.zero, Offset.zero, Colors.transparent, 0.0),
    };

    final Offset c = Offset.lerp(g.$1, g.$2, glowT)!;
    final double r = size.height * 0.62;

    // Radial falloff rather than a hard disc — this is light on a photograph,
    // not a cartoon sun pasted over one.
    canvas.drawCircle(
      c,
      r,
      Paint()
        ..shader = RadialGradient(
          colors: <Color>[
            g.$3.withOpacity(g.$4),
            g.$3.withOpacity(g.$4 * 0.35),
            g.$3.withOpacity(0.0),
          ],
          stops: const <double>[0.0, 0.42, 1.0],
        ).createShader(Rect.fromCircle(center: c, radius: r)),
    );

    // A small bright core, but only while it is clear of the horizon.
    if (phase != SkyPhase.midday) {
      final double coreOpacity = phase == SkyPhase.morning
          ? glowT.clamp(0.0, 1.0)
          : (1.0 - glowT).clamp(0.0, 1.0) * 0.8 + 0.2;
      canvas.drawCircle(
        c,
        size.height * 0.055,
        Paint()..color = g.$3.withOpacity(0.75 * coreOpacity),
      );
    }
  }

  void _paintStars(Canvas canvas, Size size) {
    final Paint p = Paint();
    for (final _Star s in stars) {
      // Slow sine twinkle, each star offset so the sky shimmers rather than
      // blinking in unison.
      final double tw =
          0.40 + 0.60 * (0.5 + 0.5 * math.sin(loopT * math.pi * 2 + s.phase));
      canvas.drawCircle(
        Offset(s.dx * size.width, s.dy * size.height),
        s.radius,
        p..color = const Color(0xFFFFF8E4).withOpacity(tw * 0.95),
      );
    }
  }

  void _paintCrescent(Canvas canvas, Size size) {
    final Offset c = Offset(size.width * 0.80, size.height * 0.22);
    final double r = size.height * 0.070;

    canvas.drawCircle(
      c,
      r * 3.0,
      Paint()..color = const Color(0xFFE8EEF8).withOpacity(0.10),
    );

    // A disc with a second disc punched out of it.
    final Path crescent = Path.combine(
      PathOperation.difference,
      Path()..addOval(Rect.fromCircle(center: c, radius: r)),
      Path()
        ..addOval(Rect.fromCircle(
          center: Offset(c.dx + r * 0.46, c.dy - r * 0.24),
          radius: r * 0.92,
        )),
    );
    canvas.drawPath(crescent, Paint()..color = const Color(0xFFF6EDD2));
  }

  @override
  bool shouldRepaint(covariant _LightPainter old) =>
      old.phase != phase || old.glowT != glowT || old.loopT != loopT;
}

class _BirdsPainter extends CustomPainter {
  const _BirdsPainter({
    required this.t,
    required this.rightToLeft,
    required this.dark,
  });

  final double t;

  /// Evening birds head the other way — coming home rather than setting out.
  final bool rightToLeft;

  /// Light birds on a dark image, dark birds on a light one.
  final bool dark;

  /// Offset within the loop, vertical band, size, bob speed.
  static const List<List<double>> _flock = <List<double>>[
    <double>[0.00, 0.16, 1.00, 1.0],
    <double>[0.13, 0.26, 0.78, 1.4],
    <double>[0.22, 0.10, 0.60, 1.8],
    <double>[0.56, 0.21, 0.88, 1.1],
    <double>[0.68, 0.31, 0.68, 1.6],
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final Paint stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..color = (dark ? const Color(0xFFFFF3DC) : const Color(0xFF4A4136))
          .withOpacity(0.62);

    for (final List<double> b in _flock) {
      // Travel from just off one edge to just off the other.
      final double p = (t + b[0]) % 1.0;
      final double x = rightToLeft
          ? size.width * (1.15 - p * 1.3)
          : size.width * (p * 1.3 - 0.15);

      // Gentle bob so the flock does not look pasted on.
      final double bob = math.sin(p * math.pi * 2 * b[3]) * size.height * 0.020;
      final double y = size.height * b[1] + bob;

      final double w = 9.0 * b[2];
      stroke.strokeWidth = 1.7 * b[2];

      // Two strokes forming a wide shallow "m", which is all a distant bird is.
      final Path wing = Path()
        ..moveTo(x - w, y)
        ..quadraticBezierTo(x - w * 0.5, y - w * 0.62, x, y)
        ..quadraticBezierTo(x + w * 0.5, y - w * 0.62, x + w, y);
      canvas.drawPath(wing, stroke);
    }
  }

  @override
  bool shouldRepaint(covariant _BirdsPainter old) =>
      old.t != t || old.rightToLeft != rightToLeft || old.dark != dark;
}
