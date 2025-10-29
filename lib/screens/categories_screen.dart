import 'package:flutter/material.dart';

class CategoriesScreen extends StatefulWidget {
  const CategoriesScreen({super.key});

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  final List<String> _cats = ['Electronics', 'Furniture', 'Consumables'];
  final TextEditingController _ctrl = TextEditingController();

  void _add() {
    final v = _ctrl.text.trim();
    if (v.isEmpty) return;
    setState(() => _cats.add(v));
    _ctrl.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Categories')),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(children: [
              Expanded(child: TextField(controller: _ctrl, decoration: const InputDecoration(labelText: 'New category'))),
              IconButton(onPressed: _add, icon: const Icon(Icons.add))
            ]),
            const SizedBox(height: 12),
            Expanded(child: ListView.builder(itemCount: _cats.length, itemBuilder: (c, i) => ListTile(title: Text(_cats[i])))),
          ],
        ),
      ),
    );
  }
}
