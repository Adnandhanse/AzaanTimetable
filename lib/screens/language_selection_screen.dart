import 'package:flutter/material.dart';
import '../services/app_language.dart';
import 'home_screen.dart';

class LanguageSelectionScreen extends StatelessWidget {
  const LanguageSelectionScreen({super.key});

  Future<void> _choose(BuildContext context, AppLanguage language) async {
    await AppLanguageController.instance.setLanguage(language, markChosen: true);
    if (!context.mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const HomeScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F5EE),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.language, size: 56, color: Color(0xFF1F5E4A)),
              const SizedBox(height: 20),
              const Text(
                'Choose your language',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF2F3A35)),
              ),
              const Text(
                'اپنی زبان منتخب کریں',
                style: TextStyle(fontSize: 18, color: Color(0xFF7A7A7A)),
              ),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFF1F5E4A), width: 1.5),
                  ),
                  onPressed: () => _choose(context, AppLanguage.english),
                  child: const Text('English', style: TextStyle(fontSize: 18, color: Color(0xFF1F5E4A))),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1F5E4A)),
                  onPressed: () => _choose(context, AppLanguage.urdu),
                  child: const Text('اردو', style: TextStyle(fontSize: 20, color: Colors.white)),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'You can change this anytime in Settings.',
                style: TextStyle(fontSize: 12, color: Color(0xFF7A7A7A)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
