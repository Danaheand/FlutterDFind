import 'dart:typed_data';
import 'package:Dfind/models/alert_data.dart';
import 'package:flutter/material.dart';
import "package:Dfind/utils/alert_utils.dart";
import 'package:image_picker/image_picker.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:provider/provider.dart';
import '../providers/recordatorio_provider.dart';
import '../models/recordatorio_exception.dart';
import '../models/recordatorio.dart';
import '../services/trash_service.dart';
import '../services/session_manager.dart';
import '../models/trash_item.dart';

// enum AlertPriority { baja, media, alta }

class WeekDay {
  final String label;
  final String fullName;
  final int value;

  WeekDay(this.label, this.fullName, this.value);
}

final List<WeekDay> weekDays = [
  WeekDay('L', 'Lunes', 1),
  WeekDay('M', 'Martes', 2),
  WeekDay('X', 'Miércoles', 3),
  WeekDay('J', 'Jueves', 4),
  WeekDay('V', 'Viernes', 5),
  WeekDay('S', 'Sábado', 6),
  WeekDay('D', 'Domingo', 7),
];

// Color defaultColorFor(AlertPriority p) {
//   switch (p) {
//     case AlertPriority.alta:
//       return Colors.red.shade400;
//     case AlertPriority.media:
//       return Colors.amber.shade600;
//     case AlertPriority.baja:
//       return Colors.blue.shade400;
//   }
// }

// class AlertData {
//   String id;
//   String title;
//   String description;
//   DateTime date;
//   AlertPriority priority;
//   String? location;
//   String? object;
//   bool repetitive;
//   String? repeatFrequency;
//   bool active;
//   Color? color;
//   String? imagePath;
//   List<int>? selectedWeekdays;
//   DateTime? createdAt;
//   DateTime? updatedAt;

//   AlertData({
//     required this.id,
//     required this.title,
//     required this.description,
//     required this.date,
//     required this.priority,
//     this.location,
//     this.object,
//     this.repetitive = false,
//     this.repeatFrequency,
//     this.active = true,
//     this.color,
//     this.imagePath,
//     this.selectedWeekdays,
//     this.createdAt,
//     this.updatedAt,
//   });
// }

class AlertDetailScreen extends StatefulWidget {
  final AlertData alert;

  const AlertDetailScreen({super.key, required this.alert});

  @override
  State<AlertDetailScreen> createState() => _AlertDetailScreenState();
}

class _AlertDetailScreenState extends State<AlertDetailScreen> {
  late AlertData alert;

  @override
  void initState() {
    super.initState();
    alert = widget.alert;
  }

  String _getPriorityText() {
    switch (alert.priority) {
      case AlertPriority.alta:
        return 'Alta';
      case AlertPriority.media:
        return 'Media';
      case AlertPriority.baja:
        return 'Baja';
    }
  }

  Color get _color {
    if (!alert.active) return Colors.grey.shade400;
    return alert.color ?? defaultColorFor(alert.priority);
  }

