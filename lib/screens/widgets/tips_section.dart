import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/font_size_provider.dart';
import '../../theme/app_theme.dart';

class TipsSection extends StatelessWidget {
  const TipsSection({super.key});

  @override
  Widget build(BuildContext context) {
    final bool isLight = Theme.of(context).brightness == Brightness.light;

    final tips = [
      TipItem(
        icon: Icons.touch_app,
        title: 'Marca como comprado',
        description: 'Toca el checkbox para marcar un artículo como comprado',
        color: isLight ? AppTheme.primaryLight : AppTheme.primaryDark,
      ),
      TipItem(
        icon: Icons.store,
        title: 'Organiza por lugar',
        description: 'Los artículos se agrupan automáticamente por tienda',
        color: isLight ? AppTheme.successLight : AppTheme.successDark,
      ),
      TipItem(
        icon: Icons.notifications_active,
        title: 'Activa alertas',
        description:
            'Recibe notificaciones cuando un producto esté por agotarse',
        color: isLight ? AppTheme.warningLight : AppTheme.warningDark,
      ),
      TipItem(
        icon: Icons.inventory_2,
        title: 'Gestiona tu inventario',
        description: 'Mantén un registro de todos tus productos en casa',
        color: isLight ? AppTheme.secondaryLight : AppTheme.secondaryDark,
      ),
    ];

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isLight
              ? [
                  AppTheme.primaryLight.withOpacity(0.1),
                  AppTheme.secondaryLight.withOpacity(0.1),
                ]
              : [
                  AppTheme.primaryDark.withOpacity(0.15),
                  AppTheme.secondaryDark.withOpacity(0.15),
                ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isLight
              ? AppTheme.primaryLight.withOpacity(0.3)
              : AppTheme.primaryDark.withOpacity(0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: isLight
                ? AppTheme.primaryLight.withOpacity(0.1)
                : Colors.black.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isLight
                  ? AppTheme.surfaceLight.withOpacity(0.8)
                  : AppTheme.cardDark.withOpacity(0.5),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isLight
                        ? AppTheme.primaryLight.withOpacity(0.15)
                        : AppTheme.primaryDark.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.lightbulb_rounded,
                    color:
                        isLight ? AppTheme.primaryLight : AppTheme.primaryDark,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Consumer<FontSizeProvider>(
                        builder: (context, fontSizeProvider, _) => Text(
                          'Tips para el uso',
                          style: TextStyle(
                            fontSize: fontSizeProvider.fontSize + 4,
                            fontWeight: FontWeight.bold,
                            color: isLight
                                ? AppTheme.primaryLight
                                : AppTheme.primaryDark,
                          ),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Consumer<FontSizeProvider>(
                        builder: (context, fontSizeProvider, _) => Text(
                          'Aprovecha al máximo la aplicación',
                          style: TextStyle(
                            fontSize: fontSizeProvider.fontSize - 2,
                            color: AppTheme.getTextSecondary(context),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Tips List
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: tips.map((tip) => _buildTipCard(context, tip)).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTipCard(BuildContext context, TipItem tip) {
    final bool isLight = Theme.of(context).brightness == Brightness.light;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isLight ? AppTheme.cardLight : AppTheme.cardDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isLight ? AppTheme.dividerLight : AppTheme.dividerDark,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: tip.color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              tip.icon,
              color: tip.color,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Consumer<FontSizeProvider>(
                  builder: (context, fontSizeProvider, _) => Text(
                    tip.title,
                    style: TextStyle(
                      fontSize: fontSizeProvider.fontSize,
                      fontWeight: FontWeight.bold,
                      color: isLight
                          ? AppTheme.textPrimaryLight
                          : AppTheme.textPrimaryDark,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Consumer<FontSizeProvider>(
                  builder: (context, fontSizeProvider, _) => Text(
                    tip.description,
                    style: TextStyle(
                      fontSize: fontSizeProvider.fontSize - 2,
                      color: AppTheme.getTextSecondary(context),
                      height: 1.3,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.arrow_forward_ios_rounded,
            size: 16,
            color: AppTheme.getTextSecondary(context),
          ),
        ],
      ),
    );
  }
}

class TipItem {
  final IconData icon;
  final String title;
  final String description;
  final Color color;

  TipItem({
    required this.icon,
    required this.title,
    required this.description,
    required this.color,
  });
}
