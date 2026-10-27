import 'package:flutter/material.dart';
import '../models/prophet_story.dart';
import '../data/prophet_map_land.dart';
import '../services/app_strings.dart';
import '../theme/app_theme.dart';

/// Geographic coastline from Natural Earth, styled as a parchment atlas.
/// Markers describe regions associated with cited accounts, NOT birthplaces.
class ProphetPlacesMap extends StatelessWidget {
  const ProphetPlacesMap(
      {super.key, required this.stories, required this.onOpen});
  final List<ProphetStory> stories;
  final ValueChanged<ProphetStory> onOpen;
  static const _places = <_StoryPlace>[
    _StoryPlace('Misr', 'Yusuf · Musa\nHarun\nAlaihimus Salam', 30.8, 28.5, .17,
        .34, 'Quran 12:21; 10:87', ['yusuf', 'musa', 'harun']),
    _StoryPlace('Al-Hijr', 'Salih\nAlaihis Salam', 37.95, 26.8, .55, .32,
        'Quran 7:73; 15:80–84', ['salih']),
    _StoryPlace('Yathrib', 'Muhammad ﷺ', 39.61, 24.47, .70, .52,
        'Quran 33:13; 9:100; 59:9 · Sahih al-Bukhari 3930', ['muhammad']),
    _StoryPlace(
        'Makkah',
        'Ibrahim · Ismail\nAlaihimus Salam\nMuhammad ﷺ',
        39.86,
        21.42,
        .37,
        .69,
        'Sahih al-Bukhari 3364; Quran 48:24',
        ['ibrahim', 'ismail', 'muhammad']),
    _StoryPlace('Saba', 'Sulayman\nAlaihis Salam', 45.3, 15.4, .64, .88,
        'Quran 27:22–44', ['sulayman']),
    _StoryPlace('Al-Ahqaf', 'Hud\nAlaihis Salam', 50.0, 18.0, .87, .72,
        'Quran 46:21', ['hud']),
  ];
  void _choose(BuildContext context, _StoryPlace p) {
    final matches = stories.where((s) => p.ids.contains(s.id));
    showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        builder: (ctx) => SafeArea(
            child: SingleChildScrollView(
                padding: const EdgeInsets.all(22),
                child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(p.name,
                          style: AppText.screenTitle
                              .copyWith(color: AppColors.text)),
                      const SizedBox(height: 8),
                      Text(
                          S.tr(
                              'An approximate region associated with these accounts. This marker does not identify a birthplace or an exact historical boundary.',
                              'ان واقعات سے متعلق تقریبی علاقہ۔ یہ نشان مقامِ پیدائش یا تاریخی سرحد کا تعین نہیں کرتا۔'),
                          style:
                              AppText.body.copyWith(color: AppColors.textMid)),
                      const SizedBox(height: 10),
                      Text(p.reference,
                          style: AppText.caption
                              .copyWith(color: AppColors.textMid)),
                      const SizedBox(height: 12),
                      for (final s in matches)
                        ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: Icon(Icons.menu_book_outlined,
                                color: AppColors.emerald),
                            title: Text(s.name),
                            subtitle: Text(
                                '${s.pages.length} ${S.tr('chapters', 'حصے')}'),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: () {
                              Navigator.pop(ctx);
                              onOpen(s);
                            }),
                    ]))));
  }

  @override
  Widget build(BuildContext context) =>
      Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Text(S.tr('A journey through the lands', 'سرزمینوں کا سفر'),
            style: AppText.rowTitle.copyWith(color: AppColors.text)),
        const SizedBox(height: 6),
        Text(
            S.tr('Tap a name to explore. Pinch to zoom.',
                'کہانی کے لیے نام دبائیں۔ نقشہ بڑا کر سکتے ہیں۔'),
            style: AppText.caption.copyWith(color: AppColors.textMid)),
        const SizedBox(height: 12),
        ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: AspectRatio(
                aspectRatio: .80,
                child: LayoutBuilder(
                    builder: (ctx, size) => InteractiveViewer(
                        minScale: 1,
                        maxScale: 3,
                        child: Stack(children: [
                          const Positioned.fill(
                              child: CustomPaint(painter: _AtlasPainter())),
                          for (final p in _places)
                            Positioned(
                                left: p.x * (size.maxWidth - 80),
                                top: p.y * (size.maxHeight - 88),
                                width: 80,
                                child: Semantics(
                                    button: true,
                                    label:
                                        '${p.name}: ${p.names.replaceAll('\n', ' ')}',
                                    child: InkWell(
                                        onTap: () => _choose(context, p),
                                        borderRadius: BorderRadius.circular(44),
                                        child: Container(
                                            constraints: const BoxConstraints(
                                                minHeight: 80),
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 5, vertical: 10),
                                            decoration: BoxDecoration(
                                                color: const Color(0xFFF9F0D9),
                                                shape: BoxShape.circle,
                                                border: Border.all(
                                                    color:
                                                        const Color(0xFF94723F),
                                                    width: 1.3),
                                                boxShadow: const [
                                                  BoxShadow(
                                                      color: Color(0x25000000),
                                                      blurRadius: 7,
                                                      offset: Offset(0, 3))
                                                ]),
                                            child: Column(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Text(p.name,
                                                      textAlign:
                                                          TextAlign.center,
                                                      style: const TextStyle(
                                                          fontFamily: 'Inter',
                                                          color:
                                                              Color(0xFF674821),
                                                          fontSize: 10,
                                                          fontWeight:
                                                              FontWeight.w700)),
                                                  const SizedBox(height: 4),
                                                  Text(p.names,
                                                      textAlign:
                                                          TextAlign.center,
                                                      style: const TextStyle(
                                                          fontFamily: 'Inter',
                                                          color:
                                                              Color(0xFF352E22),
                                                          fontSize: 9,
                                                          height: 1.4)),
                                                ]))))),
                        ]))))),
        const SizedBox(height: 8),
        Text(
            S.tr(
                'Geographic coastlines • Traditional place names • Approximate regions, not birthplaces',
                'جغرافیائی ساحل • روایتی نام • تقریبی علاقے، مقامِ پیدائش نہیں'),
            style: AppText.caption.copyWith(color: AppColors.textMid)),
      ]);
}

