import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// A row of speed chips, shared by the hadith reader and the Qur'an player.
///
/// One widget rather than two, because the two places must agree: someone who
/// sets 1.25× for hadith and finds the Qur'an player offering 0.5×/2× has been
/// given two different controls for the same idea.
///
/// Chips rather than a slider. A slider invites fiddling and lands people on
/// rates that are unintelligible, and nobody can hear the difference between
/// 1.12× and 1.18×.
class SpeedSelector extends StatelessWidget {
  const SpeedSelector({
    super.key,
    required this.options,
    required this.value,
    required this.onChanged,
    this.compact = false,
  });

  /// (label, value) pairs. The label is what the reader sees — "1.25×" — and
  /// the value is whatever the underlying player wants, which is not the same
  /// number for TTS as for audio playback.
  final List<(String, double)> options;
  final double value;
  final ValueChanged<double> onChanged;

  /// Smaller, for sitting inside a card rather than a toolbar.
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Icon(Icons.speed,
            size: compact ? 14 : 16, color: AppColors.textMuted),
        const SizedBox(width: 6),
        for (final (String label, double v) in options)
          Padding(
            padding: const EdgeInsets.only(right: 5),
            child: GestureDetector(
              onTap: () => onChanged(v),
              child: Container(
                padding: EdgeInsets.symmetric(
                    horizontal: compact ? 8 : 10, vertical: compact ? 3 : 4),
                decoration: BoxDecoration(
                  color: v == value ? AppColors.emerald : Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: v == value
                          ? AppColors.emerald
                          : AppColors.goldRule),
                ),
                child: Text(
                  label,
                  style: AppText.caption.copyWith(
                    fontSize: compact ? 10.5 : 11.5,
                    fontWeight: v == value ? FontWeight.w600 : FontWeight.w400,
                    color: v == value ? Colors.white : AppColors.textMuted,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
