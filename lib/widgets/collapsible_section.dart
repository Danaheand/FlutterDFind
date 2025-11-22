import 'package:flutter/material.dart';
import 'package:Dfind/models/alert_data.dart';
import 'package:Dfind/theme/app_theme.dart';

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

  @override
  Widget build(BuildContext context) {
    if (widget.count == 0) {
      return const SizedBox.shrink();
    }

    return Column(
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
              color: widget.headerColor ?? Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
            ),
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                if (widget.icon != null) ...[
                  Icon(
                    widget.icon,
                    size: 20,
                    color: Colors.black87,
                  ),
                  const SizedBox(width: 12),
                ],
                Expanded(
                  child: Text(
                    widget.title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
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
                    color: Colors.white,
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
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
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
                  color: Colors.black87,
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

    return Column(
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
                      const Text(
                        'Alertas Vencidas',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        '${widget.expiredAlerts.length} recordatorio${widget.expiredAlerts.length > 1 ? 's' : ''} pendiente${widget.expiredAlerts.length > 1 ? 's' : ''}',
                        style: const TextStyle(
                          fontSize: 12,
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
                      fontSize: 16,
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
    );
  }
}
