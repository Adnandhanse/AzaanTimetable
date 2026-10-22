import 'package:flutter/material.dart';
import '../models/prophet_story.dart';

/// An illustrative regional diagram, not a GPS map or a birthplace database.
/// Only locations explicitly associated with cited accounts are selectable.
class ProphetPlacesMap extends StatelessWidget {
  const ProphetPlacesMap({super.key, required this.stories, required this.onOpen});
  final List<ProphetStory> stories;
  final ValueChanged<ProphetStory> onOpen;
  static const _places = <_StoryPlace>[
    _StoryPlace('Misr', .16, .31, 'Quran 12:21; 10:87', ['yusuf', 'musa', 'harun'],
      'Yusuf, Musa aur Harun Alaihimus Salam ke waqiat se mutalliq ilaqa.'),
    _StoryPlace('Hijr / Thamud', .48, .32, 'Quran 7:73; 15:80–84', ['salih'],
      'Thamud aur paharon mein tarashe hue gharon ka zikr. Exact ghar ya paidaish ka maqam nahi.'),
    _StoryPlace('Madinah', .51, .51, 'Quran 9:100; 59:9 · Sahih al-Bukhari 3930', ['muhammad'],
      'Hijrat ke baad Muhajirin aur Ansar ki zindagi se mutalliq ilaqa.'),
    _StoryPlace('Makkah', .42, .69, 'Sahih al-Bukhari 3364; Quran 48:24', ['ibrahim', 'ismail', 'muhammad'],
      'Ibrahim aur Ismail Alaihimus Salam ke waqiat aur Muhammad ﷺ ki seerat se mutalliq.'),
    _StoryPlace('Saba', .55, .87, 'Quran 27:22–44', ['sulayman'],
      'Saba ki malika aur Sulayman Alaihis Salam ke paigham ka waqia; unki paidaish ka dawa nahi.'),
    _StoryPlace('Al-Ahqaf', .82, .77, 'Quran 46:21', ['hud'],
      'Hud Alaihis Salam ki qaum ke liye Quran mein Al-Ahqaf ka zikr. Exact hudood is khake se tay nahi hotin.'),
  ];
  void _choose(BuildContext context, _StoryPlace p) {
    final matches = stories.where((s) => p.ids.contains(s.id)).toList();
    showModalBottomSheet<void>(context: context, isScrollControlled: true,
      builder: (ctx) => SafeArea(child: SingleChildScrollView(
        padding: const EdgeInsets.all(24), child: Column(mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Text(p.name, style: const TextStyle(fontFamily: 'Inter', fontSize: 22, fontWeight: FontWeight.w600)),
            const SizedBox(height: 10), Text(p.note, style: const TextStyle(fontSize: 14, height: 1.7)),
            const SizedBox(height: 8), Text(p.reference, style: const TextStyle(fontSize: 12, color: Color(0xFF85662D))),
            const SizedBox(height: 16),
            for (final story in matches) ListTile(contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.menu_book_outlined), title: Text(story.name),
              subtitle: Text('${story.pages.length} hisse'), trailing: const Icon(Icons.chevron_right),
              onTap: () { Navigator.pop(ctx); onOpen(story); }),
          ]))));
  }
  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
    const Text('Anbiya ke waqiat aur ilaqe', style: TextStyle(fontFamily: 'Inter', fontSize: 20, fontWeight: FontWeight.w600)),
    const SizedBox(height: 8),
    const Text('Circle par tap karke kahani kholein. Yeh ilaqon ka khaka hai, paidaish ya safar ka exact naqsha nahi.',
      style: TextStyle(fontSize: 13, height: 1.65)),
    const SizedBox(height: 16),
    ClipRRect(borderRadius: BorderRadius.circular(24), child: ColoredBox(color: const Color(0xFFEEE1C5),
      child: LayoutBuilder(builder: (ctx, size) {
        final height = size.maxWidth * 1.45;
        return SizedBox(height: height, child: Stack(children: [
          const Positioned.fill(child: CustomPaint(painter: _PlacesPainter())),
          for (final place in _places) Positioned(left: place.x * (size.maxWidth - 92),
            top: place.y * (height - 100), width: 92, child: Semantics(button: true,
              label: '${place.name}: kahaniyan kholein', child: InkWell(
                borderRadius: BorderRadius.circular(18), onTap: () => _choose(context, place),
                child: Column(children: [
                  Container(width: 48, height: 48, decoration: BoxDecoration(
                    color: const Color(0xFF254A43), shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFFD4AE61), width: 2)),
                    child: const Icon(Icons.menu_book_outlined, color: Color(0xFFFFEAC1), size: 22)),
                  const SizedBox(height: 5), Container(padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
                    decoration: BoxDecoration(color: const Color(0xFFF9F1DD), borderRadius: BorderRadius.circular(8)),
                    child: Text(place.name, textAlign: TextAlign.center,
                      style: const TextStyle(color: Color(0xFF332D22), fontSize: 12, fontWeight: FontWeight.w600))),
                ])))),
          const Positioned(top: 16, left: 16, child: Text('WAQIAT KA KHAKA',
            style: TextStyle(color: Color(0xFF75613D), fontSize: 10, letterSpacing: 1.5))),
        ]));
      }))),
    const SizedBox(height: 12),
    const Text('Baqi Anbiya ki exact jagah yahan mark nahi ki gayi. Sabhi 25 ki kahaniyan neeche maujood hain.',
      style: TextStyle(fontSize: 12, height: 1.6)),
  ]);
}
class _StoryPlace {
  const _StoryPlace(this.name, this.x, this.y, this.reference, this.ids, this.note);
  final String name, reference, note;
  final double x, y;
  final List<String> ids;
}
class _PlacesPainter extends CustomPainter {
  const _PlacesPainter();
  @override
  void paint(Canvas canvas, Size size) {
    canvas.save(); canvas.scale(size.width, size.height);
    final sea = Paint()..color = const Color(0xFFB4CDCA);
    // Stylised Mediterranean, Nile and Red Sea; no political borders or
    // archaeological precision is implied by this hand-drawn illustration.
    canvas.drawPath(Path()..moveTo(0, .04)..lineTo(.62, .04)..quadraticBezierTo(.55, .18, .35, .15)
      ..quadraticBezierTo(.18, .17, 0, .23)..close(), sea);
    canvas.drawPath(Path()..moveTo(.22, .24)..quadraticBezierTo(.25, .48, .22, .68)
      ..lineTo(.235, .69)..quadraticBezierTo(.27, .46, .24, .24)..close(), sea);
    canvas.drawPath(Path()..moveTo(.35, .28)..quadraticBezierTo(.43, .50, .59, .93)
      ..lineTo(.64, .96)..quadraticBezierTo(.53, .62, .40, .32)..close(), sea);
    canvas.drawPath(Path()..moveTo(.71, .14)..quadraticBezierTo(.76, .27, .98, .35)
      ..lineTo(1, .43)..quadraticBezierTo(.82, .36, .71, .14)..close(), sea);
    final sand = Paint()..color = const Color(0x337D643D)..style = PaintingStyle.stroke..strokeWidth = .002;
    for (var i = 0; i < 6; i++) {
      final y = .34 + i * .09;
      canvas.drawPath(Path()..moveTo(.68, y)..quadraticBezierTo(.81, y - .04, .95, y + .025), sand);
    }
    canvas.restore();
  }
  @override
  bool shouldRepaint(covariant _PlacesPainter oldDelegate) => false;
}
