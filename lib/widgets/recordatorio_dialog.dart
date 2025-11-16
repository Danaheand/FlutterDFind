import 'dart:math';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:image_picker/image_picker.dart';
import '../services/notification_service.dart';
import '../widgets/custom_text_button.dart';

enum AlertPriority { baja, media, alta }

Color defaultColorFor(AlertPriority p) {
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

/// Diálogo reutilizable para crear o editar recordatorios
class RecordatorioDialog extends StatefulWidget {
  const RecordatorioDialog({
    super.key,
    this.alert,
    this.userEmail,
  });

  final AlertData? alert;
  final String? userEmail;

  @override
  State<RecordatorioDialog> createState() => _RecordatorioDialogState();
}

class _RecordatorioDialogState extends State<RecordatorioDialog> {
  late TextEditingController titleCtrl;
  late TextEditingController descCtrl;

  late DateTime date;
  late AlertPriority priority;
  String? location;
  String? object;
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
    date = a?.date ?? DateTime.now();
    priority = a?.priority ?? AlertPriority.baja;
    location = a?.location;
    object = a?.object;
    repetitive = a?.repetitive ?? false;
    repeatFrequency = a?.repeatFrequency;
    selectedWeekdays = a?.selectedWeekdays ?? [];
    customColor = a?.color ?? defaultColorFor(priority);
    _pickedImage = null;
  }

  @override
  void dispose() {
    titleCtrl.dispose();
    descCtrl.dispose();
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
          CustomTextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  static const _vGap = SizedBox(height: 16);
  static const _sectionDivider = Divider(height: 30, thickness: 0.1);

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
              CustomTextButton.icon(
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
                  allDaysSelected ? 'Desmarcar todos' : 'Marcar todos los días',
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

  String _getSelectedDaysText() {
    if (selectedWeekdays.isEmpty) return '';

    final dayNames = {
      1: 'Lunes',
      2: 'Martes',
      3: 'Miércoles',
      4: 'Jueves',
      5: 'Viernes',
      6: 'Sábado',
      7: 'Domingo'
    };

    selectedWeekdays.sort();
    final names = selectedWeekdays.map((day) => dayNames[day]).toList();

    if (names.length <= 2) {
      return names.join(' y ');
    } else {
      return '${names.sublist(0, names.length - 1).join(', ')} y ${names.last}';
    }
  }

  @override
  Widget build(BuildContext context) {
    final existing = widget.alert;
    final existingPath = existing?.imagePath;

    return AlertDialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      titlePadding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
      contentPadding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
      actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      title:
          Text(existing == null ? 'Nuevo Recordatorio' : 'Editar Recordatorio'),
      content: SizedBox(
        width: 520,
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
                ),
              ),
              _vGap,
              TextField(
                controller: descCtrl,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Descripción',
                  prefixIcon: Icon(Icons.notes),
                ),
              ),
              _sectionDivider,
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
                          helpText: 'Selecciona la fecha de la alerta',
                          cancelText: 'Cancelar',
                          confirmText: 'Aceptar',
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
                        decoration: const InputDecoration(
                          labelText: 'Fecha',
                          border: OutlineInputBorder(),
                          contentPadding:
                              EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                        child: Text(
                          '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}',
                          style: const TextStyle(fontSize: 16),
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
                          helpText: 'Selecciona la hora de la alerta',
                          cancelText: 'Cancelar',
                          confirmText: 'Aceptar',
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
                        decoration: const InputDecoration(
                          labelText: 'Hora',
                          border: OutlineInputBorder(),
                          contentPadding:
                              EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                        child: Text(
                          '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}',
                          style: const TextStyle(fontSize: 16),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              _vGap,
              DropdownButtonFormField<AlertPriority>(
                value: priority,
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
                    priority = val!;
                    customColor = defaultColorFor(priority);
                  });
                },
              ),
              _vGap,
              Row(
                children: [
                  const Text('Color:  '),
                  Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      color: customColor ?? defaultColorFor(priority),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.black12),
                    ),
                  ),
                  const SizedBox(width: 12),
                  OutlinedButton.icon(
                    onPressed: _openColorPicker,
                    icon: const Icon(Icons.palette_outlined),
                    label: const Text('Cambiar color'),
                  ),
                ],
              ),
              _sectionDivider,
              TextField(
                decoration: const InputDecoration(
                  labelText: 'Lugar (opcional)',
                  prefixIcon: Icon(Icons.place_outlined),
                ),
                onChanged: (v) => location = v.trim().isEmpty ? null : v.trim(),
                controller: TextEditingController(text: location),
              ),
              _sectionDivider,
              Align(
                alignment: Alignment.centerLeft,
                child: Text('Imagen (opcional)',
                    style: Theme.of(context).textTheme.titleMedium),
              ),
              _vGap,
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  _thumbPreview(existingPath: existingPath),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        OutlinedButton.icon(
                          onPressed: _pickFromGallery,
                          icon: const Icon(Icons.photo_outlined),
                          label: const Text('Galería'),
                        ),
                        OutlinedButton.icon(
                          onPressed: _pickFromCamera,
                          icon: const Icon(Icons.photo_camera_outlined),
                          label: const Text('Cámara'),
                        ),
                        if (_pickedImage != null ||
                            (existingPath?.isNotEmpty ?? false))
                          CustomTextButton.icon(
                            onPressed: _clearImage,
                            icon: const Icon(Icons.delete_outline),
                            label: const Text('Quitar'),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
              _sectionDivider,
              SwitchListTile(
                value: repetitive,
                onChanged: (v) => setState(() => repetitive = v),
                title: const Text('Repetir'),
                contentPadding: EdgeInsets.zero,
              ),
              if (repetitive) ...[
                _vGap,
                Text('Selecciona los días que se repetirá:',
                    style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 12),
                _buildWeekdaySelector(),
                const SizedBox(height: 8),
                Text(
                  selectedWeekdays.isEmpty
                      ? 'Selecciona al menos un día'
                      : 'Se repetirá: ${_getSelectedDaysText()}',
                  style: TextStyle(
                    color: selectedWeekdays.isEmpty ? Colors.red : Colors.green,
                    fontSize: 12,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        CustomTextButton(
          onPressed: () => Navigator.pop(context, null),
          child: const Text('Cancelar'),
        ),
        ElevatedButton.icon(
          onPressed: () async {
            final trimmedTitle = titleCtrl.text.trim();
            if (trimmedTitle.isEmpty) return;

            final result = AlertData(
              id: widget.alert?.id ?? 'alert${Random().nextInt(100000)}',
              title: trimmedTitle,
              description: descCtrl.text.trim(),
              date: date,
              priority: priority,
              location: location,
              object: object,
              repetitive: repetitive,
              repeatFrequency:
                  repetitive ? (repeatFrequency ?? 'semanal') : null,
              active: widget.alert?.active ?? true,
              color: customColor,
              imagePath: _pickedImage?.path ?? widget.alert?.imagePath,
              selectedWeekdays:
                  selectedWeekdays.isNotEmpty ? selectedWeekdays : null,
            );

            // Programar la notificación/alarma
            if (date.isAfter(DateTime.now())) {
              try {
                if (repetitive && selectedWeekdays.isNotEmpty) {
                  await NotificationService()
                      .scheduleRepeatingAlarmNotification(
                    baseId: result.id.hashCode,
                    title: 'Alarma: ${result.title}',
                    body: result.description.isNotEmpty
                        ? result.description
                        : 'Es hora de tu alarma',
                    scheduledDate: result.date,
                    weekdays: selectedWeekdays,
                  );
                } else {
                  await NotificationService().scheduleAlarmNotification(
                    id: result.id.hashCode,
                    title: 'Alarma: ${result.title}',
                    body: result.description.isNotEmpty
                        ? result.description
                        : 'Es hora de tu alarma',
                    scheduledDate: result.date,
                  );
                }

                final pending =
                    await NotificationService().getPendingNotifications();
                print('✅ Notificación programada exitosamente');
                print(
                    '📌 Total de notificaciones pendientes: ${pending.length}');
              } catch (e) {
                if (mounted) {
                  print('❌ Error al programar alarma: $e');
                }
              }
            } else {
              print(
                  '⚠️  La fecha es anterior a ahora, no se programó notificación');
            }

            if (mounted) {
              Navigator.pop(context, result);
            }
          },
          icon: const Icon(Icons.save),
          label: const Text('Guardar'),
        ),
      ],
    );
  }

  Widget _thumbPreview({String? existingPath}) {
    final path = _pickedImage?.path ?? existingPath;
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

    Future<Uint8List> loadBytes() => XFile(path).readAsBytes();

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: FutureBuilder<Uint8List>(
        future: loadBytes(),
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done || !snap.hasData) {
            return Container(
              width: 72,
              height: 72,
              color: Colors.grey.shade100,
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
}
