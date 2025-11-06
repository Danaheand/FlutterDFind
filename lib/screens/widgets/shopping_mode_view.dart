import 'package:flutter/material.dart';
import '../../models/shopping_item.dart';
import '../../theme/app_theme.dart';

class ShoppingModeView extends StatelessWidget {
  final List<ShoppingItem> pendingItems;
  final Function(String category) onCategoryTap;

  const ShoppingModeView({
    super.key,
    required this.pendingItems,
    required this.onCategoryTap,
  });

  Map<String, int> _getCategoryCounts() {
    final counts = <String, int>{};
    for (var item in pendingItems) {
      counts[item.category] = (counts[item.category] ?? 0) + 1;
    }
    return counts;
  }

  @override
  Widget build(BuildContext context) {
    final categoryCounts = _getCategoryCounts();
    final categories = categoryCounts.keys.toList()..sort();

    if (categories.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.shopping_cart_outlined,
              size: 64,
              color: AppTheme.getTextSecondary(context),
            ),
            const SizedBox(height: 16),
            Text(
              'No hay artículos pendientes',
              style: TextStyle(
                fontSize: 18,
                color: AppTheme.getTextSecondary(context),
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          color: AppTheme.getShoppingModeBackground(context),
          child: Row(
            children: [
              Icon(
                Icons.shopping_basket,
                color: AppTheme.getPlaceIcon(context),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Modo Compras',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    Text(
                      'Selecciona un pasillo para comenzar',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppTheme.getTextSecondary(context),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: categories.length,
            itemBuilder: (context, index) {
              final category = categories[index];
              final count = categoryCounts[category]!;

              return Card(
                elevation: 2,
                margin: const EdgeInsets.only(bottom: 12),
                child: InkWell(
                  onTap: () => onCategoryTap(category),
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      children: [
                        Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            color: AppTheme.getShoppingModeTile(context),
                            borderRadius: BorderRadius.circular(28),
                          ),
                          child: Icon(
                            Icons.category,
                            size: 32,
                            color:
                                Theme.of(context).brightness == Brightness.light
                                    ? AppTheme.placeIconLight
                                    : AppTheme.textPrimaryDark,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                category,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '$count ${count == 1 ? 'artículo' : 'artículos'}',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: AppTheme.getTextSecondary(context),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          Icons.arrow_forward_ios,
                          color: AppTheme.getTextSecondary(context),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
