import 'package:flutter/material.dart';
import '../models/alert_data.dart';

class TutorialAlertCard extends StatefulWidget {
  final Animation<double>? slideAnimation;

  const TutorialAlertCard({
    super.key,
    this.slideAnimation,
  });

  @override
  State<TutorialAlertCard> createState() => _TutorialAlertCardState();
}

class _TutorialAlertCardState extends State<TutorialAlertCard> {
  @override
  Widget build(BuildContext context) {
    final tutorialAlert = AlertData(
      id: 'tutorial-alert-001',
      title: 'Tutorial: Organiza tus tareas',
      description:
          'Desliza a la derecha para completar o a la izquierda para eliminar',
      date: DateTime.now().add(const Duration(hours: 2)),
      priority: AlertPriority.media,
      location: 'En cualquier lugar',
      object: '',
      repetitive: false,
      repeatFrequency: '',
      active: true,
      completed: false,
      color: const Color(0xFF6A4C93),
      imagePath: null,
      selectedWeekdays: null,
    );

    if (widget.slideAnimation == null) {
      return const SizedBox.shrink();
    }

    return AbsorbPointer(
      absorbing: true,
      child: Stack(
        children: [
          // Fondo verde - completar
          AnimatedBuilder(
            animation: widget.slideAnimation!,
            builder: (context, child) {
              if (widget.slideAnimation!.value <= 0) {
                return const SizedBox.shrink();
              }
              return Positioned.fill(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.green.shade400,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  alignment: Alignment.centerLeft,
                  padding: const EdgeInsets.only(left: 30),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.check_circle, color: Colors.white, size: 36),
                      const SizedBox(height: 4),
                      const Text('Completar',
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 14)),
                    ],
                  ),
                ),
              );
            },
          ),
          // Fondo rojo - eliminar
          AnimatedBuilder(
            animation: widget.slideAnimation!,
            builder: (context, child) {
              if (widget.slideAnimation!.value >= 0) {
                return const SizedBox.shrink();
              }
              return Positioned.fill(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.red.shade400,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 30),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.delete_forever,
                          color: Colors.white, size: 36),
                      const SizedBox(height: 4),
                      const Text('Eliminar',
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 14)),
                    ],
                  ),
                ),
              );
            },
          ),
          // Tarjeta tutorial
          AnimatedBuilder(
            animation: widget.slideAnimation!,
            builder: (context, child) {
              return Transform.translate(
                offset: Offset(widget.slideAnimation!.value, 0),
                child: child,
              );
            },
            child: _buildCard(context, tutorialAlert),
          ),
        ],
      ),
    );
  }

  Widget _buildCard(BuildContext context, AlertData alert) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.grey.shade900 : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Opacity(
        opacity: 0.7,
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          alert.title,
                          style: theme.textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w700),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          alert.description,
                          style: theme.textTheme.bodySmall
                              ?.copyWith(
                                  color: theme.textTheme.bodySmall?.color
                                      ?.withOpacity(0.7))
                              ,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: alert.color?.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: alert.color ?? Colors.grey,
                        width: 1,
                      ),
                    ),
                    child: Text(
                      alert.priority.name.toUpperCase(),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: alert.color,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (alert.location != null && alert.location!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Icon(Icons.location_on_outlined,
                          size: 14,
                          color: theme.textTheme.bodySmall?.color
                              ?.withOpacity(0.6)),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          alert.location!,
                          style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.textTheme.bodySmall?.color
                                  ?.withOpacity(0.6)),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              Row(
                children: [
                  Icon(Icons.schedule_outlined,
                      size: 14,
                      color: theme.textTheme.bodySmall?.color
                          ?.withOpacity(0.6)),
                  const SizedBox(width: 6),
                  Text(
                    '${alert.date.hour}:${alert.date.minute.toString().padLeft(2, '0')} - Hoy',
                    style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.textTheme.bodySmall?.color
                            ?.withOpacity(0.6)),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Colors.blue.shade200,
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline,
                        size: 16, color: Colors.blue.shade600),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Tutorial: Desliza para ver las acciones disponibles',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.blue.shade600,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
