import 'package:flutter/material.dart';
import '../../models/suggestion_item.dart';
import '../../theme/app_theme.dart';

class SuggestionsSection extends StatelessWidget {
  final List<SuggestionItem> suggestions;
  final Function(SuggestionItem) onAddToList;

  const SuggestionsSection({
    super.key,
    required this.suggestions,
    required this.onAddToList,
  });

  @override
  Widget build(BuildContext context) {
    if (suggestions.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppTheme.getSuggestionBackground(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.getSuggestionBorder(context),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Icon(
                  Icons.lightbulb,
                  color: AppTheme.getSuggestionIcon(context),
                ),
                const SizedBox(width: 8),
                Text(
                  'Tips para el uso',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).brightness == Brightness.light
                        ? AppTheme.suggestionIconLight
                        : AppTheme.textPrimaryDark,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: suggestions.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final item = suggestions[index];
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor:
                      Theme.of(context).brightness == Brightness.light
                          ? AppTheme.suggestionBorderLight.withOpacity(0.3)
                          : AppTheme.shoppingModeTileDark,
                  child: Icon(
                    _getIconForReason(item.reason),
                    color: AppTheme.getSuggestionIcon(context),
                    size: 20,
                  ),
                ),
                title: Text(
                  item.name,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                subtitle: Text(
                  item.reason,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.getTextSecondary(context),
                  ),
                ),
                trailing: OutlinedButton(
                  onPressed: () => onAddToList(item),
                  style: OutlinedButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                  ),
                  child: const Text('AÑADIR'),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  IconData _getIconForReason(String reason) {
    if (reason.toLowerCase().contains('stock bajo')) {
      return Icons.warning_amber_rounded;
    } else if (reason.toLowerCase().contains('frecuente')) {
      return Icons.repeat;
    } else if (reason.toLowerCase().contains('caducidad')) {
      return Icons.schedule;
    }
    return Icons.info_outline;
  }
}
