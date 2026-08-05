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
    this.onDirectionsTap,
    this.artworkHeight = 300,
    this.settle = 1.0,
  });

  final String masjidName;

  /// City and Hijri date, already formatted.
  final String metaLine;

  final VoidCallback onSettingsTap;
  final VoidCallback onMetaTap;

  /// Null when the masjid has no coordinates, in which case no button is shown
  /// rather than one that opens an empty map.
  final VoidCallback? onDirectionsTap;

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

          // SOLID BAND, NOT A SUBTLE SCRIM.
          //
          // This was a gentle gradient tuned against the night sky. On a bright
          // photograph — pale marble, golden sunset — white text over it was
          // invisible. The name, address and directions were rendering the
          // whole time and simply could not be seen.
          //
          // A scrim that works at BOTH ends of the range has to be strong
          // enough for the brightest case, which means near-opaque at the top.
          // The picture loses a strip; the text becomes readable. That is the
          // right trade for text that has to work on every masjid photo, not
          // just a dark one.
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: <Color>[
                  Color(0xE6000000),
                  Color(0xB3000000),
                  Color(0x40000000),
                  Color(0x00000000),
                ],
                stops: <double>[0.0, 0.34, 0.52, 0.68],
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
                              // 20, down from 24. Over a photograph the name
                              // does not need to shout — the scrim and the
                              // white already separate it from the sky, and a
                              // smaller name lets more of the building show.
                              fontSize: 20,
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
                          // Directions live here now, beside the name and
                          // address they belong to. They used to sit in a card
                          // further down that repeated all of this.
                          if (onDirectionsTap != null) ...<Widget>[
                            const SizedBox(height: 8),
                            _GlassButton(
                              icon: Icons.directions_outlined,
                              label: 'Get directions',
                              onTap: onDirectionsTap!,
                            ),
                          ],
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

/// A button that has to stay legible over a photograph whose brightness swings
/// from midday sky to near-black. A translucent dark fill plus a white hairline
/// works at both ends; a plain text button does not.
class _GlassButton extends StatelessWidget {
  const _GlassButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Material(
        color: const Color(0x66000000),
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0x59FFFFFF)),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 7),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Icon(icon, size: 15, color: Colors.white),
                const SizedBox(width: 6),
                Text(label,
                    style: AppText.caption.copyWith(
                        color: Colors.white, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