class _StoryPlace {
  const _StoryPlace(this.name, this.names, this.longitude, this.latitude,
      this.x, this.y, this.reference, this.ids);
  final String name, names, reference;
  final double longitude, latitude, x, y;
  final List<String> ids;
}

class _AtlasPainter extends CustomPainter {
  const _AtlasPainter();
  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
        Offset.zero & size,
        Paint()
          ..shader = const LinearGradient(
                  colors: [Color(0xFF93B1AE), Color(0xFFBDD0BF)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight)
              .createShader(Offset.zero & size));
    final land = Paint()..color = const Color(0xFFE5D1A8);
    final edge = Paint()
      ..color = const Color(0xFF9F8D65)
      ..style = PaintingStyle.stroke
      ..strokeWidth = .9;
    for (final ring in prophetMapLand) {
      final path = Path();
      for (var i = 0; i < ring.length; i++) {
        final p = Offset(ring[i].dx * size.width, ring[i].dy * size.height);
        if (i == 0) {
          path.moveTo(p.dx, p.dy);
        } else {
          path.lineTo(p.dx, p.dy);
        }
      }
      path.close();
      canvas.drawPath(path, land);
      canvas.drawPath(path, edge);
    }
    final grid = Paint()
      ..color = const Color(0x18765B35)
      ..strokeWidth = .5;
    for (var i = 1; i < 8; i++) {
      canvas.drawLine(Offset(size.width * i / 8, 0),
          Offset(size.width * i / 8, size.height), grid);
      canvas.drawLine(Offset(0, size.height * i / 8),
          Offset(size.width, size.height * i / 8), grid);
    }
    // Thin leaders tie the readable story circles to their geographical anchors.
    for (final p in ProphetPlacesMap._places) {
      final anchor = Offset((p.longitude - 23) / 39 * size.width,
          (42 - p.latitude) / 32 * size.height);
      final label =
          Offset(p.x * (size.width - 80) + 40, p.y * (size.height - 88) + 40);
      canvas.drawLine(
          anchor,
          label,
          Paint()
            ..color = const Color(0x887A6038)
            ..strokeWidth = 1);
      canvas.drawCircle(anchor, 2.5, Paint()..color = const Color(0xFF6C502C));
    }
    void label(String text, double x, double y, {double angle = 0}) {
      final tp = TextPainter(
          text: TextSpan(
              text: text,
              style: const TextStyle(
                  fontFamily: 'Inter',
                  color: Color(0xFF64583E),
                  fontSize: 9,
                  letterSpacing: 1.4,
                  fontWeight: FontWeight.w500)),
          textDirection: TextDirection.ltr)
        ..layout();
      canvas.save();
      canvas.translate(size.width * x, size.height * y);
      canvas.rotate(angle);
      tp.paint(canvas, Offset.zero);
      canvas.restore();
    }

    label('BILAD AL-SHAM', .34, .17);
    label('AL-HIJAZ', .42, .57, angle: .55);
    label('BAHR AL-QULZUM', .25, .54, angle: 1.0);
    label('ARABIAN SEA', .68, .96);
    label('N', .92, .07);
    canvas.drawLine(Offset(size.width * .93, size.height * .06),
        Offset(size.width * .93, size.height * .035), edge);
  }

  @override
  bool shouldRepaint(covariant _AtlasPainter oldDelegate) => false;
}
