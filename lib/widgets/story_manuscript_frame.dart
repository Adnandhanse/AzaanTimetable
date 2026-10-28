import 'package:flutter/material.dart';

/// Thin manuscript-inspired rules, with geometric corners. No figures or text.
/// Foreground decoration ignores taps and never changes chapter dimensions.
class StoryManuscriptFrame extends CustomPainter {
  const StoryManuscriptFrame();
  @override
  void paint(Canvas canvas, Size size) {
    if (size.width < 80 || size.height < 80) return;
    final line = Paint()
      ..color = const Color(0xB8D9B56E)
      ..style = PaintingStyle.stroke
      ..strokeWidth = .8;
    final rect = Rect.fromLTWH(7, 7, size.width - 14, size.height - 14);
    canvas.drawRRect(RRect.fromRectAndRadius(rect, const Radius.circular(18)), line);
    // Mirrored, open geometric corner ornaments remain outside the text inset.
    for (final x in [false, true]) {
      for (final y in [false, true]) {
        canvas.save();
        canvas.translate(x ? size.width : 0, y ? size.height : 0);
        canvas.scale(x ? -1.0 : 1.0, y ? -1.0 : 1.0);
        final corner = Path()
          ..moveTo(14, 44)..lineTo(14, 24)..lineTo(24, 14)..lineTo(44, 14)
          ..moveTo(18, 34)..lineTo(18, 25)..lineTo(25, 18)..lineTo(34, 18);
        canvas.drawPath(corner, line);
        canvas.drawPath(Path()..moveTo(24, 20)..lineTo(28, 24)
          ..lineTo(24, 28)..lineTo(20, 24)..close(), line);
        canvas.restore();
      }
    }
    for (final y in [12.0, size.height - 12]) {
      final mid = size.width / 2;
      canvas.drawLine(Offset(mid - 32, y), Offset(mid - 9, y), line);
      canvas.drawLine(Offset(mid + 9, y), Offset(mid + 32, y), line);
      canvas.drawPath(Path()..moveTo(mid, y - 3)..lineTo(mid + 4, y)
        ..lineTo(mid, y + 3)..lineTo(mid - 4, y)..close(), line);
    }
  }
  @override
  bool shouldRepaint(covariant StoryManuscriptFrame oldDelegate) => false;
}
