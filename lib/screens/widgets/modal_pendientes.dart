import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../widgets/custom_text_button.dart';

class ModalPendientes extends StatefulWidget {
  final Function(String name, String placeName, int quantity) onAdd;

  /// 🔹 Lugar predefinido (opcional).
  /// Si viene distinto de null, el lugar se muestra fijo y no se puede cambiar.
  final String? predefinedPlace;

  const ModalPendientes({
    super.key,
    required this.onAdd,
    this.predefinedPlace,
  });

  @override
  State<ModalPendientes> createState() => _ModalPendientesState();
}

class _ModalPendientesState extends State<ModalPendientes> {
  final _nameController = TextEditingController();
  final _quantityController = TextEditingController(text: '1');
  final _customPlaceController = TextEditingController();
  late String _selectedPlace;

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
  void initState() {
    super.initState();
    // Si hay lugar predefinido, usamos ese; si no, el default "Supermercado"
    _selectedPlace = widget.predefinedPlace ?? 'Supermercado';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _quantityController.dispose();
    _customPlaceController.dispose();
    super.dispose();
  }

  void _handleAdd() {
    final name = _nameController.text.trim();
    final quantityText = _quantityController.text.trim();
    final quantity = int.tryParse(quantityText);

    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor ingresa un nombre')),
      );
      return;
    }

    if (quantity == null || quantity <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor ingresa una cantidad válida')),
      );
      return;
    }

    String finalPlace;

    // ✅ Si viene lugar predefinido, usamos ese SIEMPRE
    if (widget.predefinedPlace != null &&
        widget.predefinedPlace!.trim().isNotEmpty) {
      finalPlace = widget.predefinedPlace!.trim();
    } else {
      // 🔹 Misma lógica anterior (dropdown + "Otro")
      finalPlace = _selectedPlace;
      if (_selectedPlace == 'Otro') {
        final customPlace = _customPlaceController.text.trim();
        if (customPlace.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Por favor ingresa un nombre para el lugar'),
            ),
          );
          return;
        }
        finalPlace = customPlace;
      }
    }

    widget.onAdd(name, finalPlace, quantity);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final hasPredefinedPlace = widget.predefinedPlace != null &&
        widget.predefinedPlace!.trim().isNotEmpty;

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

            // 🔹 Si HAY lugar predefinido → campo fijo con mismo formato visual
            if (hasPredefinedPlace) ...[
              TextField(
                enabled: false,
                controller: TextEditingController(
                  text: widget.predefinedPlace,
                ),
                decoration: const InputDecoration(
                  labelText: 'Lugar de compra',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.store),
                ),
              ),
            ] else ...[
              // 🔹 Si NO hay lugar predefinido → mismo dropdown de antes
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: 'Lugar de compra',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.store),
                ),
                value: _places.contains(_selectedPlace)
                    ? _selectedPlace
                    : 'Supermercado',
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
              if (_selectedPlace == 'Otro') ...[
                const SizedBox(height: 16),
                TextField(
                  controller: _customPlaceController,
                  decoration: const InputDecoration(
                    labelText: 'Nombre del lugar',
                    hintText: 'Ej: Costco, Carrefour, Mercadona...',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.edit_location),
                  ),
                  textCapitalization: TextCapitalization.words,
                ),
              ],
            ],

            const SizedBox(height: 16),
            TextField(
              controller: _quantityController,
              decoration: const InputDecoration(
                labelText: 'Cantidad',
                hintText: 'Ej: 1, 2, 3...',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.numbers),
                suffixText: 'unidades',
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                CustomTextButton(
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
