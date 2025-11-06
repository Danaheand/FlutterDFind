import 'package:flutter/material.dart';
import '../../models/shopping_item.dart';
import '../../theme/app_theme.dart';

class ShoppingModeView extends StatelessWidget {
  final List<ShoppingItem> pendingItems;
  final Function(String place) onPlaceTap;

  const ShoppingModeView({
    super.key,
    required this.pendingItems,
    required this.onPlaceTap,
  });

  Map<String, int> _getPlaceCounts() {
    final counts = <String, int>{};
    for (var item in pendingItems) {
      counts[item.placeName] = (counts[item.placeName] ?? 0) + 1;
    }
    return counts;
  }

  @override
  Widget build(BuildContext context) {
  final placeCounts = _getPlaceCounts();
  final places = placeCounts.keys.toList()..sort();

  if (places.isEmpty) {
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
                      'Selecciona un lugar para comenzar',
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
            itemCount: places.length,
            itemBuilder: (context, index) {
              final place = places[index];
              final count = placeCounts[place]!;
              final itemsInPlace = pendingItems.where((item) => item.placeName == place).toList();
              final firstItemName = itemsInPlace.isNotEmpty ? itemsInPlace.first.name : '';

              return Card(
                elevation: 2,
                margin: const EdgeInsets.only(bottom: 12),
                child: InkWell(
                  onTap: () => onPlaceTap(place),
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
                            Icons.store,
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
                                place,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              if (firstItemName.isNotEmpty) ...[
                                const SizedBox(height: 2),
                                Text(
                                  firstItemName,
                                  style: TextStyle(
                                    fontSize: 15,
                                    color: AppTheme.getTextSecondary(context),
                                  ),
                                ),
                              ],
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
