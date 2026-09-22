import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../theme/app_theme_controller.dart';

/// The 7 options as specified: Green (Dark), Green (Light), Black & Gold,
/// Blue, Amber, Purple, System Default.
///
/// Only 'green_light' and 'black_gold' are wired to real, hand-specified
/// palettes in AppColors right now - see the scope note on
/// AppThemeController. The other five are listed (so the picker matches
/// what was asked for) but disabled with a "Coming soon" tag rather than
/// silently pretending to work - picking "Blue" and having nothing change
/// would be a worse experience than not offering it yet.
class ThemeSelectionScreen extends StatelessWidget {
  const ThemeSelectionScreen({super.key});

  static const List<(String id, String label, bool available)> _options = [
    ('green_light', 'Green (Light)', true),
    ('green_dark', 'Green (Dark)', false),
    ('black_gold', 'Black & Gold', true),
    ('blue', 'Blue', false),
    ('amber', 'Amber', false),
    ('purple', 'Purple', false),
    ('system', 'System Default', false),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Appearance')),
      body: ListenableBuilder(
        listenable: AppThemeController.instance,
        builder: (context, _) {
          final String current = AppThemeController.instance.themeId;
          return ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: _options.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final (id, label, available) = _options[index];
              final bool selected = id == current;
              return ListTile(
                enabled: available,
                leading: _Swatch(themeId: id),
                title: Text(label),
                subtitle: available ? null : const Text('Coming soon'),
                trailing: selected
                    ? Icon(Icons.check_circle, color: AppColors.gold)
                    : null,
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
