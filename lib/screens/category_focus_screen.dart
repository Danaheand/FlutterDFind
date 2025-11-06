import 'package:flutter/material.dart';
import '../models/shopping_item.dart';
import '../theme/app_theme.dart';

class CategoryFocusScreen extends StatefulWidget {
  final String category;
  final List<ShoppingItem> items;
  final Function(ShoppingItem) onToggleItem;

  const CategoryFocusScreen({
    super.key,
    required this.category,
    required this.items,
    required this.onToggleItem,
  });

  @override
  State<CategoryFocusScreen> createState() => _CategoryFocusScreenState();
}

class _CategoryFocusScreenState extends State<CategoryFocusScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.category),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: widget.items.isEmpty
          ? Center(
              child: Text(
                'No hay artículos en esta categoría',
                style: TextStyle(
                  fontSize: 18,
                  color: AppTheme.getTextSecondary(context),
                ),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: widget.items.length,
              itemBuilder: (context, index) {
                final item = widget.items[index];
                return Card(
                  elevation: 2,
                  margin: const EdgeInsets.only(bottom: 16),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Transform.scale(
                          scale: 1.5,
                          child: Checkbox(
                            value: item.isPurchased,
                            onChanged: (_) => widget.onToggleItem(item),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.name,
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  decoration: item.isPurchased
                                      ? TextDecoration.lineThrough
                                      : null,
                                  color: item.isPurchased
                                      ? AppTheme.getPurchasedColor(context)
                                      : null,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Icon(
                                    Icons.store,
                                    size: 16,
                                    color: AppTheme.getTextSecondary(context),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    item.placeName,
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: AppTheme.getTextSecondary(context),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: ElevatedButton.icon(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.arrow_back),
          label: const Text('VOLVER A PASILLOS'),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
        ),
      ),
    );
  }
}
