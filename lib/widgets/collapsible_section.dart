import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:Dfind/models/alert_data.dart';
import 'package:Dfind/theme/app_theme.dart';
import 'package:Dfind/providers/font_size_provider.dart';

/// Widget que muestra una sección colapsable con un contador de elementos
class CollapsibleSection extends StatefulWidget {
  final String title;
  final int count;
  final List<Widget> children;
  final Color? headerColor;
  final bool initiallyExpanded;
  final IconData? icon;

  const CollapsibleSection({
    super.key,
    required this.title,
    required this.count,
    required this.children,
    this.headerColor,
    this.initiallyExpanded = true,
    this.icon,
  });

  @override
  State<CollapsibleSection> createState() => _CollapsibleSectionState();
}

class _CollapsibleSectionState extends State<CollapsibleSection> {
  late bool _isExpanded;

  @override
  void initState() {
    super.initState();
    _isExpanded = widget.initiallyExpanded;
  }

  /// Obtiene el color del header adaptado al modo oscuro
  Color _getHeaderColor(BuildContext context) {
    if (widget.headerColor == null) {
      return Theme.of(context).brightness == Brightness.light 
          ? Colors.grey.shade100 
          : Colors.grey.shade800;
    }

    // Si se proporciona un color personalizado, adaptarlo al modo oscuro
    if (Theme.of(context).brightness == Brightness.light) {
      return widget.headerColor!;
    }

    // Mapeo de colores light a dark
    if (widget.headerColor == Colors.amber.shade50) {
      return Colors.amber.shade900;
    } else if (widget.headerColor == Colors.red.shade50) {
      return Colors.red.shade900;
    } else if (widget.headerColor == Colors.orange.shade50) {
      return Colors.orange.shade900;
    } else if (widget.headerColor == Colors.green.shade50) {
      return Colors.green.shade900;
    } else if (widget.headerColor == Colors.grey.shade200) {
      return Colors.grey.shade700;
    }

    return widget.headerColor!;
  }

  /// Obtiene el color de texto adaptado al modo oscuro
  Color _getTextColor(BuildContext context) {
    if (widget.headerColor == null) {
      return Theme.of(context).brightness == Brightness.light
          ? Colors.black87
          : Colors.white;
    }

    // Para colores personalizados, usar blanco en dark mode
    return Theme.of(context).brightness == Brightness.light
        ? Colors.black87
        : Colors.white;
  }

  @override
  Widget build(BuildContext context) {
    if (widget.count == 0) {
      return const SizedBox.shrink();
    }

    return Consumer<FontSizeProvider>(
      builder: (context, fontSizeProvider, _) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: () {
              setState(() {
                _isExpanded = !_isExpanded;
              });
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: _getHeaderColor(context),
                borderRadius: BorderRadius.circular(12),
              ),
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  if (widget.icon != null) ...[
                    Icon(
                      widget.icon,
                      size: 20,
                      color: _getTextColor(context),
                    ),
                    const SizedBox(width: 12),
                  ],
                  Expanded(
                    child: Text(
                      widget.title,
                      style: TextStyle(
                        fontSize: fontSizeProvider.fontSize,
                        fontWeight: FontWeight.bold,
                        color: _getTextColor(context),
                      ),
                    ),
                  ),
                  // Badge con contador
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Theme.of(context).brightness == Brightness.light
                          ? Colors.white
                          : Colors.grey.shade700,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Text(
                      '${widget.count}',
                      style: TextStyle(
                        fontSize: fontSizeProvider.fontSize - 2,
                        fontWeight: FontWeight.bold,
                        color: _getTextColor(context),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Icono de expandir/colapsar
                  Icon(
                    _isExpanded
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    size: 24,
                    color: _getTextColor(context),
                  ),
                ],
              ),
            ),
          ),
          // Contenido colapsable
          if (_isExpanded) ...[
            ...widget.children,
            const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }
}

/// Banner especial para alertas vencidas con estilo rojo
class ExpiredAlertsBanner extends StatefulWidget {
  final List<AlertData> expiredAlerts;
  final List<Widget> children;

  const ExpiredAlertsBanner({
    super.key,
    required this.expiredAlerts,
    required this.children,
  });

  @override
  State<ExpiredAlertsBanner> createState() => _ExpiredAlertsBannerState();
}

class _ExpiredAlertsBannerState extends State<ExpiredAlertsBanner> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    if (widget.expiredAlerts.isEmpty) {
      return const SizedBox.shrink();
    }

    return Consumer<FontSizeProvider>(
      builder: (context, fontSizeProvider, _) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: () {
              setState(() {
                _isExpanded = !_isExpanded;
              });
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppTheme.primaryLight,
                    AppTheme.primaryDark,
                  ],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: const Color.fromARGB(255, 111, 102, 124).withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  // Icono de advertencia
                  const Icon(
                    Icons.warning_rounded,
                    size: 24,
                    color: Colors.white,
                  ),
                  const SizedBox(width: 12),
                  // Texto
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Alertas Vencidas',
                          style: TextStyle(
                            fontSize: fontSizeProvider.fontSize,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          '${widget.expiredAlerts.length} recordatorio${widget.expiredAlerts.length > 1 ? 's' : ''} pendiente${widget.expiredAlerts.length > 1 ? 's' : ''}',
                          style: TextStyle(
                            fontSize: fontSizeProvider.fontSize - 3,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Badge con contador
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${widget.expiredAlerts.length}',
                      style: TextStyle(
                        fontSize: fontSizeProvider.fontSize - 1,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryLight,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Icono de expandir/colapsar
                  Icon(
                    _isExpanded
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    size: 28,
                    color: Colors.white,
                  ),
                ],
              ),
            ),
          ),
          // Contenido colapsable
          if (_isExpanded) ...[
            ...widget.children,
            const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }
}