  String _formatTime(DateTime date) {
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  String _formatDateTimeCompact(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year.toString().substring(2);
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return '$day/$month/$year\n$hour:$minute';
  }

  void _showEditDialog() {
    showDialog(
      context: context,
      builder: (context) => _EditAlertModal(
        alert: alert,
        onSave: (editedAlert) async {
          try {
            // Mostrar indicador de carga
            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (context) => const Center(
                child: CircularProgressIndicator(),
              ),
            );

            // Llamar a la API para actualizar
            final provider = context.read<RecordatorioProvider>();
            final tituloOriginal = alert.title;
            final userId = SessionManager.instance.userId ?? 0;

            final recordatorioActualizado = Recordatorio(
              idRecordatorio: alert.id,
              idUsuario: userId,
              titulo: editedAlert.title,
              descripcion: editedAlert.description,
              fechaHora: editedAlert.date,
              prioridad: editedAlert.priority.name,
              ubicacion: editedAlert.location,
              objeto: editedAlert.object,
              esRepetitivo: editedAlert.repetitive,
              frecuenciaRepeticion: editedAlert.repeatFrequency,
              diasSeleccionados: editedAlert.selectedWeekdays?.join(','),
            );

            await provider.actualizarRecordatorio(
              tituloOriginal,
              recordatorioActualizado,
            );

            // Cerrar indicador de carga
            if (mounted) Navigator.pop(context);

            // Volver al diálogo
            if (mounted) {
              Navigator.pop(context);

              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('✅ Recordatorio actualizado exitosamente'),
                  backgroundColor: Colors.green,
                ),
              );
            }
          } on RecordatorioException catch (e) {
            if (mounted) Navigator.pop(context);
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Error: ${e.message}'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          } catch (e) {
            if (mounted) Navigator.pop(context);
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Error inesperado: $e'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          }
        },
      ),
      barrierDismissible: false,
    );
  }

  String _formatTimeRemaining(DateTime date) {
    final now = DateTime.now();
    final difference = date.difference(now);

    if (difference.isNegative) {
      final absDiff = difference.abs();
      if (absDiff.inDays > 0) {
        return 'Hace ${absDiff.inDays} día${absDiff.inDays > 1 ? 's' : ''}';
      } else if (absDiff.inHours > 0) {
        return 'Hace ${absDiff.inHours} hora${absDiff.inHours > 1 ? 's' : ''}';
      } else {
        return 'Hace ${absDiff.inMinutes} minuto${absDiff.inMinutes > 1 ? 's' : ''}';
      }
    }

    if (difference.inDays > 0) {
      final hours = difference.inHours % 24;
      return '${difference.inDays} día${difference.inDays > 1 ? 's' : ''} y $hours hora${hours != 1 ? 's' : ''}';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hora${difference.inHours > 1 ? 's' : ''}';
    } else {
      return '${difference.inMinutes} minuto${difference.inMinutes > 1 ? 's' : ''}';
    }
  }

  String _getMonthName(int month) {
    const months = [
      'Enero',
      'Febrero',
      'Marzo',
      'Abril',
      'Mayo',
      'Junio',
      'Julio',
      'Agosto',
      'Septiembre',
      'Octubre',
      'Noviembre',
      'Diciembre'
    ];
    return months[month - 1];
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final isPast = alert.date.isBefore(now);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Detalle del Recordatorio'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: _showEditDialog,
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Imagen o ícono (más pequeña)
                  if (alert.imagePath != null && alert.imagePath!.isNotEmpty)
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                _ImageViewer(path: alert.imagePath!),
                          ),
                        );
                      },
                      child: Container(
                        width: 140,
                        height: 140,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: FutureBuilder<Uint8List>(
                            future: XFile(alert.imagePath!).readAsBytes(),
                            builder: (context, snap) {
                              if (snap.connectionState !=
                                      ConnectionState.done ||
                                  !snap.hasData) {
                                return Container(
                                  color: Colors.grey.shade200,
                                  child: const Center(
                                    child: CircularProgressIndicator(),
                                  ),
                                );
                              }
                              return Image.memory(
                                snap.data!,
                                fit: BoxFit.cover,
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                  if (alert.imagePath != null && alert.imagePath!.isNotEmpty)
                    const SizedBox(height: 12),
                  Text(
                    alert.title,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: _color.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      'Prioridad ${_getPriorityText()}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: _color,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Sección "Vence en" más compacta
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Column(
                      children: [
                        Text(
                          isPast ? 'VENCIÓ' : 'VENCE EN',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.shade600,
                            letterSpacing: 0.8,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          _formatTimeRemaining(alert.date),
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${alert.date.day} de ${_getMonthName(alert.date.month)} ${alert.date.year} • ${_formatTime(alert.date)}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Línea divisora
                  Divider(
                    color: Colors.grey.shade300,
                    thickness: 1,
                    height: 20,
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'DETALLES',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Colors.grey.shade600,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Descripción (siempre se muestra)
                  _SimpleDetailItem(
                    icon: Icons.description_outlined,
                    label: 'Descripción',
                    value: alert.description.isNotEmpty
                        ? alert.description
                        : 'Sin descripción',
                  ),
                  const SizedBox(height: 12),

                  // Artículo (solo si tiene valor)
                  if (alert.object != null && alert.object!.isNotEmpty) ...[
                    _SimpleDetailItem(
                      icon: Icons.inventory_2_outlined,
                      label: 'Artículo',
                      value: alert.object!,
                    ),
                    const SizedBox(height: 12),
                  ],

                  // Ubicación (solo si tiene valor)
                  if (alert.location != null && alert.location!.isNotEmpty) ...[
                    _SimpleDetailItem(
                      icon: Icons.location_on_outlined,
                      label: 'Ubicación',
                      value: alert.location!,
                    ),
                    const SizedBox(height: 12),
                  ],

                  // Estado activo
                  _SimpleDetailItem(
                    icon: alert.active
                        ? Icons.check_circle_outline
                        : Icons.pause_circle_outline,
                    label: 'Estado',
                    value: alert.active ? 'Activo' : 'Inactivo',
                  ),
                  const SizedBox(height: 12),

                  // Repetición (solo si es repetitivo y tiene días seleccionados)
                  if (alert.repetitive &&
                      alert.selectedWeekdays != null &&
                      alert.selectedWeekdays!.isNotEmpty) ...[
                    _SimpleRepetitionDetail(
                        selectedWeekdays: alert.selectedWeekdays!),
                    const SizedBox(height: 12),
                  ],

                  // Frecuencia de repetición (solo si tiene valor)
                  if (alert.repetitive &&
                      alert.repeatFrequency != null &&
                      alert.repeatFrequency!.isNotEmpty) ...[
                    _SimpleDetailItem(
                      icon: Icons.event_repeat,
                      label: 'Frecuencia',
                      value: alert.repeatFrequency!,
                    ),
                    const SizedBox(height: 12),
                  ],

                  // Ruta de imagen (solo si tiene valor)
                  if (alert.imagePath != null &&
                      alert.imagePath!.isNotEmpty) ...[
                    _SimpleDetailItem(
                      icon: Icons.image_outlined,
                      label: 'Imagen',
                      value: 'Imagen adjunta',
                    ),
                    const SizedBox(height: 12),
                  ],

                  // Sección de metadatos (fechas) - Solo si alguna existe
                  if (alert.createdAt != null || alert.updatedAt != null) ...[
                    const SizedBox(height: 8),
                    Divider(
                      color: Colors.grey.shade300,
                      thickness: 1,
                      height: 20,
                    ),
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'INFORMACIÓN DEL SISTEMA',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Colors.grey.shade600,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        // Fecha de creación
                        if (alert.createdAt != null)
                          Expanded(
                            child: _CompactDetailItem(
                              icon: Icons.calendar_today_outlined,
                              label: 'Creado el',
                              value: _formatDateTimeCompact(alert.createdAt!),
                            ),
                          ),
                        if (alert.createdAt != null && alert.updatedAt != null)
                          const SizedBox(width: 16),
                        // Fecha de actualización
                        if (alert.updatedAt != null)
                          Expanded(
                            child: _CompactDetailItem(
                              icon: Icons.update_outlined,
                              label: 'Actualizado el',
                              value: _formatDateTimeCompact(alert.updatedAt!),
                            ),
                          ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Botones en columna vertical - ajustados al contenedor
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Botón Completar
                      ElevatedButton.icon(
                        onPressed: () async {
                          final confirmar = await showDialog<bool>(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('Completar recordatorio'),
                              content: const Text(
                                  '¿Deseas marcar este recordatorio como completado? Esto lo eliminará permanentemente.'),
                              actions: [
                                TextButton(
                                    onPressed: () =>
                                        Navigator.pop(context, false),
                                    child: const Text('Cancelar')),
                                TextButton(
                                  onPressed: () => Navigator.pop(context, true),
                                  child: const Text('Completar',
                                      style: TextStyle(color: Colors.blue)),
                                ),
                              ],
                            ),
                          );

                          if (confirmar == true && mounted) {
                            try {
                              // Enviar el recordatorio a la papelera
                              final trashService = TrashService.getInstance();

                              // Crear un TrashItem a partir del recordatorio
                              final trashItem = TrashItem(
                                id: alert.id,
                                name: alert.title,
                                placeName: alert.location ?? 'Sin ubicación',
                                category:
                                    'Recordatorio - ${alert.priority.name}',
                                quantity: null,
                                deletedAt: DateTime.now(),
                                originalType: 'alert',
                              );

                              // Agregar a la papelera
                              await trashService.addToTrash(trashItem);

                              // Eliminar de la API
                              final provider =
                                  context.read<RecordatorioProvider>();
                              await provider.eliminarRecordatorio(alert.title);

                              if (mounted) {
                                Navigator.pop(context);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                        '✅ Recordatorio completado y enviado a la papelera'),
                                    backgroundColor: Colors.green,
                                  ),
                                );
                              }
                            } on RecordatorioException catch (e) {
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Error: ${e.message}'),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            } catch (e) {
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Error inesperado: $e'),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            }
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          elevation: 2,
                        ),
                        icon: const Icon(Icons.check_circle_outline, size: 22),
                        label: const Text('Completar',
                            style: TextStyle(
                                fontSize: 15, fontWeight: FontWeight.bold)),
                      ),
                      const SizedBox(height: 10),
                      // Botón Desactivar/Activar
                      OutlinedButton.icon(
                        onPressed: () async {
                          try {
                            // Llamar a la API para toggle activo
                            final provider =
                                context.read<RecordatorioProvider>();
                            await provider
                                .toggleActivoRecordatorio(alert.title);

                            // Actualizar el estado local
                            setState(() {
                              alert.active = !alert.active;
                            });

                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(alert.active
                                      ? 'Recordatorio activado'
                                      : 'Recordatorio desactivado'),
                                  backgroundColor: Colors.green,
                                ),
                              );
                            }
                          } on RecordatorioException catch (e) {
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Error: ${e.message}'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          } catch (e) {
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Error inesperado: $e'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          }
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.grey.shade700,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          side: BorderSide(
                              color: Colors.grey.shade300, width: 1.5),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        icon: Icon(
                          alert.active
                              ? Icons.pause_circle_outline
                              : Icons.play_circle_outline,
                          size: 22,
                        ),
                        label: Text(
                          alert.active ? 'Desactivar' : 'Activar',
                          style: const TextStyle(
                              fontSize: 15, fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(height: 10),
                      // Botón Eliminar
                      TextButton.icon(
                        onPressed: () async {
                          final confirmar = await showDialog<bool>(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('Eliminar'),
                              content: const Text(
                                  '¿Estás seguro de que deseas eliminar este recordatorio?'),
                              actions: [
                                TextButton(
                                    onPressed: () =>
                                        Navigator.pop(context, false),
                                    child: const Text('Cancelar')),
                                TextButton(
                                  onPressed: () => Navigator.pop(context, true),
                                  child: const Text('Eliminar',
                                      style: TextStyle(color: Colors.red)),
                                ),
                              ],
                            ),
                          );

                          if (confirmar == true && mounted) {
                            try {
                              // Enviar el recordatorio a la papelera
                              final trashService = TrashService.getInstance();

                              // Crear un TrashItem a partir del recordatorio
                              final trashItem = TrashItem(
                                id: alert.id,
                                name: alert.title,
                                placeName: alert.location ?? 'Sin ubicación',
                                category:
                                    'Recordatorio - ${alert.priority.name}',
                                quantity: null,
                                deletedAt: DateTime.now(),
                                originalType: 'alert',
                              );

                              // Agregar a la papelera
                              await trashService.addToTrash(trashItem);

                              // Eliminar de la API
                              final provider =
                                  context.read<RecordatorioProvider>();
                              await provider.eliminarRecordatorio(alert.title);

                              if (mounted) {
                                Navigator.pop(context);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                        '♻️ Recordatorio enviado a la papelera'),
                                    backgroundColor: Colors.green,
                                  ),
                                );
                              }
                            } on RecordatorioException catch (e) {
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Error: ${e.message}'),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            } catch (e) {
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Error inesperado: $e'),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            }
                          }
                        },
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.red,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          backgroundColor: Colors.red.shade50,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        icon: const Icon(Icons.delete_outline, size: 22),
                        label: const Text('Eliminar',
                            style: TextStyle(
                                fontSize: 15, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Widget para mostrar un item de detalle (solo texto, sin tarjeta)
class _SimpleDetailItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _SimpleDetailItem({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 22, color: Colors.grey.shade600),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                value,
                style: const TextStyle(fontSize: 16, color: Colors.black87),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// Widget para mostrar repetición (sin tarjeta, estilo simple)
class _SimpleRepetitionDetail extends StatelessWidget {
  final List<int> selectedWeekdays;

  const _SimpleRepetitionDetail({required this.selectedWeekdays});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.repeat_rounded, size: 22, color: Colors.grey.shade600),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Repetición',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: weekDays.map((day) {
                  final isSelected = selectedWeekdays.contains(day.value);
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: isSelected ? Colors.blue : Colors.grey.shade200,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          day.label,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: isSelected
                                ? Colors.white
                                : Colors.grey.shade600,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// Widget compacto para mostrar información de sistema (lado a lado)
class _CompactDetailItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _CompactDetailItem({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(icon, size: 20, color: Colors.grey.shade600),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade600,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.black87,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// Widget para visualizar la imagen en pantalla completa
class _ImageViewer extends StatelessWidget {
  const _ImageViewer({required this.path});
  final String path;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Imagen del Recordatorio'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: FutureBuilder<Uint8List>(
          future: XFile(path).readAsBytes(),
          builder: (context, snap) {
            if (snap.connectionState != ConnectionState.done || !snap.hasData) {
              return const CircularProgressIndicator(color: Colors.white);
            }
            return InteractiveViewer(
              minScale: 0.5,
              maxScale: 4.0,
              child: Image.memory(snap.data!),
            );
          },
        ),
      ),
    );
  }
}

// Modal para editar recordatorios con todas las características (similar a crear)
class _EditAlertModal extends StatefulWidget {
  final AlertData? alert;
  final Function(AlertData) onSave;

  const _EditAlertModal({
    required this.alert,
    required this.onSave,
  });

  @override
  State<_EditAlertModal> createState() => _EditAlertModalState();
}

class _EditAlertModalState extends State<_EditAlertModal> {
  late TextEditingController titleCtrl;
  late TextEditingController descCtrl;
  late TextEditingController locationCtrl;

  late DateTime date;
  late AlertPriority priority;
  bool repetitive = false;
  String? repeatFrequency;
  List<int> selectedWeekdays = [];

  Color? customColor;
  final _picker = ImagePicker();
  XFile? _pickedImage;

  @override
  void initState() {
    super.initState();
    final a = widget.alert;
    titleCtrl = TextEditingController(text: a?.title ?? '');
    descCtrl = TextEditingController(text: a?.description ?? '');
    locationCtrl = TextEditingController(text: a?.location ?? '');
    date = a?.date ?? DateTime.now();
    priority = a?.priority ?? AlertPriority.baja;
    repetitive = a?.repetitive ?? false;
    repeatFrequency = a?.repeatFrequency;
    selectedWeekdays = List.from(a?.selectedWeekdays ?? []);
    customColor = a?.color ?? defaultColorFor(priority);
    _pickedImage = null;
  }

  @override
  void dispose() {
    titleCtrl.dispose();
    descCtrl.dispose();
    locationCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickFromGallery() async {
    final img =
        await _picker.pickImage(source: ImageSource.gallery, maxWidth: 1920);
    if (img != null) setState(() => _pickedImage = img);
  }

  Future<void> _pickFromCamera() async {
    final img =
        await _picker.pickImage(source: ImageSource.camera, maxWidth: 1920);
    if (img != null) setState(() => _pickedImage = img);
  }

  void _clearImage() {
    setState(() => _pickedImage = null);
  }

  void _openColorPicker() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Elegir color'),
        content: SingleChildScrollView(
          child: BlockPicker(
            pickerColor: customColor ?? defaultColorFor(priority),
            onColorChanged: (c) => setState(() => customColor = c),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  Widget _buildWeekdaySelector() {
    final weekdays = [
      {'name': 'L', 'fullName': 'Lunes', 'value': 1},
      {'name': 'M', 'fullName': 'Martes', 'value': 2},
      {'name': 'X', 'fullName': 'Miércoles', 'value': 3},
      {'name': 'J', 'fullName': 'Jueves', 'value': 4},
      {'name': 'V', 'fullName': 'Viernes', 'value': 5},
      {'name': 'S', 'fullName': 'Sábado', 'value': 6},
      {'name': 'D', 'fullName': 'Domingo', 'value': 7},
    ];

    final allDaysSelected = selectedWeekdays.length == 7;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            children: [
              TextButton.icon(
                onPressed: () {
                  setState(() {
                    if (allDaysSelected) {
                      selectedWeekdays.clear();
                    } else {
                      selectedWeekdays = [1, 2, 3, 4, 5, 6, 7];
                    }
                  });
                },
                icon: Icon(
                  allDaysSelected ? Icons.check_circle : Icons.circle_outlined,
                  color: Colors.blue,
                ),
                label: Text(
                  allDaysSelected ? 'Desmarcar todos' : 'Marcar todos',
                  style: const TextStyle(color: Colors.blue),
                ),
              ),
            ],
          ),
        ),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: weekdays.map((day) {
            final isSelected = selectedWeekdays.contains(day['value']);
            return GestureDetector(
              onTap: () {
                setState(() {
                  if (isSelected) {
                    selectedWeekdays.remove(day['value']);
                  } else {
                    selectedWeekdays.add(day['value'] as int);
                  }
                });
              },
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: isSelected ? Colors.blue : Colors.grey.shade200,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isSelected ? Colors.blue : Colors.grey.shade400,
                    width: 1,
                  ),
                ),
                child: Center(
                  child: Text(
                    day['name'] as String,
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.black87,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _thumbPreview() {
    final path = _pickedImage?.path ?? widget.alert?.imagePath;
    if (path == null) {
      return Container(
        width: 72,
        height: 72,
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300),
        ),
        alignment: Alignment.center,
        child: const Icon(Icons.image_outlined, color: Colors.grey),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: FutureBuilder<Uint8List>(
        future: XFile(path).readAsBytes(),
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done || !snap.hasData) {
            return Container(
              width: 72,
              height: 72,
              color: Colors.grey.shade200,
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            );
          }
          return Image.memory(
            snap.data!,
            width: 72,
            height: 72,
            fit: BoxFit.cover,
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final existing = widget.alert;

    return AlertDialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
      contentPadding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
      actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          const Icon(Icons.edit_outlined, color: Colors.blue),
          const SizedBox(width: 12),
          const Text('Editar Recordatorio'),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: titleCtrl,
                decoration: const InputDecoration(
                  labelText: 'Título',
                  prefixIcon: Icon(Icons.title),
                  filled: true,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: descCtrl,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Descripción',
                  prefixIcon: Icon(Icons.notes),
                  filled: true,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Fecha y Hora',
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: date.isAfter(DateTime.now())
                              ? date
                              : DateTime.now(),
                          firstDate: DateTime.now(),
                          lastDate: DateTime(2100),
                        );
                        if (picked != null) {
                          setState(() {
                            date = DateTime(
                              picked.year,
                              picked.month,
                              picked.day,
                              date.hour,
                              date.minute,
                            );
                          });
                        }
                      },
                      child: InputDecorator(
                        decoration: InputDecoration(
                          labelText: 'Fecha',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          filled: true,
                        ),
                        child: Text(
                          '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}',
                          style: const TextStyle(fontSize: 15),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: GestureDetector(
                      onTap: () async {
                        final picked = await showTimePicker(
                          context: context,
                          initialTime: TimeOfDay.fromDateTime(date),
                        );
                        if (picked != null) {
                          setState(() {
                            date = DateTime(
                              date.year,
                              date.month,
                              date.day,
                              picked.hour,
                              picked.minute,
                            );
                          });
                        }
                      },
                      child: InputDecorator(
                        decoration: InputDecoration(
                          labelText: 'Hora',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          filled: true,
                        ),
                        child: Text(
                          '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}',
                          style: const TextStyle(fontSize: 15),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<AlertPriority>(
                value: priority,
                decoration: InputDecoration(
                  labelText: 'Prioridad',
                  prefixIcon: const Icon(Icons.priority_high_rounded),
                  filled: true,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
                items: const [
                  DropdownMenuItem(
                      value: AlertPriority.baja, child: Text('Baja')),
                  DropdownMenuItem(
                      value: AlertPriority.media, child: Text('Media')),
                  DropdownMenuItem(
                      value: AlertPriority.alta, child: Text('Alta')),
                ],
                onChanged: (val) {
                  setState(() {
                    priority = val!;
                    customColor = defaultColorFor(priority);
                  });
                },
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  const Text('Color:'),
                  const SizedBox(width: 12),
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: customColor ?? defaultColorFor(priority),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.grey.shade400, width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: (customColor ?? defaultColorFor(priority))
                              .withOpacity(0.3),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  OutlinedButton.icon(
                    onPressed: _openColorPicker,
                    icon: const Icon(Icons.palette_outlined),
                    label: const Text('Cambiar'),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              const Text(
                'Detalles Adicionales',
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey),
              ),
              const SizedBox(height: 12),
              TextField(
                decoration: InputDecoration(
                  labelText: 'Ubicación (opcional)',
                  prefixIcon: const Icon(Icons.location_on_outlined),
                  filled: true,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
                onChanged: (v) =>
                    locationCtrl.text = v.trim().isEmpty ? '' : v.trim(),
                controller: locationCtrl,
              ),
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerLeft,
                child: Text('Imagen (opcional)',
                    style: Theme.of(context)
                        .textTheme
                        .titleSmall
                        ?.copyWith(color: Colors.grey)),
              ),
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  _thumbPreview(),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        OutlinedButton.icon(
                          onPressed: _pickFromGallery,
                          icon: const Icon(Icons.photo_outlined, size: 18),
                          label: const Text('Galería',
                              style: TextStyle(fontSize: 12)),
                        ),
                        OutlinedButton.icon(
                          onPressed: _pickFromCamera,
                          icon:
                              const Icon(Icons.photo_camera_outlined, size: 18),
                          label: const Text('Cámara',
                              style: TextStyle(fontSize: 12)),
                        ),
                        if (_pickedImage != null ||
                            (existing?.imagePath?.isNotEmpty ?? false))
                          TextButton.icon(
                            onPressed: _clearImage,
                            icon: const Icon(Icons.delete_outline, size: 18),
                            label: const Text('Quitar',
                                style: TextStyle(fontSize: 12)),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SwitchListTile(
                value: repetitive,
                onChanged: (v) => setState(() => repetitive = v),
                title: const Text('Repetir semanalmente'),
                contentPadding: EdgeInsets.zero,
                dense: true,
              ),
              if (repetitive) ...[
                const SizedBox(height: 12),
                Text('Días de repetición:',
                    style: Theme.of(context)
                        .textTheme
                        .titleSmall
                        ?.copyWith(color: Colors.grey)),
                const SizedBox(height: 12),
                _buildWeekdaySelector(),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        ElevatedButton.icon(
          onPressed: () {
            final trimmedTitle = titleCtrl.text.trim();
            if (trimmedTitle.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('El título es requerido'),
                  backgroundColor: Colors.red,
                ),
              );
              return;
            }

            // Validar que la fecha/hora no sea anterior a ahora
            final now = DateTime.now();
            if (date.isBefore(now)) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                      '❌ La fecha y hora no pueden ser anteriores a la actual'),
                  backgroundColor: Colors.red,
                ),
              );
              return;
            }

            final result = AlertData(
              id: widget.alert!.id,
              title: trimmedTitle,
              description: descCtrl.text.trim(),
              date: date,
              priority: priority,
              location: locationCtrl.text.trim().isEmpty
                  ? null
                  : locationCtrl.text.trim(),
              object: widget.alert!.object,
              repetitive: repetitive,
              repeatFrequency:
                  repetitive ? (repeatFrequency ?? 'semanal') : null,
              active: widget.alert!.active,
              color: customColor,
              imagePath: _pickedImage?.path ?? widget.alert!.imagePath,
              selectedWeekdays:
                  selectedWeekdays.isNotEmpty ? selectedWeekdays : null,
            );

            widget.onSave(result);
            Navigator.pop(context);
          },
          icon: const Icon(Icons.save),
          label: const Text('Guardar'),
        ),
      ],
    );
  }
}
