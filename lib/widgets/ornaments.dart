import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Tiling eight-point girih star, drawn as a faint gold outline. This is the
/// only decorative texture in the app — it appears behind headers and nowhere
/// else. Drawn rather than bundled as an image so it stays crisp at any
/// density and costs nothing in app size.
class GirihPainter extends CustomPainter {
  const GirihPainter({this.tile = 52, this.opacity = 0.26});

  final double tile;
  final double opacity;

  @override
  void paint(Canvas canvas, Size size) {
    final Paint stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.9
      ..color = AppColors.gold.withOpacity(opacity);

    // One tile, defined on a 52-unit grid then scaled.
    final double k = tile / 52;
    final Path star = Path()
      ..moveTo(26 * k, 4 * k)
      ..lineTo(33 * k, 19 * k)
      ..lineTo(48 * k, 26 * k)
      ..lineTo(33 * k, 33 * k)
      ..lineTo(26 * k, 48 * k)
      ..lineTo(19 * k, 33 * k)
      ..lineTo(4 * k, 26 * k)
      ..lineTo(19 * k, 19 * k)
      ..close();

    canvas.save();
    canvas.clipRect(Offset.zero & size);
    for (double y = 0; y < size.height + tile; y += tile) {
      for (double x = 0; x < size.width + tile; x += tile) {
        canvas.save();
        canvas.translate(x, y);
        canvas.drawPath(star, stroke);
        canvas.drawCircle(Offset(26 * k, 26 * k), 3 * k, stroke);
        canvas.restore();
      }
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant GirihPainter old) =>
      old.tile != tile || old.opacity != opacity;
}

/// The arch, and optionally the dome, at the top of a screen.
///
/// Geometry is hand-tuned on a 308 x 186 grid and scaled to whatever size the
/// widget gets, so proportions hold on every screen width. Don't edit the
/// numbers without re-checking on a narrow device.
class ArchHeaderPainter extends CustomPainter {
  const ArchHeaderPainter({required this.withDome});

  final bool withDome;

  static const Size _grid = Size(308, 186);

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / _grid.width, size.height / _grid.height);

    final Paint goldStroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..color = AppColors.goldRule;
    final Paint ivoryFill = Paint()..color = AppColors.ivory;

    // Two paths, not one: the fill needs to be closed, the outline must not
    // be, or a gold line is drawn across the bottom of the header.
    Path archPath() => Path()
      ..moveTo(78, 186)
      ..lineTo(78, 118)
      ..arcToPoint(const Offset(230, 118),
          radius: const Radius.circular(76), clockwise: true)
      ..lineTo(230, 186);

    canvas.drawPath(archPath()..close(), ivoryFill);
    canvas.drawPath(archPath(), goldStroke);

    if (withDome) {
      final Path dome = Path()
        ..moveTo(132, 186)
        ..lineTo(132, 122)
        ..cubicTo(118, 96, 148, 88, 154, 74)
        ..cubicTo(160, 88, 190, 96, 176, 122)
        ..lineTo(176, 186)
        ..close();
      canvas.drawPath(dome, Paint()..color = AppColors.emerald);

      canvas.drawLine(
        const Offset(154, 74),
        const Offset(154, 60),
        Paint()
          ..color = AppColors.gold
          ..strokeWidth = 2.5
          ..strokeCap = StrokeCap.round,
      );
      canvas.drawCircle(
        const Offset(154, 56),
        4,
        Paint()..color = AppColors.gold,
      );
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant ArchHeaderPainter old) =>
      old.withDome != withDome;
}

/// White header panel with the girih watermark, the arch, and whatever content
/// is layered on top.
class IlluminatedHeader extends StatelessWidget {
  const IlluminatedHeader({
    super.key,
    required this.height,
    required this.child,
    this.withDome = false,
  });

