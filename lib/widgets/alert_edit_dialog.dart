import 'dart:math';

import 'package:Dfind/models/alert_data.dart';
import 'package:Dfind/services/notification_service.dart';
import 'package:Dfind/utils/alert_utils.dart';
import 'package:Dfind/widgets/custom_text_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';

class AlertEditDialogState extends State<AlertEditDialog> {
  late TextEditingController titleCtrl;
  late TextEditingController descCtrl;

  DateTime? date; // Nullable para empezar en blanco
  AlertPriority? priority;
  String? location;
  String? object;
  bool repetitive = false;
  String? repeatFrequency;
  List<int> selectedWeekdays =
      []; // Días de la semana seleccionados (1=Lunes, 7=Domingo)

  Color? customColor;

  // Variables para mostrar errores
  String? titleError;
  String? dateError;
  String? timeError;

  @override
  void initState() {
    super.initState();
    final a = widget.alert;
    titleCtrl = TextEditingController(text: a?.title ?? '');
    descCtrl = TextEditingController(text: a?.description ?? '');
    // Si es edición, usar la fecha existente; si es nuevo, empezar en blanco
    date = a?.date;
    priority = a?.priority; // Empieza en blanco para nuevo recordatorio
    location = a?.location;
    object = a?.object;
    repetitive = a?.repetitive ?? false;
    repeatFrequency = a?.repeatFrequency;
    selectedWeekdays = a?.selectedWeekdays ?? [];
    customColor = a?.color; // Empieza en blanco para nuevo recordatorio
  }

  @override
  void dispose() {
    titleCtrl.dispose();
    descCtrl.dispose();
    super.dispose();
  }

