import 'package:flutter/material.dart';
import '../models/dua.dart';
import '../services/dua_repository.dart';
import 'dua_detail_screen.dart';

class DuaHomeScreen extends StatefulWidget {
  const DuaHomeScreen({super.key});

  @override
  State<DuaHomeScreen> createState() => _DuaHomeScreenState();
}

class _DuaHomeScreenState extends State<DuaHomeScreen> {
  List<DuaCategory>? _categories;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final categories = await DuaRepository.loadCategories();
    if (!mounted) return;
    setState(() => _categories = categories);
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _categories == null
        ? <DuaCategory>[]
        : _categories!.where((c) => c.title.toLowerCase().contains(_query.toLowerCase())).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Duas'),
        backgroundColor: const Color(0xFF1F5E4A),
        foregroundColor: Colors.white,
      ),
      body: _categories == null
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: TextField(
                    decoration: const InputDecoration(
                      hintText: 'Search duas by topic',
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (v) => setState(() => _query = v),
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final category = filtered[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        child: ListTile(
                          leading: const Icon(Icons.favorite_border, color: Color(0xFF1F5E4A)),
                          title: Text(category.title),
                          subtitle: Text('${category.duas.length} dua(s)'),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => DuaDetailScreen(category: category)),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    'Source: Hisn al-Muslim (hisnmuslim.com) • Works fully offline',
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                  ),
                ),
              ],
            ),
    );
  }
}
