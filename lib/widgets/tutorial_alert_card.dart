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
      // location: 'En cualquier lugar',
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
                  margin:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
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
                  margin:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
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
                      Icon(Icons.delete_forever, color: Colors.white, size: 36),
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
    final cardColor = isDarkMode ? Colors.grey.shade900 : Colors.white;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      clipBehavior: Clip.antiAlias,
      child: Container(
        decoration: BoxDecoration(
          color: cardColor,
        ),
        child: Row(
          children: [
            // Barra de color vertical (igual que AlertCard)
            Container(
              width: 5,
              height: 90,
              decoration: BoxDecoration(
                color: alert.color ?? Colors.purple,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  bottomLeft: Radius.circular(16),
                ),
              ),
            ),
            // Contenido
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    // Icono con fondo de color
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: (alert.color ?? Colors.purple).withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color:
                              (alert.color ?? Colors.purple).withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Icon(
                        Icons.swipe,
                        color: alert.color ?? Colors.purple,
                        size: 26,
                      ),
                    ),
                    const SizedBox(width: 16),
                    // Texto
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Tutorial',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: isDarkMode ? Colors.white : Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Desliza para completar o eliminar',
                            style: TextStyle(
                              fontSize: 14,
                              color: isDarkMode
                                  ? Colors.grey.shade400
                                  : Colors.grey.shade600,
                              height: 1.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
