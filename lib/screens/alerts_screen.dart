import 'dart:math';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'alert_detail_screen.dart' as detail;
import '../services/notification_service.dart';

// Variable global eliminada, se declara dentro de la clase correspondiente

enum AlertPriority { baja, media, alta }

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
  final d = date.day.toString().padLeft(2, '0');
  final m = date.month.toString().padLeft(2, '0');
  final y = date.year.toString();
  return '$d/$m/$y';
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
  });
}

class AlertsScreen extends StatefulWidget {
  const AlertsScreen({super.key});
  @override
  State<AlertsScreen> createState() => _AlertsScreenState();
}

class _AlertsScreenState extends State<AlertsScreen> {
  Set<String> selectedAlerts = {};
  int tabIndex = 0;
  bool selectionMode = false;
  final List<AlertData> _alerts = [
    // Actuales con todos los campos
    AlertData(
      id: 'a1',
      title: 'Garantía del portátil vence',
      description:
          'Recuerda renovar la garantía extendida antes de que caduque para seguir protegido',
      date: DateTime.now().add(const Duration(days: 45, hours: 14)),
      priority: AlertPriority.media,
      active: true,
      color: Colors.lightBlue.shade400,
      location: 'Oficina - Escritorio principal',
      object: 'MacBook Pro 14"',
      repetitive: false,
    ),
    AlertData(
      id: 'a2',
      title: 'Cambiar filtros del aire',
      description:
          'Los filtros del sistema de aire acondicionado necesitan ser reemplazados cada 3 meses',
      date: DateTime.now().add(const Duration(days: 7, hours: 9)),
      priority: AlertPriority.alta,
      active: true,
      color: Colors.red.shade400,
      location: 'Casa - Sala de estar',
      object: 'Aire acondicionado Samsung',
      repetitive: true,
      repeatFrequency: 'Cada 3 meses',
    ),
    AlertData(
      id: 'a3',
      title: 'Revisar extintores',
      description:
          'Inspección anual obligatoria de los extintores de incendios',
      date:
          DateTime.now().add(const Duration(days: 15, hours: 10, minutes: 30)),
      priority: AlertPriority.alta,
      active: true,
      color: Colors.orange.shade600,
      location: 'Oficina - Área común',
      object: 'Extintor ABC 6kg',
      repetitive: true,
      repeatFrequency: 'Anual',
    ),
    AlertData(
      id: 'a4',
      title: 'Mantenimiento coche',
      description: 'Cambio de aceite y revisión general del vehículo',
      date: DateTime.now().add(const Duration(days: 3, hours: 16)),
      priority: AlertPriority.media,
      active: true,
      color: Colors.blue.shade500,
      location: 'Garaje',
      object: 'Toyota Corolla 2020',
      repetitive: true,
      repeatFrequency: 'Cada 6 meses',
    ),
    // Pasadas
    AlertData(
      id: 'p1',
      title: 'Pago de servicios',
      description: 'Pagar facturas de luz, agua e internet del mes',
      date: DateTime.now().subtract(const Duration(days: 2, hours: 5)),
      priority: AlertPriority.alta,
      active: true,
      color: Colors.red.shade300,
      location: 'Casa',
      object: null,
      repetitive: true,
      repeatFrequency: 'Mensual',
    ),
    AlertData(
      id: 'p2',
      title: 'Regar plantas',
      description: 'Regar todas las plantas del jardín',
      date: DateTime.now().subtract(const Duration(days: 1, hours: 8)),
      priority: AlertPriority.baja,
      active: true,
      color: Colors.green.shade300,
      location: 'Casa - Jardín',
      object: 'Plantas ornamentales',
      repetitive: true,
      repeatFrequency: 'Cada 2 días',
    ),
    AlertData(
      id: 'p3',
      title: 'Renovar suscripción',
      description: 'Renovar suscripción premium de streaming',
      date: DateTime.now().subtract(const Duration(days: 5, hours: 12)),
      priority: AlertPriority.media,
      active: true,
      color: Colors.purple.shade300,
      location: null,
      object: null,
      repetitive: false,
    ),
    // Desactivada
    AlertData(
      id: 'd1',
      title: 'Alerta desactivada',
      description: 'Esta alerta fue desactivada temporalmente',
      date: DateTime.now().add(const Duration(days: 20)),
      priority: AlertPriority.baja,
      active: false,
      color: Colors.grey.shade400,
      location: 'Casa',
      object: 'Artículo de prueba',
      repetitive: false,
    ),
  ];

