import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../theme/app_theme.dart';

class UpdateInventoryModalV2 extends StatefulWidget {
  final String itemName;
  final Function(int quantity, DateTime? expirationDate) onUpdate;
  final VoidCallback onSkip;

  const UpdateInventoryModalV2({
    super.key,
    required this.itemName,
    required this.onUpdate,
    required this.onSkip,
  });

  @override
  State<UpdateInventoryModalV2> createState() => _UpdateInventoryModalV2State();
}

class _UpdateInventoryModalV2State extends State<UpdateInventoryModalV2> {
  final _quantityController = TextEditingController(text: '1');
  DateTime? _selectedDate;

  @override
  void dispose() {
    _quantityController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 7)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 3650)), // 10 años
      helpText: 'Selecciona fecha de caducidad',
    );

    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  void _handleUpdate() {
    final quantityText = _quantityController.text.trim();
    final quantity = int.tryParse(quantityText);

    if (quantity == null || quantity <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor ingresa una cantidad válida')),
      );
      return;
    }

    widget.onUpdate(quantity, _selectedDate);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final successColor = Theme.of(context).brightness == Brightness.light
        ? AppTheme.successLight
        : AppTheme.successDark;

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
                Icon(Icons.inventory_2, size: 28, color: successColor),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Actualizar Inventario',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        widget.itemName,
                        style: TextStyle(
                          fontSize: 14,
                          color: AppTheme.getTextSecondary(context),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 24),
            const Text(
              '¿Cuántos compraste?',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _quantityController,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.numbers),
                suffixText: 'unidades',
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              autofocus: true,
            ),
            const SizedBox(height: 20),
            const Text(
              'Fecha de caducidad (opcional)',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            InkWell(
              onTap: _selectDate,
              borderRadius: BorderRadius.circular(4),
              child: InputDecorator(
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.calendar_today),
                ),
                child: Text(
                  _selectedDate == null
                      ? 'Seleccionar fecha'
                      : '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}',
                  style: TextStyle(
                    color: _selectedDate == null
                        ? AppTheme.getTextSecondary(context)
                        : null,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _handleUpdate,
              icon: const Icon(Icons.check),
              label: const Text('ACTUALIZAR INVENTARIO'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () {
                widget.onSkip();
                Navigator.of(context).pop();
              },
              child: const Text('SOLO MARCAR (NO ACTUALIZAR)'),
            ),
          ],
        ),
      ),
    );
  }
}
