import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/font_size_provider.dart';
import '../../theme/app_theme.dart';

class TipsRecordatorios extends StatefulWidget {
  const TipsRecordatorios({super.key});

  @override
  State<TipsRecordatorios> createState() => _TipsRecordatoriosState();
}

class _TipsRecordatoriosState extends State<TipsRecordatorios> {
  bool _expandTips = false;

  @override
  Widget build(BuildContext context) {
    final bool isLight = Theme.of(context).brightness == Brightness.light;

    final tips = [
      TipItem(
        icon: Icons.add_alert_rounded,
        title: 'Crear recordatorio',
        description: 'Toca el botón "+" para añadir un nuevo recordatorio',
        color: isLight ? AppTheme.primaryLight : AppTheme.primaryDark,
      ),
      TipItem(
        icon: Icons.repeat_rounded,
        title: 'Recordatorios repetitivos',
        description: 'Configura alertas que se repitan en días específicos',
        color: isLight ? AppTheme.successLight : AppTheme.successDark,
      ),
      TipItem(
        icon: Icons.priority_high,
        title: 'Gestiona prioridades',
        description:
            'Asigna prioridades (Alta, Media, Baja) a tus recordatorios',
        color: isLight ? AppTheme.warningLight : AppTheme.warningDark,
      ),
      TipItem(
        icon: Icons.location_on_outlined,
        title: 'Añade ubicaciones',
        description: 'Indica dónde y qué objeto necesitas recordar',
        color: isLight ? AppTheme.secondaryLight : AppTheme.secondaryDark,
      ),
      TipItem(
        icon: Icons.gesture,
        title: 'Gestos en alertas',
        description:
            'Mantén presionado para seleccionar múltiples. Desliza derecha para activar (verde). Desliza izquierda para eliminar (rojo).',
        color: isLight ? AppTheme.primaryLight : AppTheme.primaryDark,
      ),
    ];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
          // Header - Clickeable para expandir/contraer
          GestureDetector(
            onTap: () => setState(() => _expandTips = !_expandTips),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isLight
                    ? AppTheme.surfaceLight.withOpacity(0.8)
                    : AppTheme.cardDark.withOpacity(0.5),
                borderRadius: _expandTips
                    ? const BorderRadius.only(
                        topLeft: Radius.circular(16),
                        topRight: Radius.circular(16),
                      )
                    : BorderRadius.circular(16),
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
                      color: isLight
                          ? AppTheme.primaryLight
                          : AppTheme.primaryDark,
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
                            'Tips de Recordatorios',
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
                            'Aprovecha todas las características',
                            style: TextStyle(
                              fontSize: fontSizeProvider.fontSize - 2,
                              color: AppTheme.getTextSecondary(context),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    _expandTips ? Icons.expand_less : Icons.expand_more,
                    color:
                        isLight ? AppTheme.primaryLight : AppTheme.primaryDark,
                    size: 24,
                  ),
                ],
              ),
            ),
          ),

          // Tips List - Se expande/contrae
          if (_expandTips)
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children:
                    tips.map((tip) => _buildTipCard(context, tip)).toList(),
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
