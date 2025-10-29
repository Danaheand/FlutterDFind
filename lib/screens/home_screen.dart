import 'package:flutter/material.dart';
import '../models/inventory_item.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final List<InventoryItem> _recent = List.generate(
    4,
    (i) => InventoryItem(id: 'r_$i', name: 'Recent $i', category: 'Cat ${i%2}', location: 'Loc ${i}'),
  );

  String _search = '';

  List<InventoryItem> get _filtered => _recent.where((r) => r.name.toLowerCase().contains(_search.toLowerCase())).toList();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Home')),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              decoration: const InputDecoration(prefixIcon: Icon(Icons.search), hintText: 'Search...'),
              onChanged: (v) => setState(() => _search = v),
            ),
            const SizedBox(height: 12),
            const Text('Recently added', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Expanded(
              child: ListView.builder(
                itemCount: _filtered.length,
                itemBuilder: (context, i) {
                  final it = _filtered[i];
                  return Card(
                    child: ListTile(
                      title: Text(it.name),
                      subtitle: Text('${it.category} • ${it.location}'),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}