import 'package:flutter/material.dart';

class AddItemModalV2 extends StatefulWidget {
  final Function(String name, String placeName) onAdd;

  const AddItemModalV2({
    super.key,
    required this.onAdd,
  });

  @override
  State<AddItemModalV2> createState() => _AddItemModalV2State();
}

class _AddItemModalV2State extends State<AddItemModalV2> {
  final _nameController = TextEditingController();
  // final _categoryController = TextEditingController(); // Eliminado
  String _selectedPlace = 'Supermercado';

  final List<String> _places = [
    'Supermercado',
    'Farmacia',
    'Ferretería',
    'Panadería',
    'Mercado',
    'Tienda de Electrónicos',
    'Otro',
  ];

  @override
  void dispose() {
  _nameController.dispose();
  super.dispose();
  }

  void _handleAdd() {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor ingresa un nombre')),
      );
      return;
    }
    widget.onAdd(name, _selectedPlace);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Icon(Icons.add_shopping_cart, size: 28),
                const SizedBox(width: 12),
                const Text(
                  'Añadir Artículo',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Nombre del artículo',
                hintText: 'Ej: Leche, Pan, Tornillos...',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.shopping_bag),
              ),
              autofocus: true,
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedPlace,
              decoration: const InputDecoration(
                labelText: 'Lugar de compra',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.store),
              ),
              items: _places.map((place) {
                return DropdownMenuItem(
                  value: place,
                  child: Text(place),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() => _selectedPlace = value);
                }
              },
            ),
            // Campo de categoría eliminado
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('CANCELAR'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _handleAdd,
                  child: const Text('AÑADIR'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
