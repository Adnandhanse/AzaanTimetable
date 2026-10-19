import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// All bundled story scenes are 1536 x 1024. Keep that ratio in the reader
/// and library instead of cropping a landscape into a portrait thumbnail.
class ProphetStoryArtwork extends StatelessWidget {
  const ProphetStoryArtwork({super.key, required this.image,
    required this.title, this.subtitle});
  final String image, title;
  final String? subtitle;
  @override
  Widget build(BuildContext context) => Column(children: [
    AspectRatio(aspectRatio: 1.5, child: Stack(fit: StackFit.expand, children: [
      Image.asset(image, fit: BoxFit.contain, cacheWidth: 900,
        excludeFromSemantics: true,
        errorBuilder: (_, __, ___) => ColoredBox(color: AppColors.goldRule,
          child: const Center(child: Icon(Icons.landscape_outlined, size: 48)))),
      const Positioned.fill(child: IgnorePointer(child: DecoratedBox(
        decoration: BoxDecoration(gradient: LinearGradient(
          begin: Alignment.topCenter, end: Alignment.bottomCenter,
          stops: [0.45, 1], colors: [Colors.transparent, Color(0xC9000000)]))))),
      Positioned(left: 18, right: 18, bottom: 18, child: Text(title,
        maxLines: 2, overflow: TextOverflow.ellipsis,
        style: AppText.rowTitle.copyWith(color: Colors.white, fontSize: 26, height: 1.25))),
    ])),
    // Let long chapter titles and accessibility text wrap below the image.
    if (subtitle != null) Padding(padding: const EdgeInsets.fromLTRB(18, 12, 18, 8),
      child: Align(alignment: AlignmentDirectional.centerStart,
        child: Text(subtitle!, style: AppText.body.copyWith(color: AppColors.textMuted)))),
  ]);
}
