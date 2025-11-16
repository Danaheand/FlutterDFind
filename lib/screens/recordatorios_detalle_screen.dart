import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../providers/recordatorio_provider.dart';
import '../models/recordatorio_exception.dart';
import '../models/recordatorio.dart';

enum AlertPriority { baja, media, alta }

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

Color _defaultColorFor(AlertPriority p) {
  switch (p) {
    case AlertPriority.alta:
      return Colors.red.shade400;
    case AlertPriority.media:
      return Colors.amber.shade600;
    case AlertPriority.baja:
      return Colors.blue.shade400;
  }
}

class AlertData {
  String id;
  String title;
  String description;
  DateTime date;
  AlertPriority priority;
  String? location;
  String? object;
  bool repetitive;
  String? repeatFrequency;
  bool active;
  Color? color;
  String? imagePath;
  List<int>? selectedWeekdays;
  DateTime? createdAt;
  DateTime? updatedAt;

  AlertData({
    required this.id,
    required this.title,
    required this.description,
    required this.date,
    required this.priority,
    this.location,
    this.object,
    this.repetitive = false,
    this.repeatFrequency,
    this.active = true,
    this.color,
    this.imagePath,
    this.selectedWeekdays,
    this.createdAt,
    this.updatedAt,
  });
}

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
    return alert.color ?? _defaultColorFor(alert.priority);
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
    final titleCtrl = TextEditingController(text: alert.title);
    final descCtrl = TextEditingController(text: alert.description);
    final locationCtrl = TextEditingController(text: alert.location ?? '');
    final objectCtrl = TextEditingController(text: alert.object ?? '');

    DateTime editDate = alert.date;
    AlertPriority editPriority = alert.priority;
    Color? editColor = alert.color ?? _defaultColorFor(alert.priority);

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Editar Recordatorio'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextField(
                  controller: titleCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Título',
                    prefixIcon: Icon(Icons.title),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: descCtrl,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Descripción',
                    prefixIcon: Icon(Icons.notes),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: locationCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Lugar (opcional)',
                    prefixIcon: Icon(Icons.place_outlined),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: objectCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Artículo (opcional)',
                    prefixIcon: Icon(Icons.inventory_2_outlined),
                  ),
                ),
                const SizedBox(height: 12),
                GestureDetector(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: editDate,
                      firstDate: DateTime.now(),
                      lastDate: DateTime(2100),
                    );
                    if (picked != null) {
                      setState(() => editDate = picked);
                    }
                  },
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Fecha',
                      border: OutlineInputBorder(),
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    child: Text(
                      '${editDate.day.toString().padLeft(2, '0')}/${editDate.month.toString().padLeft(2, '0')}/${editDate.year}',
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<AlertPriority>(
                  value: editPriority,
                  // initialValue: editPriority,
                  decoration: const InputDecoration(
                    labelText: 'Prioridad',
                    prefixIcon: Icon(Icons.priority_high_rounded),
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
                      editPriority = val!;
                      editColor = _defaultColorFor(editPriority);
                    });
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            ElevatedButton.icon(
              onPressed: () async {
                final tituloOriginal =
                    alert.title; // Guardar título original para el PUT

                try {
                  // Llamar a la API para actualizar
                  final provider = context.read<RecordatorioProvider>();

                  final recordatorioActualizado = Recordatorio(
                    idRecordatorio: alert.id,
                    idUsuario: 0, // Se requiere pero no se usa en PUT
                    titulo: titleCtrl.text.trim(),
                    descripcion: descCtrl.text.trim(),
                    fechaHora: editDate,
                    prioridad: editPriority.name,
                    ubicacion: locationCtrl.text.trim().isEmpty
                        ? null
                        : locationCtrl.text.trim(),
                    objeto: objectCtrl.text.trim().isEmpty
                        ? null
                        : objectCtrl.text.trim(),
                    esRepetitivo: alert.repetitive,
                    frecuenciaRepeticion: alert.repeatFrequency,
                    diasSeleccionados: alert.selectedWeekdays?.join(','),
                  );

                  await provider.actualizarRecordatorio(
                    tituloOriginal,
                    recordatorioActualizado,
                  );

                  // Actualizar el estado local
                  if (mounted) {
                    setState(() {
                      alert = AlertData(
                        id: alert.id,
                        title: titleCtrl.text.trim(),
                        description: descCtrl.text.trim(),
                        date: editDate,
                        priority: editPriority,
                        location: locationCtrl.text.trim().isEmpty
                            ? null
                            : locationCtrl.text.trim(),
                        object: objectCtrl.text.trim().isEmpty
                            ? null
                            : objectCtrl.text.trim(),
                        repetitive: alert.repetitive,
                        repeatFrequency: alert.repeatFrequency,
                        active: alert.active,
                        color: editColor,
                        imagePath: alert.imagePath,
                        selectedWeekdays: alert.selectedWeekdays,
                        createdAt: alert.createdAt,
                        updatedAt: DateTime.now(),
                      );
                    });

                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Recordatorio actualizado exitosamente'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                } on RecordatorioException catch (e) {
                  Navigator.pop(context);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error: ${e.message}'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                } catch (e) {
                  Navigator.pop(context);
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
              icon: const Icon(Icons.save),
              label: const Text('Guardar'),
            ),
          ],
        ),
      ),
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
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Imagen o ícono
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
                        width: 200,
                        height: 200,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
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
                    const SizedBox(height: 20),
                  Text(
                    alert.title,
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: _color.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'Prioridad ${_getPriorityText()}',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: _color,
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      children: [
                        Text(
                          isPast ? 'VENCIÓ' : 'VENCE EN',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.shade600,
                            letterSpacing: 1.2,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _formatTimeRemaining(alert.date),
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          '${alert.date.day} de ${_getMonthName(alert.date.month)} ${alert.date.year}, ${_formatTime(alert.date)}',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 30),
                  // Línea divisora
                  Divider(
                    color: Colors.grey.shade300,
                    thickness: 1,
                    height: 40,
                  ),
                  const SizedBox(height: 10),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'DETALLES',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Colors.grey.shade600,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Descripción (siempre se muestra)
                  _SimpleDetailItem(
                    icon: Icons.description_outlined,
                    label: 'Descripción',
                    value: alert.description.isNotEmpty
                        ? alert.description
                        : 'Sin descripción',
                  ),
                  const SizedBox(height: 20),

                  // Artículo (solo si tiene valor)
                  if (alert.object != null && alert.object!.isNotEmpty) ...[
                    _SimpleDetailItem(
                      icon: Icons.inventory_2_outlined,
                      label: 'Artículo',
                      value: alert.object!,
                    ),
                    const SizedBox(height: 20),
                  ],

                  // Ubicación (solo si tiene valor)
                  if (alert.location != null && alert.location!.isNotEmpty) ...[
                    _SimpleDetailItem(
                      icon: Icons.location_on_outlined,
                      label: 'Ubicación',
                      value: alert.location!,
                    ),
                    const SizedBox(height: 20),
                  ],

                  // Estado activo
                  _SimpleDetailItem(
                    icon: alert.active
                        ? Icons.check_circle_outline
                        : Icons.pause_circle_outline,
                    label: 'Estado',
                    value: alert.active ? 'Activo' : 'Inactivo',
                  ),
                  const SizedBox(height: 20),

                  // Repetición (solo si es repetitivo y tiene días seleccionados)
                  if (alert.repetitive &&
                      alert.selectedWeekdays != null &&
                      alert.selectedWeekdays!.isNotEmpty) ...[
                    _SimpleRepetitionDetail(
                        selectedWeekdays: alert.selectedWeekdays!),
                    const SizedBox(height: 20),
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
                    const SizedBox(height: 20),
                  ],

                  // Ruta de imagen (solo si tiene valor)
                  if (alert.imagePath != null &&
                      alert.imagePath!.isNotEmpty) ...[
                    _SimpleDetailItem(
                      icon: Icons.image_outlined,
                      label: 'Imagen',
                      value: 'Imagen adjunta',
                    ),
                    const SizedBox(height: 20),
                  ],

                  // Sección de metadatos (fechas) - Solo si alguna existe
                  if (alert.createdAt != null || alert.updatedAt != null) ...[
                    const SizedBox(height: 10),
                    Divider(
                      color: Colors.grey.shade300,
                      thickness: 1,
                      height: 40,
                    ),
                    const SizedBox(height: 10),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'INFORMACIÓN DEL SISTEMA',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Colors.grey.shade600,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
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
            padding: const EdgeInsets.all(16),
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
                  // Botón Completar - Ancho completo
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
                                onPressed: () => Navigator.pop(context, false),
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
                          // Llamar a la API para eliminar (completar = eliminar)
                          final provider = context.read<RecordatorioProvider>();
                          await provider.eliminarRecordatorio(alert.title);

                          if (mounted) {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                    'Recordatorio completado exitosamente'),
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
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    icon: const Icon(Icons.check_circle_outline, size: 22),
                    label: const Text('Completar',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w600)),
                  ),
                  const SizedBox(height: 10),
                  // Fila con Desactivar y Eliminar
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
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
                            size: 20,
                          ),
                          label: Text(
                            alert.active ? 'Desactivar' : 'Activar',
                            style: const TextStyle(
                                fontSize: 15, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextButton.icon(
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
                                    onPressed: () =>
                                        Navigator.pop(context, true),
                                    child: const Text('Eliminar',
                                        style: TextStyle(color: Colors.red)),
                                  ),
                                ],
                              ),
                            );

                            if (confirmar == true && mounted) {
                              try {
                                // Llamar a la API para eliminar
                                final provider =
                                    context.read<RecordatorioProvider>();
                                await provider
                                    .eliminarRecordatorio(alert.title);

                                if (mounted) {
                                  Navigator.pop(context);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                          'Recordatorio eliminado exitosamente'),
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
                          icon: const Icon(Icons.delete_outline, size: 20),
                          label: const Text('Eliminar',
                              style: TextStyle(
                                  fontSize: 15, fontWeight: FontWeight.w600)),
                        ),
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
