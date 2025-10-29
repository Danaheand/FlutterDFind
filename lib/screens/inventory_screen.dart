import 'package:flutter/material.dart';
import '../models/inventory_item.dart';
import 'object_detail_screen.dart';

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  final List<String> _imageNames = [
    'tele.jpg', 'taladro.jpg', 'pasaporte.jpg', 'libro.jpg', 'leche.jpg', 'laptop.jpg', 'jarron.jpg', 'camara.jpg', 'bici.jpg', 'atun.jpg', 'arroz.jpg', 'aire.jpg'
  ];

  final List<InventoryItem> _items = List.generate(
    8,
    (i) => InventoryItem(
      id: 'it_$i',
      name: 'Item #$i',
      category: 'Category ${i % 3}',
      location: 'Shelf ${i % 4}',
      image: i < 12 ? 'assets/img/${['tele.jpg','taladro.jpg','pasaporte.jpg','libro.jpg','leche.jpg','laptop.jpg','jarron.jpg','camara.jpg','bici.jpg','atun.jpg','arroz.jpg','aire.jpg'][i]}' : null,
      createdAt: DateTime.now().subtract(Duration(days: i)),
    ),
  );

  // Filters and UI state
  String _search = '';
  String? _selectedCategory;
  String? _selectedLocation;

  final List<String> _categories = ['All', 'Electronics', 'Furniture', 'Consumables', 'Uncategorized'];
  final List<String> _locations = ['All', 'Shelf 0', 'Shelf 1', 'Shelf 2', 'Shelf 3', 'Unknown'];

  void _addOrEditItem({InventoryItem? edit}) {
    final nameCtrl = TextEditingController(text: edit?.name ?? '');
    String category = edit?.category ?? _categories[1];
    String location = edit?.location ?? _locations[1];
    String? image = edit?.image;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(edit == null ? 'Add item' : 'Edit item'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Name')),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: category,
                items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                onChanged: (v) => category = v ?? category,
                decoration: const InputDecoration(labelText: 'Category'),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: location,
                items: _locations.map((l) => DropdownMenuItem(value: l, child: Text(l))).toList(),
                onChanged: (v) => location = v ?? location,
                decoration: const InputDecoration(labelText: 'Location'),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: image,
                items: [null, ..._imageNames].map((n) => DropdownMenuItem(value: n == null ? null : 'assets/img/$n', child: Text(n ?? 'No image'))).toList(),
                onChanged: (v) => image = v,
                decoration: const InputDecoration(labelText: 'Image'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              final name = nameCtrl.text.trim();
              if (name.isEmpty) return;
              setState(() {
                if (edit != null) {
                  edit.name = name;
                  edit.category = category;
                  edit.location = location;
                  edit.image = image;
                } else {
                  final newItem = InventoryItem(
                    id: 'it_${_items.length + 1}',
                    name: name,
                    category: category,
                    location: location,
                    image: image,
                  );
                  _items.insert(0, newItem);
                }
              });
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _removeItem(InventoryItem it) {
    setState(() => _items.removeWhere((e) => e.id == it.id));
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _items.where((it) {
      final matchesSearch = it.name.toLowerCase().contains(_search.toLowerCase());
      final matchesCat = _selectedCategory == null || _selectedCategory == 'All' ? true : it.category == _selectedCategory;
      final matchesLoc = _selectedLocation == null || _selectedLocation == 'All' ? true : it.location == _selectedLocation;
      return matchesSearch && matchesCat && matchesLoc;
    }).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Inventory')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _addOrEditItem(),
        child: const Icon(Icons.add),
      ),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            TextField(
              decoration: const InputDecoration(prefixIcon: Icon(Icons.search), hintText: 'Search inventory...'),
              onChanged: (v) => setState(() => _search = v),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: DropdownButton<String>(
                    value: _selectedCategory ?? 'All',
                    isExpanded: true,
                    items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                    onChanged: (v) => setState(() => _selectedCategory = v),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: DropdownButton<String>(
                    value: _selectedLocation ?? 'All',
                    isExpanded: true,
                    items: _locations.map((l) => DropdownMenuItem(value: l, child: Text(l))).toList(),
                    onChanged: (v) => setState(() => _selectedLocation = v),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(onPressed: () => _showPropertiesModal(), child: const Text('Properties')),
              ],
            ),
            const SizedBox(height: 12),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.only(bottom: 16),
                itemCount: filtered.length,
                itemBuilder: (context, index) {
                  final it = filtered[index];
                  final asset = it.image ?? 'assets/img/${_imageNames[index % _imageNames.length]}';
                  return Card(
                    child: ListTile(
                      leading: ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: Image.asset(
                          asset,
                          width: 56,
                          height: 56,
                          fit: BoxFit.cover,
                          errorBuilder: (c, e, s) => CircleAvatar(child: Text(it.name.characters.first)),
                        ),
                      ),
                      title: Text(it.name),
                      subtitle: Text('${it.category} • ${it.location}'),
                      trailing: PopupMenuButton<String>(
                        onSelected: (v) {
                          if (v == 'edit') _addOrEditItem(edit: it);
                          if (v == 'delete') _removeItem(it);
                        },
                        itemBuilder: (_) => const [
                          PopupMenuItem(value: 'edit', child: Text('Edit')),
                          PopupMenuItem(value: 'delete', child: Text('Delete')),
                        ],
                      ),
                      onTap: () {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => ObjectDetailScreen(item: it)));
                      },
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

  void _showPropertiesModal() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Properties (demo)'),
        content: const Text('This would list and allow editing of item properties. For now it is a placeholder that you can expand.'),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close'))],
      ),
    );
  }
}
