import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/app_language.dart';
import 'role_selection_screen.dart';

class LanguageSelectionScreen extends StatelessWidget {
  const LanguageSelectionScreen({super.key});

  Future<void> _choose(BuildContext context, AppLanguage language) async {
    await AppLanguageController.instance.setLanguage(language, markChosen: true);
    if (!context.mounted) return;
    // On to the role question, not straight to Home — otherwise a first-run
    // user picking a language would skip it entirely and never be asked.
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const RoleSelectionScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.ivory,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.language, size: 56, color: AppColors.emerald),
              const SizedBox(height: 20),
              const Text(
                'Choose your language',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.text),
              ),
              const Text(
                'اپنی زبان منتخب کریں',
                style: TextStyle(fontSize: 18, color: AppColors.textMuted),
              ),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: AppColors.emerald, width: 1.5),
                  ),
                  onPressed: () => _choose(context, AppLanguage.english),
                  child: const Text('English', style: TextStyle(fontSize: 18, color: AppColors.emerald)),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.emerald),
                  onPressed: () => _choose(context, AppLanguage.urdu),
                  child: const Text('اردو', style: TextStyle(fontSize: 20, color: Colors.white)),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'You can change this anytime in Settings.',
                style: TextStyle(fontSize: 12, color: AppColors.textMuted),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
