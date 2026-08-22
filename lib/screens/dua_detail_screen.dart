import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/dua.dart';

class DuaDetailScreen extends StatelessWidget {
  final DuaCategory category;
  const DuaDetailScreen({super.key, required this.category});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(category.displayTitle),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: category.duas.length,
        itemBuilder: (context, index) {
          final dua = category.duas[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    dua.arabicText,
                    textAlign: TextAlign.right,
                    textDirection: TextDirection.rtl,
                    style: AppText.arabicVerse.copyWith(color: AppColors.text),
                  ),
                  const SizedBox(height: 10),
                  const Divider(),
                  Text(dua.displayTranslation.trim(), style: const TextStyle(fontSize: 15)),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