  void _openColorPicker() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Elegir color'),
        content: SingleChildScrollView(
          child: BlockPicker(
            pickerColor: customColor ??
                (priority != null ? defaultColorFor(priority!) : Colors.blue),
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
        // Botón de marcar todos
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
        // Selector de días individuales
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

    return AlertDialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
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
                decoration: InputDecoration(
                  labelText: 'Título *',
                  hintText: 'Ingresa el título del recordatorio',
                  prefixIcon: const Icon(Icons.title),
                  errorText: titleError,
                ),
                onChanged: (value) {
                  if (titleError != null && value.trim().isNotEmpty) {
                    setState(() => titleError = null);
                  }
                },
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
                          initialDate: date?.isAfter(DateTime.now()) ?? false
                              ? date!
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
                              date?.hour ?? 0,
                              date?.minute ?? 0,
                            );
                            dateError = null; // Limpiar error al seleccionar
                          });
                        }
                      },
                      child: InputDecorator(
                        decoration: InputDecoration(
                          labelText: 'Fecha *',
                          border: const OutlineInputBorder(),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          errorText: dateError,
                        ),
                        child: Text(
                          date != null
                              ? '${date!.day.toString().padLeft(2, '0')}/${date!.month.toString().padLeft(2, '0')}/${date!.year}'
                              : 'Selecciona una fecha',
                          style: TextStyle(
                            fontSize: 16,
                            color: date != null ? Colors.black87 : Colors.grey,
                          ),
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
                          initialTime: date != null
                              ? TimeOfDay.fromDateTime(date!)
                              : TimeOfDay.now(),
                          helpText: 'Selecciona la hora de la alerta',
                          cancelText: 'Cancelar',
                          confirmText: 'Aceptar',
                        );
                        if (picked != null) {
                          setState(() {
                            final now = DateTime.now();
                            date = DateTime(
                              date?.year ?? now.year,
                              date?.month ?? now.month,
                              date?.day ?? now.day,
                              picked.hour,
                              picked.minute,
                            );
                            timeError = null; // Limpiar error al seleccionar
                          });
                        }
                      },
                      child: InputDecorator(
                        decoration: InputDecoration(
                          labelText: 'Hora *',
                          border: const OutlineInputBorder(),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          errorText: timeError,
                        ),
                        child: Text(
                          date != null
                              ? '${date!.hour.toString().padLeft(2, '0')}:${date!.minute.toString().padLeft(2, '0')}'
                              : 'Selecciona una hora',
                          style: TextStyle(
                            fontSize: 16,
                            color: date != null ? Colors.black87 : Colors.grey,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              _vGap,
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text('❗',
                          style: TextStyle(
                            color: Colors.grey.shade500,
                            fontSize: 18,
                          )),
                      const SizedBox(width: 4),
                      Text('Prioridad',
                          style: Theme.of(context).textTheme.titleSmall),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildPriorityChip(
                        'Baja',
                        AlertPriority.baja,
                        const Color(0xFF6A4C93),
                      ),
                      _buildPriorityChip(
                        'Media',
                        AlertPriority.media,
                        Colors.amber.shade600,
                      ),
                      _buildPriorityChip(
                        'Alta',
                        AlertPriority.alta,
                        Colors.red.shade400,
                      ),
                    ],
                  ),
                ],
              ),
              _vGap,
              Row(
                children: [
                  const Text('Color:  '),
                  Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      color: customColor ??
                          (priority != null
                              ? defaultColorFor(priority!)
                              : Colors.grey),
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
              SwitchListTile(
                secondary: const Icon(Icons.repeat_rounded),
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

            // Validar todos los campos obligatorios
            bool hasErrors = false;

            if (trimmedTitle.isEmpty) {
              setState(() => titleError = 'El título es obligatorio');
              hasErrors = true;
            }

            if (date == null) {
              setState(() {
                dateError = 'Selecciona una fecha';
                timeError = 'Selecciona una hora';
              });
              hasErrors = true;
            }

            if (hasErrors) {
              return;
            }

            // Validar que la fecha/hora no sea anterior a ahora
            final now = DateTime.now();
            if (date!.isBefore(now)) {
              setState(() {
                dateError = 'La fecha y hora no pueden ser anteriores';
                timeError = 'La fecha y hora no pueden ser anteriores';
              });
              return;
            }

            // Asegurar que priority tenga un valor por defecto si no se seleccionó
            final finalPriority = priority ?? AlertPriority.media;

            // Asegurar que el color se guarde correctamente
            final finalColor = customColor ?? defaultColorFor(finalPriority);
            print('🎨 Color guardado: ${finalColor.value.toRadixString(16)}');

            final result = AlertData(
              id: widget.alert?.id ?? 'alert${Random().nextInt(100000)}',
              title: trimmedTitle,
              description: descCtrl.text.trim(),
              date: date!,
              priority: finalPriority,
              location: location,
              object: object,
              repetitive: repetitive,
              repeatFrequency:
                  repetitive ? (repeatFrequency ?? 'semanal') : null,
              active: widget.alert?.active ?? true,
              color: finalColor,
              imagePath: widget.alert?.imagePath,
              selectedWeekdays:
                  selectedWeekdays.isNotEmpty ? selectedWeekdays : null,
            ); // Programar la notificación/alarma
            if (date!.isAfter(DateTime.now())) {
              try {
                if (repetitive && selectedWeekdays.isNotEmpty) {
                  // Alarma repetitiva para días específicos
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
                  // Alarma única
                  await NotificationService().scheduleAlarmNotification(
                    id: result.id.hashCode,
                    title: 'Alarma: ${result.title}',
                    body: result.description.isNotEmpty
                        ? result.description
                        : 'Es hora de tu alarma',
                    scheduledDate: result.date,
                  );
                }

                // Verificar que la notificación se programó correctamente
                final pending =
                    await NotificationService().getPendingNotifications();
                print('✅ Notificación programada exitosamente');
                print(
                    '📌 Total de notificaciones pendientes: ${pending.length}');
                for (var notif in pending) {
                  print('   - ID: ${notif.id}, Título: ${notif.title}');
                }
              } catch (e) {
                // Si hay error con las notificaciones, mostrar mensaje
                if (mounted) {
                  print('❌ Error al programar alarma: $e');
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error al programar alarma: $e')),
                  );
                }
              }
            } else {
              print(
                  '⚠️  La fecha es anterior a ahora, no se programó notificación');
            }

            Navigator.pop(context, result);
          },
          icon: const Icon(Icons.save),
          label: const Text('Guardar'),
        ),
      ],
    );
  }

  Widget _buildPriorityChip(String label, AlertPriority value, Color color) {
    final isSelected = priority == value;
    return Expanded(
      child: InkWell(
        onTap: () {
          setState(() {
            priority = value;
            customColor = color;
          });
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? color.withOpacity(0.15) : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? color : Colors.grey.shade300,
              width: isSelected ? 2.5 : 1.5,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: color.withOpacity(0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    )
                  ]
                : null,
          ),
          child: Column(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  value == AlertPriority.alta
                      ? Icons.priority_high
                      : value == AlertPriority.media
                          ? Icons.unfold_more
                          : Icons.trending_down,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? color : Colors.grey.shade600,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class AlertEditDialog extends StatefulWidget {
  const AlertEditDialog({
    required this.alert,
    this.userEmail,
  });
  final AlertData? alert;
  final String? userEmail;

  @override
  State<AlertEditDialog> createState() => AlertEditDialogState();
}
