import 'package:flutter/material.dart';

class PropertiesScreen extends StatefulWidget {
  const PropertiesScreen({super.key});

  @override
  State<PropertiesScreen> createState() => _PropertiesScreenState();
}

class _PropertiesScreenState extends State<PropertiesScreen> {
  final List<String> _properties = ['Color', 'Weight', 'Size'];
  final TextEditingController _ctrl = TextEditingController();

  void _add() {
    if (_ctrl.text.trim().isEmpty) return;
    setState(() {
      _properties.add(_ctrl.text.trim());
      _ctrl.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Properties')),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(children: [
              Expanded(child: TextField(controller: _ctrl, decoration: const InputDecoration(labelText: 'New property'))),
              IconButton(onPressed: _add, icon: const Icon(Icons.add))
            ]),
            const SizedBox(height: 12),
            Expanded(
              child: ListView.builder(
                itemCount: _properties.length,
                itemBuilder: (context, i) => ListTile(title: Text(_properties[i])),
              ),
            )
          ],
        ),
      ),
    );
  }
}
