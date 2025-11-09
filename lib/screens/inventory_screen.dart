import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/font_size_provider.dart';
import '../models/shopping_item.dart';
import '../models/suggestion_item.dart';
import '../theme/app_theme.dart';
import 'widgets/add_item_modal_v2.dart';
import 'widgets/suggestions_section.dart';
// ...existing code...

typedef AddToShoppingList = void Function(String name);

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});

  static AddToShoppingList? addFromAlertGlobal;

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  final List<ShoppingItem> _items = [];
  final Map<String, bool> _expandedPlaces = {};

  // Sugerencias de ejemplo (en producción vendrían del inventario)
  final List<SuggestionItem> _suggestions = [
    SuggestionItem(
      id: 's1',
      name: 'Leche',
      placeName: 'Supermercado',
      category: 'Lácteos',
      reason: 'Stock bajo',
    ),
    SuggestionItem(
      id: 's2',
      name: 'Pan',
      placeName: 'Panadería',
      category: 'Panadería',
      reason: 'Compra frecuente',
    ),
  ];

  @override
  void initState() {
    super.initState();
    InventoryScreen.addFromAlertGlobal = addFromAlert;
  }

  @override
  void dispose() {
    InventoryScreen.addFromAlertGlobal = null;
    super.dispose();
  }

  void addFromAlert(String name) {
    if (_items.any((e) => e.name == name)) return;
    setState(() {
      _items.add(ShoppingItem(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: name,
        placeName: 'Supermercado',
        category: '',
      ));
    });
  }

  void _addItemManually(String name, String placeName, int quantity) {
    setState(() {
      _items.add(ShoppingItem(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: name,
        placeName: placeName,
        category: '',
        quantity: quantity,
      ));
    });
  }

  void _addFromSuggestion(SuggestionItem suggestion) {
    if (_items.any((e) => e.name == suggestion.name)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${suggestion.name} ya está en tu lista')),
      );
      return;
    }

    setState(() {
      _items.add(ShoppingItem(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: suggestion.name,
        placeName: suggestion.placeName,
        category: '',
      ));
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${suggestion.name} añadido a la lista')),
    );
  }

  void _toggleItem(ShoppingItem item) {
    setState(() {
      item.isPurchased = !item.isPurchased;
    });

    // Mostrar solo un SnackBar de confirmación
    if (item.isPurchased) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✓ ${item.name} marcado como comprado'),
          duration: const Duration(seconds: 2),
          action: SnackBarAction(
            label: 'Deshacer',
            onPressed: () {
              setState(() {
                item.isPurchased = false;
              });
            },
          ),
        ),
      );
    }
  }

  void _removeItem(ShoppingItem item) {
    setState(() {
      _items.remove(item);
    });
  }

  void _showAddItemModal() {
    showDialog(
      context: context,
      builder: (context) => AddItemModalV2(
        onAdd: _addItemManually,
      ),
    );
  }

  List<ShoppingItem> get _pendingItems =>
      _items.where((item) => !item.isPurchased).toList();

  List<ShoppingItem> get _purchasedItems =>
      _items.where((item) => item.isPurchased).toList();

  Map<String, List<ShoppingItem>> _groupItemsByPlace(List<ShoppingItem> items) {
    final grouped = <String, List<ShoppingItem>>{};
    for (var item in items) {
      grouped.putIfAbsent(item.placeName, () => []);
      grouped[item.placeName]!.add(item);
    }
    return grouped;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pendientes'),
      ),
      body: _buildNormalView(),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddItemModal,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildNormalView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Sección de Sugerencias
          SuggestionsSection(
            suggestions: _suggestions,
            onAddToList: _addFromSuggestion,
          ),

          // Lista "Por Comprar"
          _buildPendingSection(),

          const SizedBox(height: 24),

          // Lista "Comprados"
          _buildPurchasedSection(),
        ],
      ),
    );
  }

  Widget _buildPendingSection() {
    final pending = _pendingItems;

    if (pending.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.light
              ? Colors.grey[100]
              : AppTheme.categoryHeaderDark,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(
              Icons.shopping_cart_outlined,
              size: 48,
              color: AppTheme.getTextSecondary(context),
            ),
            const SizedBox(height: 8),
            Consumer<FontSizeProvider>(
              builder: (context, fontSizeProvider, _) => Text(
                '¡Tu lista de compras está vacía!',
                style: TextStyle(
                  fontSize: fontSizeProvider.fontSize,
                  color: AppTheme.getTextSecondary(context),
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      );
    }

    final grouped = _groupItemsByPlace(pending);
    final places = grouped.keys.toList()..sort();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Consumer<FontSizeProvider>(
          builder: (context, fontSizeProvider, _) => Text(
            'Por Comprar',
            style: TextStyle(
              fontSize: fontSizeProvider.fontSize + 4,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 12),
        ...places.map((place) => _buildPlaceGroup(place, grouped[place]!)),
      ],
    );
  }

  Widget _buildPlaceGroup(String place, List<ShoppingItem> items) {
    final isExpanded = _expandedPlaces[place] ?? true;
    final totalItems = items.length;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(
        children: [
          InkWell(
            onTap: () {
              setState(() {
                _expandedPlaces[place] = !isExpanded;
              });
            },
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Icon(
                    isExpanded
                        ? Icons.keyboard_arrow_down
                        : Icons.keyboard_arrow_right,
                    size: 28,
                  ),
                  const SizedBox(width: 8),
                  Icon(Icons.store, color: AppTheme.getPlaceIcon(context)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Consumer<FontSizeProvider>(
                      builder: (context, fontSizeProvider, _) => Text(
                        place,
                        style: TextStyle(
                          fontSize: fontSizeProvider.fontSize + 2,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.getPlaceBadgeBackground(context),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '$totalItems',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).brightness == Brightness.light
                            ? AppTheme.placeIconLight
                            : AppTheme.textPrimaryDark,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (isExpanded) ...[
            const Divider(height: 1),
            ...items.map((item) => ListTile(
                  leading: Checkbox(
                    value: item.isPurchased,
                    onChanged: (_) => _toggleItem(item),
                  ),
                  title: Consumer<FontSizeProvider>(
                    builder: (context, fontSizeProvider, _) => Text(
                      item.name,
                      style: TextStyle(fontSize: fontSizeProvider.fontSize + 2),
                    ),
                  ),
                  subtitle: item.quantity != null && item.quantity! > 1
                      ? Consumer<FontSizeProvider>(
                          builder: (context, fontSizeProvider, _) => Text(
                            'Cantidad: ${item.quantity}',
                            style: TextStyle(
                              fontSize: fontSizeProvider.fontSize - 2,
                              color: AppTheme.getTextSecondary(context),
                            ),
                          ),
                        )
                      : null,
                  trailing: IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    onPressed: () => _removeItem(item),
                  ),
                )),
          ],
        ],
      ),
    );
  }

  Widget _buildPurchasedSection() {
    final purchased = _purchasedItems;

    if (purchased.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Consumer<FontSizeProvider>(
          builder: (context, fontSizeProvider, _) => Text(
            'Comprados',
            style: TextStyle(
              fontSize: fontSizeProvider.fontSize + 4,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Card(
          child: Column(
            children: purchased
                .map((item) => ListTile(
                      leading: Checkbox(
                        value: item.isPurchased,
                        onChanged: (_) => _toggleItem(item),
                      ),
                      title: Consumer<FontSizeProvider>(
                        builder: (context, fontSizeProvider, _) => Text(
                          item.name,
                          style: TextStyle(
                            decoration: TextDecoration.lineThrough,
                            color: AppTheme.getPurchasedColor(context),
                            fontSize: fontSizeProvider.fontSize + 2,
                          ),
                        ),
                      ),
                      subtitle: Consumer<FontSizeProvider>(
                        builder: (context, fontSizeProvider, _) => Text(
                          item.quantity != null && item.quantity! > 1
                              ? '${item.placeName} • Cantidad: ${item.quantity}'
                              : item.placeName,
                          style: TextStyle(
                            fontSize: fontSizeProvider.fontSize - 2,
                            color: AppTheme.getTextSecondary(context),
                          ),
                        ),
                      ),
                      trailing: IconButton(
                        icon: Icon(
                          Icons.delete,
                          color:
                              Theme.of(context).brightness == Brightness.light
                                  ? AppTheme.errorLight
                                  : AppTheme.errorDark,
                        ),
                        onPressed: () => _removeItem(item),
                      ),
                    ))
                .toList(),
          ),
        ),
      ],
    );
  }
}
