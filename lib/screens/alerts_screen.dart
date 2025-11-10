import 'dart:math';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';

enum AlertPriority { baja, media, alta }

class AlertData {
  String id;
  String title;
  String description;
  DateTime date;
  AlertPriority priority;
  String? location;
  String? object;
  bool repetitive;
  String? repeatFrequency; // 'semanal', 'mensual', 'anual'
  bool active;
  Color? color; // color elegido por el usuario (opcional)
  String? imagePath; // ruta/URL (XFile.path) de la imagen opcional

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
  });
}

/// Color por defecto según prioridad (si la alerta no tiene color propio)
Color _defaultColorFor(AlertPriority p) {
  switch (p) {
    case AlertPriority.alta:
      return Colors.red.shade400;
    case AlertPriority.media:
      return Colors.amber.shade600;
    case AlertPriority.baja:
    default:
      return Colors.blue.shade400;
  }
}

/// Etiqueta de fecha amigable: "Hoy", "Mañana", "En X días", "Ayer", o dd/MM/yyyy
String _dateLabel(DateTime date) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final target = DateTime(date.year, date.month, date.day);
  final diff = target.difference(today).inDays;

  if (diff == 0) return 'Hoy';
  if (diff == 1) return 'Mañana';
  if (diff == -1) return 'Ayer';
  if (diff > 1 && diff <= 7) return 'En $diff días';
  if (diff < -1 && diff >= -7) return 'Hace ${diff.abs()} días';
  // formato corto dd/MM/yyyy
  final d = date.day.toString().padLeft(2, '0');
  final m = date.month.toString().padLeft(2, '0');
  final y = date.year.toString();
  return '$d/$m/$y';
}

class AlertsScreen extends StatefulWidget {
  const AlertsScreen({super.key});

  @override
  State<AlertsScreen> createState() => _AlertsScreenState();
}

class _AlertsScreenState extends State<AlertsScreen> {
  final List<AlertData> _alerts = [
    AlertData(
      id: 'a1',
      title: 'Garantía del portátil vence',
      description: 'Artículo: MacBook Pro 14"\nLugar: Oficina',
      date: DateTime.now().add(const Duration(days: 45)),
      priority: AlertPriority.baja,
      active: true,
      color: Colors.lightBlue.shade400,
      imagePath: null,
    ),
    AlertData(
      id: 'a2',
      title: 'test',
      description: '',
      date: DateTime.now(),
      priority: AlertPriority.alta,
      active: true,
      color: Colors.purple.shade400,
    ),
    AlertData(
      id: 'a3',
      title: 'Test',
      description: 'test',
      date: DateTime.now().add(const Duration(days: 4)),
      priority: AlertPriority.media,
      active: true,
      color: Colors.purple.shade400,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final importantes = _alerts
        .where((a) => a.active && a.priority == AlertPriority.alta)
        .toList()
      ..sort((a, b) => a.date.compareTo(b.date));

    final actuales = _alerts
        .where((a) => a.active && a.priority != AlertPriority.alta)
        .toList()
      ..sort((a, b) => a.date.compareTo(b.date));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Alertas'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final created = await _openEditor(context, null);
          if (created != null) {
            setState(() => _alerts.add(created));
          }
        },
        icon: const Icon(Icons.add),
        label: const Text('Nueva'),
      ),
      body: ListView(
        children: [
          const SizedBox(height: 8),
          _sectionHeader('Importantes'),
          ...importantes.map((a) => _AlertCard(
                alert: a,
                onTap: () async {
                  final edited = await _openEditor(context, a);
                  if (edited != null) {
                    setState(() {
                      final idx = _alerts.indexWhere((x) => x.id == a.id);
                      if (idx >= 0) _alerts[idx] = edited;
                    });
                  }
                },
                onToggleActive: () {
                  setState(() => a.active = !a.active);
                },
                onDelete: () {
                  setState(() => _alerts.removeWhere((x) => x.id == a.id));
                },
              )),
          const SizedBox(height: 16),
          _sectionHeader('Actuales'),
          ...actuales.map((a) => _AlertCard(
                alert: a,
                onTap: () async {
                  final edited = await _openEditor(context, a);
                  if (edited != null) {
                    setState(() {
                      final idx = _alerts.indexWhere((x) => x.id == a.id);
                      if (idx >= 0) _alerts[idx] = edited;
                    });
                  }
                },
                onToggleActive: () {
                  setState(() => a.active = !a.active);
                },
                onDelete: () {
                  setState(() => _alerts.removeWhere((x) => x.id == a.id));
                },
              )),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _sectionHeader(String text) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Text(
        text,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
      ),
    );
  }

