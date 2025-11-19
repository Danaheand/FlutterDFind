// import 'package:Dfind/screens/recordatorios_detalle_screen.dart';
import 'package:Dfind/models/alert_data.dart';
import 'package:Dfind/utils/alert_utils.dart';

import 'package:flutter/material.dart';

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
    final dateText = dateLabel(alert.date);
    // Detect if this alert is in 'pasadas' tab
    final isPasada = alert.date.isBefore(DateTime.now());

    final cardWidget = Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: _color.withOpacity(0.3), width: 1.5),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          print('🔵 AlertCard onTap - Alert: ${alert.title}');
          onTap();
        },
        onLongPress: onLongPress != null
            ? () {
                print('🟡 AlertCard onLongPress - Alert: ${alert.title}');
                onLongPress!();
              }
            : null,
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                _color.withOpacity(0.05),
                _color.withOpacity(0.02),
              ],
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                if (showCheckbox)
                  Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: Checkbox(
                      value: checked,
                      onChanged: (_) => onTap(),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                  ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Título grande y prominente
                      Text(
                        alert.title,
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: alert.active ? Colors.black87 : Colors.black38,
                          letterSpacing: -0.5,
                          height: 1.2,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 16),
                      // Fecha y hora con icono
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: _color.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              Icons.calendar_today_rounded,
                              color: _color,
                              size: 18,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  dateText,
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey.shade700,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Text(
                                  '${alert.date.hour.toString().padLeft(2, '0')}:${alert.date.minute.toString().padLeft(2, '0')}',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey.shade500,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      // Objeto (si existe)
                      if (alert.object?.isNotEmpty ?? false) ...[
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: _color.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(
                                Icons.inventory_2_outlined,
                                color: _color,
                                size: 18,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                alert.object!,
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey.shade700,
                                  fontWeight: FontWeight.w500,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                // Menú de opciones
                PopupMenuButton<String>(
                  icon: Icon(
                    Icons.more_vert_rounded,
                    color: Colors.grey.shade600,
                    size: 24,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  onSelected: (v) {
                    if (isPasada) {
                      if (v == 'delete') onDelete();
                    } else {
                      switch (v) {
                        case 'toggle':
                          onToggleActive();
                          break;
                        case 'delete':
                          onDelete();
                          break;
                      }
                    }
                  },
                  itemBuilder: (ctx) => isPasada
                      ? [
                          const PopupMenuItem(
                            value: 'delete',
                            child: Row(
                              children: [
                                Icon(Icons.delete_outline, size: 20),
                                SizedBox(width: 12),
                                Text('Eliminar'),
                              ],
                            ),
                          ),
                        ]
                      : [
                          PopupMenuItem(
                            value: 'toggle',
                            child: Row(
                              children: [
                                Icon(
                                  alert.active
                                      ? Icons.pause_circle_outline
                                      : Icons.play_circle_outline,
                                  size: 20,
                                ),
                                const SizedBox(width: 12),
                                Text(alert.active ? 'Desactivar' : 'Activar'),
                              ],
                            ),
                          ),
                          const PopupMenuItem(
                            value: 'delete',
                            child: Row(
                              children: [
                                Icon(Icons.delete_outline, size: 20),
                                SizedBox(width: 12),
                                Text('Eliminar'),
                              ],
                            ),
                          ),
                        ],
                ),
              ],
            ),
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
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.green.shade400,
            borderRadius: BorderRadius.circular(20),
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
                alert.active ? 'Pausar' : 'Activar',
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
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.red.shade400,
            borderRadius: BorderRadius.circular(20),
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
}
