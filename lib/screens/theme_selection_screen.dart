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
