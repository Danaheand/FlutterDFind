import 'package:flutter/material.dart';
import '../models/shopping_item.dart';
import '../models/suggestion_item.dart';
import '../theme/app_theme.dart';
import 'widgets/add_item_modal_v2.dart';
import 'widgets/update_inventory_modal_v2.dart';
import 'widgets/suggestions_section.dart';
import 'widgets/shopping_mode_view.dart';
import 'category_focus_screen.dart';

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
  bool _isShoppingMode = false;

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
        category: 'General',
      ));
    });
  }

  void _addItemManually(String name, String placeName, String category) {
    setState(() {
      _items.add(ShoppingItem(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: name,
        placeName: placeName,
        category: category,
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
        category: suggestion.category,
      ));
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${suggestion.name} añadido a la lista')),
    );
  }

  void _toggleItem(ShoppingItem item) {
    final wasNotPurchased = !item.isPurchased;

    setState(() {
      item.isPurchased = !item.isPurchased;
    });

    if (wasNotPurchased) {
      // Marcar como comprado -> mostrar modal
      _showUpdateInventoryModal(item);
    }
    // Si se desmarca, solo vuelve a "Por Comprar" sin modal
  }

  void _showUpdateInventoryModal(ShoppingItem item) {
    showDialog(
      context: context,
      builder: (context) => UpdateInventoryModalV2(
        itemName: item.name,
        onUpdate: (quantity, expirationDate) {
          // Aquí se conectaría con el sistema de inventario
          setState(() {
            item.quantity = quantity;
            item.expirationDate = expirationDate;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Inventario actualizado')),
          );
        },
        onSkip: () {
          // Solo marcar, no actualizar inventario
        },
      ),
    );
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

  Map<String, Map<String, List<ShoppingItem>>> _groupItems(
      List<ShoppingItem> items) {
    final grouped = <String, Map<String, List<ShoppingItem>>>{};

    for (var item in items) {
      grouped.putIfAbsent(item.placeName, () => {});
      grouped[item.placeName]!.putIfAbsent(item.category, () => []);
      grouped[item.placeName]![item.category]!.add(item);
    }

    return grouped;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lista de Compras'),
        actions: [
          Row(
            children: [
              const Text('Modo Compras'),
              Switch(
                value: _isShoppingMode,
                onChanged: (value) {
                  setState(() => _isShoppingMode = value);
                },
              ),
            ],
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _isShoppingMode
          ? ShoppingModeView(
              pendingItems: _pendingItems,
              onCategoryTap: (category) {
                final itemsInCategory = _pendingItems
                    .where((item) => item.category == category)
                    .toList();

                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => CategoryFocusScreen(
                      category: category,
                      items: itemsInCategory,
                      onToggleItem: _toggleItem,
                    ),
                  ),
                );
              },
            )
          : _buildNormalView(),
      floatingActionButton: !_isShoppingMode
          ? FloatingActionButton(
              onPressed: _showAddItemModal,
              child: const Icon(Icons.add),
            )
          : null,
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
            Text(
              '¡Tu lista de compras está vacía!',
              style: TextStyle(
                fontSize: 16,
                color: AppTheme.getTextSecondary(context),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    final grouped = _groupItems(pending);
    final places = grouped.keys.toList()..sort();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Por Comprar',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        ...places.map((place) => _buildPlaceGroup(place, grouped[place]!)),
      ],
    );
  }

  Widget _buildPlaceGroup(
      String place, Map<String, List<ShoppingItem>> categories) {
    final isExpanded = _expandedPlaces[place] ?? true;
    final totalItems =
        categories.values.fold(0, (sum, items) => sum + items.length);

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
                    child: Text(
                      place,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
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
            ...categories.entries
                .map((entry) => _buildCategoryGroup(entry.key, entry.value)),
          ],
        ],
      ),
    );
  }

  Widget _buildCategoryGroup(String category, List<ShoppingItem> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          color: AppTheme.getCategoryHeader(context),
          child: Row(
            children: [
              Icon(
                Icons.category,
                size: 16,
                color: AppTheme.getCategoryIcon(context),
              ),
              const SizedBox(width: 8),
              Text(
                category,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.getCategoryIcon(context),
                ),
              ),
            ],
          ),
        ),
        ...items.map((item) => ListTile(
              leading: Checkbox(
                value: item.isPurchased,
                onChanged: (_) => _toggleItem(item),
              ),
              title: Text(item.name),
              trailing: IconButton(
                icon: const Icon(Icons.close, size: 20),
                onPressed: () => _removeItem(item),
              ),
            )),
      ],
    );
  }

  Widget _buildPurchasedSection() {
    final purchased = _purchasedItems;

    if (purchased.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Comprados',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
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
                      title: Text(
                        item.name,
                        style: TextStyle(
                          decoration: TextDecoration.lineThrough,
                          color: AppTheme.getPurchasedColor(context),
                        ),
                      ),
                      subtitle: Text(
                        '${item.placeName} • ${item.category}',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.getTextSecondary(context),
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