  Future<AlertData?> _openEditor(
      BuildContext context, AlertData? existing) async {
    return showDialog<AlertData>(
      context: context,
      builder: (_) => _AlertEditDialog(alert: existing),
      barrierDismissible: false,
    );
  }
}

class _AlertCard extends StatelessWidget {
  const _AlertCard({
    required this.alert,
    required this.onTap,
    required this.onToggleActive,
    required this.onDelete,
  });

  final AlertData alert;
  final VoidCallback onTap;
  final VoidCallback onToggleActive;
  final VoidCallback onDelete;

  Color get _color {
    if (!alert.active) return Colors.grey.shade400;
    return alert.color ?? _defaultColorFor(alert.priority);
  }

  IconData get _icon {
    if (!alert.active) return Icons.pause_circle_filled_rounded;
    switch (alert.priority) {
      case AlertPriority.alta:
        return Icons.warning_amber_rounded;
      case AlertPriority.media:
        return Icons.notifications_active_rounded;
      case AlertPriority.baja:
      default:
        return Icons.check_circle_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateText = _dateLabel(alert.date);

    return Card(
      margin: const EdgeInsets.symmetric(
          horizontal: 12, vertical: 6), // antes: vertical: 6
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      clipBehavior: Clip.antiAlias, // permite recorte con esquinas redondeadas
      child: InkWell(
        onTap: onTap,
        child: Stack(
          children: [
            // Barra lateral de color redondeada
            Positioned.fill(
              child: Align(
                alignment: Alignment.centerLeft,
                child: Container(
                  width: 6,
                  decoration: BoxDecoration(
                    color: _color,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(16),
                      bottomLeft: Radius.circular(16),
                    ),
                  ),
                ),
              ),
            ),

            // Contenido
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Ícono circular con el mismo color
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: (_color.withOpacity(0.15)),
                    child: Icon(_icon, color: _color),
                  ),
                  const SizedBox(width: 12),

                  // Texto
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Título + fecha
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(
                                alert.title,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: alert.active
                                      ? Colors.black87
                                      : Colors.black38,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              dateText,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),

                        if (alert.description.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            alert.description,
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey.shade700,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],

                        // Chips (opcional): objeto/lugar
                        if ((alert.object?.isNotEmpty ?? false) ||
                            (alert.location?.isNotEmpty ?? false)) ...[
                          const SizedBox(height: 6),
                          Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: [
                              if (alert.object?.isNotEmpty ?? false)
                                Chip(
                                  label: Text('Artículo: ${alert.object}'),
                                  visualDensity: VisualDensity.compact,
                                  side: BorderSide(
                                      color: _color.withOpacity(0.4)),
                                ),
                              if (alert.location?.isNotEmpty ?? false)
                                Chip(
                                  label: Text('Lugar: ${alert.location}'),
                                  visualDensity: VisualDensity.compact,
                                  side: BorderSide(
                                      color: _color.withOpacity(0.4)),
                                ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),

                  // Miniatura (opcional)
                  if (alert.imagePath != null &&
                      alert.imagePath!.isNotEmpty) ...[
                    const SizedBox(width: 10),
                    _MiniThumb(path: alert.imagePath!),
                  ],

                  const SizedBox(width: 6),

                  // Menú acciones
                  PopupMenuButton<String>(
                    onSelected: (v) {
                      switch (v) {
                        case 'toggle':
                          onToggleActive();
                          break;
                        case 'delete':
                          onDelete();
                          break;
                      }
                    },
                    itemBuilder: (ctx) => [
                      PopupMenuItem(
                        value: 'toggle',
                        child: Text(alert.active ? 'Desactivar' : 'Activar'),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Text('Eliminar'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Miniatura que carga bytes desde XFile sin usar dart:io (sirve para Web)
class _MiniThumb extends StatelessWidget {
  const _MiniThumb({required this.path});

  final String path;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => _ImageViewer(path: path)),
      ),
      child: FutureBuilder<Uint8List>(
        future: XFile(path).readAsBytes(),
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done || !snap.hasData) {
            return const SizedBox(width: 56, height: 56);
          }
          return ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.memory(
              snap.data!,
              width: 56,
              height: 56,
              fit: BoxFit.cover,
            ),
          );
        },
      ),
    );
  }
}

/// Visor de imagen a pantalla completa
class _ImageViewer extends StatelessWidget {
  const _ImageViewer({required this.path});
  final String path;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Imagen')),
      body: Center(
        child: FutureBuilder<Uint8List>(
          future: XFile(path).readAsBytes(),
          builder: (context, snap) {
            if (snap.connectionState != ConnectionState.done || !snap.hasData) {
              return const SizedBox.shrink();
            }
            return InteractiveViewer(
              child: Image.memory(snap.data!),
            );
          },
        ),
      ),
    );
  }
}

class _AlertEditDialog extends StatefulWidget {
  const _AlertEditDialog({required this.alert});
  final AlertData? alert;

  @override
  State<_AlertEditDialog> createState() => _AlertEditDialogState();
}

class _AlertEditDialogState extends State<_AlertEditDialog> {
  late TextEditingController titleCtrl;
  late TextEditingController descCtrl;

  late DateTime date;
  late AlertPriority priority;
  String? location;
  String? object;
  bool repetitive = false;
  String? repeatFrequency;

  Color? customColor;
  final _picker = ImagePicker();
  XFile? _pickedImage; // imagen nueva seleccionada (si aplica)

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

    // si ya tenía color, úsalo; si no, toma el de prioridad
    customColor = a?.color ?? _defaultColorFor(priority);
    _pickedImage = null; // mantenemos la imagen previa vía imagePath al guardar
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

  Future<void> _pickDate() async {
    final r = await showDatePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      initialDate: date,
    );
    if (r != null) {
      setState(() => date = r);
    }
  }

  void _openColorPicker() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Elegir color'),
        content: SingleChildScrollView(
          child: BlockPicker(
            pickerColor: customColor ?? _defaultColorFor(priority),
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

  static const _vGap = SizedBox(height: 16); // gap estándar entre campos
  static const _sectionDivider =
      Divider(height: 30, thickness: 0.1); // separa secciones

  @override
  Widget build(BuildContext context) {
    final existing = widget.alert;
    final existingPath = existing?.imagePath;

    return AlertDialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      titlePadding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
      contentPadding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
      actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      title: Text(existing == null ? 'Nueva alerta' : 'Editar alerta'),
      content: SizedBox(
        width: 520,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // --- Datos básicos ---
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
                              : DateTime.now().add(const Duration(days: 1)),
                          firstDate:
                              DateTime.now().add(const Duration(days: 1)),
                          lastDate: DateTime(2100),
                          helpText: 'Selecciona la fecha de la alerta',
                          cancelText: 'Cancelar',
                          confirmText: 'Aceptar',
                        );
                        if (picked != null && picked.isAfter(DateTime.now())) {
                          setState(() => date = picked);
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
                ],
              ),
              _vGap,

              // --- Prioridad ---
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
                    customColor = _defaultColorFor(priority);
                  });
                },
              ),
              _vGap,

              // --- Color ---
              Row(
                children: [
                  const Text('Color:  '),
                  Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      color: customColor ?? _defaultColorFor(priority),
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

              // --- Lugar / Artículo ---
              TextField(
                decoration: const InputDecoration(
                  labelText: 'Lugar (opcional)',
                  prefixIcon: Icon(Icons.place_outlined),
                ),
                onChanged: (v) => location = v.trim().isEmpty ? null : v.trim(),
                controller: TextEditingController(text: location),
              ),
              _sectionDivider,

              // --- Imagen (opcional) ---
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
                  const SizedBox(width: 16), // más aire horizontal
                  Expanded(
                    child: Wrap(
                      spacing: 12, // más separación entre botones
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
                          TextButton.icon(
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

              // --- Repetición ---
              SwitchListTile(
                value: repetitive,
                onChanged: (v) => setState(() => repetitive = v),
                title: const Text('Repetir'),
                contentPadding:
                    EdgeInsets.zero, // evita sumar padding lateral extra
              ),
              if (repetitive) ...[
                _vGap,
                DropdownButtonFormField<String>(
                  value: repeatFrequency ?? 'semanal',
                  items: const [
                    DropdownMenuItem(value: 'semanal', child: Text('Semanal')),
                    DropdownMenuItem(value: 'mensual', child: Text('Mensual')),
                    DropdownMenuItem(value: 'anual', child: Text('Anual')),
                  ],
                  onChanged: (v) => setState(() => repeatFrequency = v),
                  decoration: const InputDecoration(
                    labelText: 'Frecuencia',
                    prefixIcon: Icon(Icons.repeat),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, null),
          child: const Text('Cancelar'),
        ),
        ElevatedButton.icon(
          onPressed: () {
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
            );

            Navigator.pop(context, result);
          },
          icon: const Icon(Icons.save),
          label: const Text('Guardar'),
        ),
      ],
    );
  }

  /// Miniatura dentro del editor (acepta imagen existente o la elegida en esta sesión)
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

    Future<Uint8List> _loadBytes() => XFile(path).readAsBytes();

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: FutureBuilder<Uint8List>(
        future: _loadBytes(),
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
