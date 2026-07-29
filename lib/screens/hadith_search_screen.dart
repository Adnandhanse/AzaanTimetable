import 'package:flutter/material.dart';
import '../models/hadith.dart';

class HadithSearchScreen extends StatefulWidget {
  final HadithCollection collection;
  final String bookKey;
  final String language;

  const HadithSearchScreen({super.key, required this.collection, required this.bookKey, required this.language});

  @override
  State<HadithSearchScreen> createState() => _HadithSearchScreenState();
}

class _HadithSearchScreenState extends State<HadithSearchScreen> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final results = _query.trim().isEmpty
        ? <HadithItem>[]
        : widget.collection.hadiths
            .where((h) => h.text.toLowerCase().contains(_query.toLowerCase()))
            .take(100)
            .toList();

    return Scaffold(
      appBar: AppBar(
        title: Text('Search ${widget.collection.name}'),
        backgroundColor: const Color(0xFF14532D),
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              autofocus: true,
              decoration: const InputDecoration(
                hintText: 'Search hadith text (e.g. "intention", "prayer")',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: (v) => setState(() => _query = v),
            ),
          ),
          if (_query.trim().isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text('${results.length} result(s)${results.length == 100 ? ' (showing first 100)' : ''}',
                    style: const TextStyle(color: Colors.grey)),
              ),
            ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: results.length,
              itemBuilder: (context, index) {
                final hadith = results[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Hadith ${hadith.hadithNumber}',
                            style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF14532D), fontSize: 12)),
                        const SizedBox(height: 6),
                        Text(hadith.text, style: const TextStyle(fontSize: 14)),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
