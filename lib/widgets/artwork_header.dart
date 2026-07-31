import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'sky_artwork.dart';

/// Home header: the masjid name, city and Hijri date sit **on** the
/// photograph, top-left, over a scrim.
///
/// This is the third arrangement we have tried, so the reasoning is worth
/// recording. Originally the name sat over the middle of the picture, across
/// the dome, which was unreadable. Moving it to a white bar above fixed that
/// but cost about 90px of vertical space and made the photograph feel like a
/// thumbnail. Anchoring it top-left over a gradient scrim gets both: the type
/// stays legible because the scrim guarantees contrast regardless of what the
/// sky is doing, and the picture gets the full height back.
///
/// The scrim is not decoration — the sky behind it swings from pale midday
/// blue to near-black at night, and cream text would vanish against the bright
/// states without it.
class ArtworkHeader extends StatelessWidget {
  const ArtworkHeader({
    super.key,
    required this.masjidName,
    required this.metaLine,
    required this.onSettingsTap,
    required this.onMetaTap,
    required this.phase,
    this.artworkHeight = 300,
    this.settle = 1.0,
  });

  final String masjidName;

  /// City and Hijri date, already formatted.
  final String metaLine;

  final VoidCallback onSettingsTap;
  final VoidCallback onMetaTap;

  /// Which sky to show. Comes from the masjid's prayer times, not the clock.
  final SkyPhase phase;

  final double artworkHeight;

  /// 0 → just landed, 1 → settled. Fades the picture in.
  final double settle;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: artworkHeight,
      width: double.infinity,
      child: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          Opacity(
            opacity: settle.clamp(0.0, 1.0),
            child: SkyArtwork(phase: phase, height: artworkHeight),
          ),

          // Top-down scrim. Strongest at the very top where the type sits,
          // gone by a third of the way down so it never dulls the building.
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: <Color>[
                  Color(0xB3000000),
                  Color(0x59000000),
                  Color(0x00000000),
                ],
                stops: <double>[0.0, 0.18, 0.42],
              ),
            ),
          ),

          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 8, 0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Expanded(
                    child: GestureDetector(
                      onTap: onMetaTap,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          const SizedBox(height: 6),
                          Text(
                            masjidName,
                            textAlign: TextAlign.left,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppText.displayName.copyWith(
                              fontSize: 24,
                              color: Colors.white,
                              shadows: const <Shadow>[
                                Shadow(blurRadius: 8, color: Color(0x66000000)),
                              ],
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            metaLine,
                            textAlign: TextAlign.left,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: AppText.eyebrow.copyWith(
                              fontSize: 11,
                              letterSpacing: 1.2,
                              height: 1.45,
                              color: const Color(0xE6FFFFFF),
                              shadows: const <Shadow>[
                                Shadow(blurRadius: 6, color: Color(0x59000000)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.settings_outlined,
                        color: Colors.white, size: 21),
                    tooltip: 'Settings',
                    onPressed: onSettingsTap,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