  final double height;
  final bool withDome;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      width: double.infinity,
      child: Stack(
        children: <Widget>[
          const Positioned.fill(child: ColoredBox(color: AppColors.white)),
          const Positioned.fill(
            child: CustomPaint(painter: GirihPainter()),
          ),
          Positioned.fill(
            child: CustomPaint(
              painter: ArchHeaderPainter(withDome: withDome),
            ),
          ),
          Positioned.fill(child: child),
        ],
      ),
    );
  }
}

/// Gold hairline with a lozenge at its centre. Used above and below the
/// countdown, and nowhere that a plain rule would do.
class DiamondRule extends StatelessWidget {
  const DiamondRule({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        const Expanded(child: _Hairline()),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 9),
          child: Transform.rotate(
            angle: 0.785398, // 45°
            child: Container(width: 5, height: 5, color: AppColors.gold),
          ),
        ),
        const Expanded(child: _Hairline()),
      ],
    );
  }
}

class _Hairline extends StatelessWidget {
  const _Hairline();

  @override
  Widget build(BuildContext context) =>
      Container(height: 1, color: AppColors.goldRule);
}

/// Small-caps label with a rule running to the right edge.
class SectionRule extends StatelessWidget {
  const SectionRule({super.key, required this.label, this.trailingDiamond = false});

  final String label;
  final bool trailingDiamond;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Text(
          label.toUpperCase(),
          style: AppText.eyebrow.copyWith(color: AppColors.textMuted),
        ),
        const SizedBox(width: 9),
        const Expanded(child: _Hairline()),
        if (trailingDiamond) ...<Widget>[
          const SizedBox(width: 9),
          Transform.rotate(
            angle: 0.785398,
            child: Container(width: 5, height: 5, color: AppColors.gold),
          ),
        ],
      ],
    );
  }
}

class _OctagonPainter extends CustomPainter {
  const _OctagonPainter({required this.fill});

  final Color fill;

  @override
  void paint(Canvas canvas, Size size) {
    final double k = size.width / 34;
    final Path p = Path()
      ..moveTo(17 * k, 2 * k)
      ..lineTo(27 * k, 7 * k)
      ..lineTo(32 * k, 17 * k)
      ..lineTo(27 * k, 27 * k)
      ..lineTo(17 * k, 32 * k)
      ..lineTo(7 * k, 27 * k)
      ..lineTo(2 * k, 17 * k)
      ..lineTo(7 * k, 7 * k)
      ..close();

    canvas.drawPath(p, Paint()..color = fill);
    canvas.drawPath(
      p,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = AppColors.gold,
    );
  }

  @override
  bool shouldRepaint(covariant _OctagonPainter old) => old.fill != fill;
}

/// Gold-outlined octagon holding a number or an icon. The leading element on
/// every list row in the app, so rows across different screens line up.
class Medallion extends StatelessWidget {
  const Medallion({
    super.key,
    this.label,
    this.icon,
    this.size = 32,
    this.filled = false,
    this.dimmed = false,
  }) : assert(label != null || icon != null, 'A medallion needs a label or an icon.');

  final String? label;
  final IconData? icon;
  final double size;

  /// Emerald ground with pale gold content — used for the Hadith books.
  final bool filled;

  /// Ivory ground with muted content — used for unbuilt Guide rows.
  final bool dimmed;

  @override
  Widget build(BuildContext context) {
    final Color ground =
        filled ? AppColors.emerald : (dimmed ? AppColors.ivory : AppColors.white);
    final Color content = filled
        ? AppColors.goldPale
        : (dimmed ? AppColors.chevron : AppColors.emerald);

    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _OctagonPainter(fill: ground),
        child: Center(
          child: label != null
              ? Text(
                  label!,
                  style: TextStyle(
                    fontFamily: AppFonts.sans,
                    fontSize: size * 0.36,
                    color: content,
                  ),
                )
              : Icon(icon, size: size * 0.5, color: content),
        ),
      ),
    );
  }
}
