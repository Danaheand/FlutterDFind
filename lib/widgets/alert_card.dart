import 'package:Dfind/models/alert_data.dart';
import 'package:Dfind/utils/alert_utils.dart';
import 'package:Dfind/utils/time_utils.dart';
import 'package:Dfind/providers/font_size_provider.dart';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class AlertCard extends StatelessWidget {
  const AlertCard({
    required this.alert,
    required this.onTap,
    required this.onToggleActive,
    required this.onDelete,
    this.onLongPress,
    this.showCheckbox = false,
    this.checked = false,
  });

  final AlertData alert;
  final VoidCallback onTap;
  final VoidCallback onToggleActive;
  final VoidCallback onDelete;
  final VoidCallback? onLongPress;
  final bool showCheckbox;
  final bool checked;

  Color get _color {
    if (!alert.active) return Colors.grey.shade400;
    return alert.color ?? defaultColorFor(alert.priority);
  }

  @override
  Widget build(BuildContext context) {
    final cardWidget = Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          print('AlertCard onTap - Alert: ${alert.title}');
          onTap();
        },
        onLongPress: onLongPress != null
            ? () {
                print('AlertCard onLongPress - Alert: ${alert.title}');
                onLongPress!();
              }
            : null,
        child: Container(
          decoration: BoxDecoration(
            color: Theme.of(context).brightness == Brightness.light
                ? Colors.white
                : Colors.grey.shade900,
          ),
          child: Row(
            children: [
              // Barra de prioridad vertical a la izquierda
              Container(
                width: 5,
                height: 120,
                decoration: BoxDecoration(
                  color: _color,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    bottomLeft: Radius.circular(16),
                  ),
                ),
              ),
              // Checkbox (si está en modo selección)
              if (showCheckbox)
                Padding(
                  padding: const EdgeInsets.only(left: 12, right: 8),
                  child: Checkbox(
                    value: checked,
                    onChanged: (_) => onTap(),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                ),
              // Contenido principal
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Título en negrita con icono de repetición
                      Row(
                        children: [
                          Expanded(
                            child: Consumer<FontSizeProvider>(
                              builder: (context, fontSizeProvider, _) => Text(
                                alert.title,
                                style: TextStyle(
                                  fontSize: fontSizeProvider.getScaledSize(18),
                                  fontWeight: FontWeight.bold,
                                  color: alert.active
                                      ? (Theme.of(context).brightness == Brightness.light
                                          ? Colors.black87
                                          : Colors.white)
                                      : Colors.grey,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                          // Icono de repetición junto al título
                          if (alert.repetitive) ...[
                            const SizedBox(width: 8),
                            Icon(
                              Icons.repeat,
                              size: 18,
                              color: _color,
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 8),
                      // Etiqueta de prioridad
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: _color.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: _color.withOpacity(0.3),
                            width: 0.5,
                          ),
                        ),
                        child: Text(
                          _getPriorityText(alert.priority),
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: _color,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Fila horizontal: Ubicación + Hora
                      Row(
                        children: [
                          // Ubicación (si existe)
                          if (alert.location?.isNotEmpty ?? false) ...[
                            Icon(
                              Icons.location_on,
                              size: 16,
                              color: Colors.grey.shade600,
                            ),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Consumer<FontSizeProvider>(
                                builder: (context, fontSizeProvider, _) => Text(
                                  alert.location!,
                                  style: TextStyle(
                                    fontSize:
                                        fontSizeProvider.getScaledSize(14),
                                    color: Colors.grey.shade700,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                          ],
                          // Hora con icono de reloj
                          Icon(
                            Icons.access_time,
                            size: 16,
                            color: Colors.grey.shade600,
                          ),
                          const SizedBox(width: 4),
                          Consumer<FontSizeProvider>(
                            builder: (context, fontSizeProvider, _) => Text(
                              TimeUtils.formatTimeWithDay(alert.date),
                              style: TextStyle(
                                fontSize: fontSizeProvider.getScaledSize(14),
                                color: Colors.grey.shade700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              // Badge de tiempo relativo a la derecha
              Padding(
                padding: const EdgeInsets.only(right: 12.0),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: _getTimeBadgeColor(alert.date),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Consumer<FontSizeProvider>(
                    builder: (context, fontSizeProvider, _) => Text(
                      TimeUtils.getRelativeTimeText(alert.date),
                      style: TextStyle(
                        fontSize: fontSizeProvider.getScaledSize(12),
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    // Si no está en modo selección y no tiene checkbox, agregar Dismissible
    if (!showCheckbox) {
      print('🟣 Dismissible habilitado para: ${alert.title}');
      return Dismissible(
        key: Key(alert.id),
        direction: DismissDirection.horizontal,
        confirmDismiss: (direction) async {
          print('🟣 Dismissible confirmDismiss - direction: $direction');
          if (direction == DismissDirection.startToEnd) {
            print('🟣 Deslizar a la derecha - Activar/Pausar');
            // Deslizar a la derecha: completar/activar
            onToggleActive();
            return false; // No eliminar el widget
          } else {
            print('🟣 Deslizar a la izquierda - Eliminar');
            // Deslizar a la izquierda: eliminar
            return true; // Confirmar eliminación
          }
        },
        onDismissed: (direction) {
          print('🟣 Dismissible onDismissed - direction: $direction');
          if (direction == DismissDirection.endToStart) {
            onDelete();
          }
        },
        background: Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.green.shade400,
            borderRadius: BorderRadius.circular(16),
          ),
          alignment: Alignment.centerLeft,
          padding: const EdgeInsets.only(left: 30),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                alert.active ? Icons.pause_circle_filled : Icons.check_circle,
                color: Colors.white,
                size: 36,
              ),
              const SizedBox(height: 4),
              Text(
                alert.active ? 'Completar' : 'Activar',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
        secondaryBackground: Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.red.shade400,
            borderRadius: BorderRadius.circular(16),
          ),
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 30),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.delete_forever,
                color: Colors.white,
                size: 36,
              ),
              const SizedBox(height: 4),
              const Text(
                'Eliminar',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
        child: cardWidget,
      );
    }

    return cardWidget;
  }

  /// Obtiene el texto de la prioridad
  String _getPriorityText(AlertPriority priority) {
    switch (priority) {
      case AlertPriority.alta:
        return 'Alta';
      case AlertPriority.media:
        return 'Media';
      case AlertPriority.baja:
        return 'Baja';
    }
  }

  /// Obtiene el color del badge de tiempo relativo según la urgencia
  Color _getTimeBadgeColor(DateTime targetDate) {
    final now = DateTime.now();
    final difference = targetDate.difference(now);

    if (difference.isNegative) {
      return Colors.red.shade400; // Vencida
    } else if (difference.inHours < 1) {
      return Colors.orange.shade400; // Muy urgente
    } else if (difference.inHours < 24) {
      return Colors.amber.shade400; // Urgente
    } else if (difference.inDays <= 1) {
      return Colors.blue.shade400; // Mañana
    } else {
      return Colors.grey.shade400; // Futuro
    }
  }
}
