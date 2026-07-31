import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'sky_artwork.dart';

/// Home header: masjid name and date at the **top**, artwork beneath.
///
/// The name used to sit over the middle of the artwork, which put type across
/// the dome and made both harder to read. Text on top, picture below — each
/// gets its own space and neither fights the other.
///
/// The picture below the type is [SkyArtwork]: the Masjid an-Nabawi photograph
/// with the time of day animated on top of it — light, birds, stars.
class ArtworkHeader extends StatelessWidget {
  const ArtworkHeader({
    super.key,
    required this.masjidName,
    required this.metaLine,
    required this.onSettingsTap,
    required this.onMetaTap,
    required this.phase,
    this.artworkHeight = 200,
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

  /// 0 → just landed, 1 → settled. Drives the artwork's scale-in.
  final double settle;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          SafeArea(
            bottom: false,
            child: Column(
              children: <Widget>[
                Align(
                  alignment: Alignment.topRight,
                  child: IconButton(
                    icon: const Icon(Icons.settings_outlined,
                        color: AppColors.text, size: 20),
                    tooltip: 'Settings',
                    onPressed: onSettingsTap,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Text(
                    masjidName,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style:
                        AppText.displayName.copyWith(color: AppColors.emerald),
                  ),
                ),
                const SizedBox(height: 4),
                GestureDetector(
                  onTap: onMetaTap,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Text(
                      metaLine,
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppText.eyebrow.copyWith(
                        letterSpacing: 1.2,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
              ],
            ),
          ),

          // The animated sky. Sunrise and birds in the morning, a still sun
          // overhead at midday, sunset and birds in the evening, stars and a
          // crescent at night — driven by the masjid's own prayer times.
          //
          // The building is a transparent PNG layered inside SkyArtwork, so the
          // sky animates behind it.
          Opacity(
            opacity: settle.clamp(0.0, 1.0),
            child: SkyArtwork(phase: phase, height: artworkHeight),
          ),
        ],
      ),
    );
  }
}
