import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../theme/app_theme_controller.dart';

/// Six real, selectable themes: Green (Light), Green (Dark), Black & Gold,
/// Blue, Amber, Purple - all wired to real, hand-specified palettes in
/// AppColors. "System Default" was in the original 7-option list but has
/// been removed on request; it would need to track the device's own live
/// light/dark setting rather than a fixed palette, a different mechanism
/// from the other six.
class ThemeSelectionScreen extends StatelessWidget {
  const ThemeSelectionScreen({super.key});

  static const List<(String id, String label, bool available)> _options = [
    ('green_light', 'Green (Light)', true),
    ('green_dark', 'Green (Dark)', true),
    ('black_gold', 'Black & Gold', true),
    ('blue', 'Blue', true),
    ('amber', 'Amber', true),
    ('purple', 'Purple', true),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Appearance')),
      body: ListenableBuilder(
        listenable: AppThemeController.instance,
        builder: (context, _) {
          final String current = AppThemeController.instance.themeId;
          // 3 columns x 2 rows for the 6 themes, as requested - a grid of
          // swatches reads faster than a scrolling list when every option
          // is a colour choice, and it means all six are visible at once
          // with no scrolling on a normal phone.
          return GridView.builder(
            padding: const EdgeInsets.all(12),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 0.85,
            ),
            itemCount: _options.length,
            itemBuilder: (context, index) {
              final (id, label, available) = _options[index];
              final bool selected = id == current;
              return _ThemeTile(
                id: id,
                label: label,
                available: available,
                selected: selected,
                onTap: available
                    ? () => AppThemeController.instance.setTheme(id)
                    : null,
              );
            },
          );
        },
      ),
    );
  }
}

/// One grid cell: swatch, name, and a gold ring/checkmark when it is the
/// current theme - the card itself is the tap target, not just the swatch.
class _ThemeTile extends StatelessWidget {
  const _ThemeTile({
    required this.id,
    required this.label,
    required this.available,
    required this.selected,
    required this.onTap,
  });

  final String id;
  final String label;
  final bool available;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: available ? 1 : 0.45,
      child: Material(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: selected ? AppColors.gold : Colors.black12,
                width: selected ? 2 : 1,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    _Swatch(themeId: id),
                    if (selected)
                      Positioned(
                        right: -4,
                        bottom: -4,
                        child: Container(
                          padding: const EdgeInsets.all(1),
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.check_circle,
                              color: AppColors.gold, size: 18),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  label,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                ),
                if (!available) ...[
                  const SizedBox(height: 2),
                  const Text('Coming soon',
                      style: TextStyle(fontSize: 10, color: Colors.grey)),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A small preview circle for each option, so the choice is visible before
/// tapping - a plain gray dot for the theme names with no built palette yet
/// would be misleading, so those get a neutral placeholder instead of a
/// colour that doesn't actually exist.
class _Swatch extends StatelessWidget {
  const _Swatch({required this.themeId});

  final String themeId;

  @override
  Widget build(BuildContext context) {
    final (Color bg, Color fg) = switch (themeId) {
      'green_light' => (const Color(0xFFFAF7F0), const Color(0xFF0F5E3A)),
      'black_gold' => (const Color(0xFF0B1211), const Color(0xFFD4AF57)),
      'green_dark' => (const Color(0xFF0D1B16), const Color(0xFF34A874)),
      'blue' => (const Color(0xFFF2F6FB), const Color(0xFF1D5A8F)),
      'amber' => (const Color(0xFFFBF6EC), const Color(0xFFA9601A)),
      'purple' => (const Color(0xFFF7F4FA), const Color(0xFF6B3FA0)),
      _ => (const Color(0xFFE0DCD0), const Color(0xFFB5AC98)),
    };
    return Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        color: bg,
        shape: BoxShape.circle,
        border: Border.all(color: fg, width: 2),
      ),
    );
  }
}
