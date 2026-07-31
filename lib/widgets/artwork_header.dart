import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'sky_artwork.dart';

/// Home header: a compact white title bar, then the picture edge to edge.
///
/// The title bar is deliberately tight. An earlier version stacked the settings
/// icon on its own row above the name, which left a tall band of empty white
/// above the photograph. Icon and title now share one row, which halves the
/// height of the bar and lets the picture start much higher up the screen.
class ArtworkHeader extends StatelessWidget {
  const ArtworkHeader({
    super.key,
    required this.masjidName,
    required this.metaLine,
    required this.onSettingsTap,
    required this.onMetaTap,
    required this.phase,
    this.artworkHeight = 214,
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Container(
          color: AppColors.white,
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(8, 2, 8, 8),
              child: Row(
                children: <Widget>[
                  // Balances the icon on the right so the title stays optically
                  // centred without a second row.
                  const SizedBox(width: 44),
                  Expanded(
                    child: GestureDetector(
                      onTap: onMetaTap,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          Text(
                            masjidName,
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppText.displayName
                                .copyWith(fontSize: 21, color: AppColors.emerald),
                          ),
                          const SizedBox(height: 1),
                          Text(
                            metaLine,
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppText.eyebrow.copyWith(
                              fontSize: 10.5,
                              letterSpacing: 1.1,
                              color: AppColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 44,
                    child: IconButton(
                      icon: const Icon(Icons.settings_outlined,
                          color: AppColors.text, size: 20),
                      tooltip: 'Settings',
                      visualDensity: VisualDensity.compact,
                      onPressed: onSettingsTap,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        // The picture, full bleed. SkyArtwork animates the time of day over it.
        Opacity(
          opacity: settle.clamp(0.0, 1.0),
          child: SkyArtwork(phase: phase, height: artworkHeight),
        ),
      ],
    );
  }
}