  List<AlertData> get actuales =>
      _alerts.where((a) => a.active && a.date.isAfter(DateTime.now())).toList();
  List<AlertData> get pasadas => _alerts
      .where((a) => a.active && a.date.isBefore(DateTime.now()))
      .toList();
  List<AlertData> get importantes => _alerts
      .where((a) =>
          a.priority == AlertPriority.alta &&
          a.active &&
          a.date.isAfter(DateTime.now()))
      .toList();
  List<AlertData> get proximas => _alerts
      .where((a) =>
          a.active &&
          a.date.isAfter(DateTime.now()) &&
          a.priority != AlertPriority.alta)
      .toList();
  List<AlertData> get desactivadas => _alerts.where((a) => !a.active).toList();

  void _toggleAlertActive(AlertData alert) {
    setState(() {
      alert.active = !alert.active;
    });
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

  void _openAlertDialog() async {
    final created = await _openEditor(context, null);
    if (created != null) {
      setState(() => _alerts.add(created));
    }
  }

  void _deleteSelected() {
    setState(() {
      _alerts.removeWhere((a) => selectedAlerts.contains(a.id));
      selectedAlerts.clear();
      selectionMode = false;
    });
  }

  Widget _buildTabBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: InkWell(
              onTap: () => setState(() => tabIndex = 0),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color:
                      tabIndex == 0 ? Colors.blue.shade50 : Colors.transparent,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Center(
                  child: Text(
                    'Actuales',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color:
                          tabIndex == 0 ? Colors.blue.shade800 : Colors.black54,
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: InkWell(
              onTap: () => setState(() => tabIndex = 1),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color:
                      tabIndex == 1 ? Colors.blue.shade50 : Colors.transparent,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Center(
                  child: Text(
                    'Pasadas',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color:
                          tabIndex == 1 ? Colors.blue.shade800 : Colors.black54,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(String title, List<AlertData> alerts,
      {bool showSelection = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (alerts.isNotEmpty) ...[
          _sectionHeader(title),
          ...alerts.map((a) => _AlertCard(
                alert: a,
                onTap: () {
                  if (showSelection && selectionMode) {
                    setState(() {
                      if (selectedAlerts.contains(a.id)) {
                        selectedAlerts.remove(a.id);
                      } else {
                        selectedAlerts.add(a.id);
                      }
                    });
                  } else {
                    // Navegar al detalle de la alerta
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => detail.AlertDetailScreen(
                          alert: detail.AlertData(
                            id: a.id,
                            title: a.title,
                            description: a.description,
                            date: a.date,
                            priority:
                                detail.AlertPriority.values[a.priority.index],
                            location: a.location,
                            object: a.object,
                            repetitive: a.repetitive,
                            repeatFrequency: a.repeatFrequency,
                            active: a.active,
                            color: a.color,
                            imagePath: a.imagePath,
                          ),
                        ),
                      ),
                    );
                  }
                },
                onToggleActive: () => _toggleAlertActive(a),
                onDelete: () {
                  setState(() => _alerts.remove(a));
                },
                showCheckbox: showSelection && selectionMode,
                checked: selectedAlerts.contains(a.id),
              )),
          const SizedBox(height: 16),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false, // <- quita la flecha de retroceso
        title: const Text('Alertas'),
        actions: [
          if (tabIndex == 1 && pasadas.isNotEmpty)
            IconButton(
              icon: Icon(selectionMode ? Icons.close : Icons.select_all),
              tooltip: selectionMode ? 'Cancelar selección' : 'Seleccionar',
              onPressed: () => setState(() {
                selectionMode = !selectionMode;
                if (!selectionMode) selectedAlerts.clear();
              }),
            ),
        ],
      ),
      floatingActionButton: tabIndex == 0
          ? FloatingActionButton(
              onPressed: () => _openAlertDialog(),
              tooltip: 'Añadir Alerta',
              child: const Icon(Icons.add_alert),
            )
          : null,
      body: tabIndex == 0
          ? ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: [
                _buildTabBar(),
                _buildSection('Importantes', importantes),
                _buildSection('Actuales', proximas),
                _buildSection('Desactivadas', desactivadas),
              ],
            )
          : Stack(
              children: [
                ListView(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  children: [
                    _buildTabBar(),
                    _buildSection('Pasadas', pasadas, showSelection: true),
                  ],
                ),
                if (selectionMode && selectedAlerts.isNotEmpty)
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: Container(
                      color: Theme.of(context).colorScheme.surface,
                      padding: const EdgeInsets.all(12),
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.delete),
                        label: const Text('Eliminar Seleccionadas'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                        ),
                        onPressed: _deleteSelected,
                      ),
                    ),
                  ),
              ],
            ),
    );
  }
}

class _AlertCard extends StatelessWidget {
  const _AlertCard({
    required this.alert,
    required this.onTap,
    required this.onToggleActive,
    required this.onDelete,
    this.showCheckbox = false,
    this.checked = false,
  });

  final AlertData alert;
  final VoidCallback onTap;
  final VoidCallback onToggleActive;
  final VoidCallback onDelete;
  final bool showCheckbox;
  final bool checked;

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
        return Icons.check_circle_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateText = _dateLabel(alert.date);
    // Detect if this alert is in 'pasadas' tab
    final isPasada = alert.date.isBefore(DateTime.now());

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Stack(
          children: [
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
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  if (showCheckbox)
                    Checkbox(
                      value: checked,
                      onChanged: (_) => onTap(),
                    ),
                  if (showCheckbox) const SizedBox(width: 8),
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: (_color.withOpacity(0.15)),
                    child: Icon(_icon, color: _color),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
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
                                fontSize: 14,
                                color: Colors.grey.shade600,
                                fontWeight: FontWeight.w600,
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
                  if (alert.imagePath != null &&
                      alert.imagePath!.isNotEmpty) ...[
                    const SizedBox(width: 10),
                    _MiniThumb(path: alert.imagePath!),
                  ],
                  const SizedBox(width: 6),
                  PopupMenuButton<String>(
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
                              child: Text('Eliminar'),
                            ),
                          ]
                        : [
                            PopupMenuItem(
                              value: 'toggle',
                              child:
                                  Text(alert.active ? 'Desactivar' : 'Activar'),
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
  List<int> selectedWeekdays = []; // Días de la semana seleccionados (1=Lunes, 7=Domingo)

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
    customColor = a?.color ?? _defaultColorFor(priority);
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

  // Removed unused _pickDate method

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

    return Wrap(
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
    );
  }

  String _getSelectedDaysText() {
    if (selectedWeekdays.isEmpty) return '';
    
    final dayNames = {
      1: 'Lunes', 2: 'Martes', 3: 'Miércoles', 4: 'Jueves',
      5: 'Viernes', 6: 'Sábado', 7: 'Domingo'
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
      title: Text(existing == null ? 'Nueva alerta' : 'Editar alerta'),
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
                    customColor = _defaultColorFor(priority);
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
              SwitchListTile(
                value: repetitive,
                onChanged: (v) => setState(() => repetitive = v),
                title: const Text('Repetir'),
                contentPadding: EdgeInsets.zero,
              ),
              if (repetitive) ...[
                _vGap,
                Text('Selecciona los días que se repetirá:', style: Theme.of(context).textTheme.titleMedium),
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
        TextButton(
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
              selectedWeekdays: selectedWeekdays.isNotEmpty ? selectedWeekdays : null,
            );

            // Programar la notificación/alarma
            if (date.isAfter(DateTime.now())) {
              try {
                if (repetitive && selectedWeekdays.isNotEmpty) {
                  // Alarma repetitiva para días específicos
                  await NotificationService().scheduleRepeatingAlarmNotification(
                    baseId: result.id.hashCode,
                    title: 'Alarma: ${result.title}',
                    body: result.description.isNotEmpty ? result.description : 'Es hora de tu alarma',
                    scheduledDate: result.date,
                    weekdays: selectedWeekdays,
                  );
                } else {
                  // Alarma única
                  await NotificationService().scheduleAlarmNotification(
                    id: result.id.hashCode,
                    title: 'Alarma: ${result.title}',
                    body: result.description.isNotEmpty ? result.description : 'Es hora de tu alarma',
                    scheduledDate: result.date,
                  );
                }
              } catch (e) {
                // Si hay error con las notificaciones, mostrar mensaje
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error al programar alarma: $e')),
                  );
                }
              }
            }

            Navigator.pop(context, result);
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
