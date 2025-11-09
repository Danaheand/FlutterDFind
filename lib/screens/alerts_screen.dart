import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/font_size_provider.dart';
import 'dart:math';
import 'inventory_screen.dart';

enum AlertPriority { alta, media, baja }

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
  });
}

class AlertsScreen extends StatefulWidget {
  const AlertsScreen({super.key});
  @override
  State<AlertsScreen> createState() => _AlertsScreenState();
}

class _AlertsScreenState extends State<AlertsScreen> {
  // Simulación de base de datos de alertas
  List<AlertData> alerts = [
    AlertData(
      id: 'alert1',
      title: 'Leche caduca mañana',
      description: 'Revisar la leche en la nevera.',
      date: DateTime(2025, 10, 24),
      priority: AlertPriority.alta,
      location: 'Cocina ► Refrigerador',
      object: 'Leche Entera',
      repetitive: false,
      active: true,
    ),
    AlertData(
      id: 'alert2',
      title: 'Mantenimiento aire acondicionado',
      description: 'Llamar al técnico.',
      date: DateTime(2025, 10, 28),
      priority: AlertPriority.media,
      location: 'Dormitorio Principal',
      object: 'Aire Acondicionado Split',
      repetitive: true,
      repeatFrequency: 'anual',
      active: true,
    ),
    AlertData(
      id: 'alert3',
      title: 'Garantía del portátil vence',
      description: '',
      date: DateTime(2025, 12, 23),
      priority: AlertPriority.baja,
      location: 'Oficina',
      object: 'MacBook Pro 14"',
      repetitive: false,
      active: true,
    ),
    AlertData(
      id: 'alert4',
      title: 'Pagar servicio de luz',
      description: 'Factura de luz vence hoy.',
      date: DateTime(2025, 10, 23),
      priority: AlertPriority.alta,
      location: 'Casa Principal',
      object: null,
      repetitive: false,
      active: true,
    ),
    AlertData(
      id: 'alert5',
      title: 'Revisión del coche',
      description: 'Revisión de los 50,000km.',
      date: DateTime(2025, 10, 15),
      priority: AlertPriority.media,
      location: 'Garaje',
      object: null,
      repetitive: false,
      active: true,
    ),
    AlertData(
      id: 'alert6',
      title: 'Comprar comida del perro',
      description: 'Se está acabando.',
      date: DateTime(2025, 11, 1),
      priority: AlertPriority.media,
      location: 'Despensa',
      object: null,
      repetitive: true,
      repeatFrequency: 'mensual',
      active: false,
    ),
    AlertData(
      id: 'alert7',
      title: 'Pagar tarjeta crédito',
      description: '',
      date: DateTime(2025, 9, 30),
      priority: AlertPriority.alta,
      location: null,
      object: null,
      repetitive: false,
      active: true,
    ),
  ];

  int tabIndex = 0; // 0: actuales, 1: pasadas
  bool selectionMode = false;
  Set<String> selectedAlerts = {};

  DateTime get today =>
      DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);

  List<AlertData> get importantes => alerts
      .where((a) => a.active && !isPast(a) && a.priority == AlertPriority.alta)
      .toList()
    ..sort((a, b) => a.date.compareTo(b.date));
  List<AlertData> get proximas => alerts
      .where((a) => a.active && !isPast(a) && a.priority != AlertPriority.alta)
      .toList()
    ..sort((a, b) => a.date.compareTo(b.date));
  List<AlertData> get desactivadas => alerts.where((a) => !a.active).toList()
    ..sort((a, b) => b.date.compareTo(a.date));
  List<AlertData> get pasadas =>
      alerts.where((a) => a.active && isPast(a)).toList()
        ..sort((a, b) => b.date.compareTo(a.date));

  bool isPast(AlertData a) => a.date.isBefore(today);

  void _openAlertDialog({AlertData? edit}) async {
    final result = await showDialog<AlertData>(
      context: context,
      builder: (_) => _AlertEditDialog(alert: edit),
    );
    if (result != null) {
      // Palabras clave para detectar compras/comida
      final keywords = [
        'comida',
        'comprar',
        'super',
        'mercado',
        'pan',
        'leche',
        'fruta',
        'verdura',
        'carne',
        'huevo',
        'banana',
        'arroz',
        'atun'
      ];
      final lowerTitle = result.title.toLowerCase();
      final lowerDesc = result.description.toLowerCase();
      final isShopping =
          keywords.any((k) => lowerTitle.contains(k) || lowerDesc.contains(k));
      if (isShopping && InventoryScreen.addFromAlertGlobal != null) {
        // Usa el título como nombre del producto
        InventoryScreen.addFromAlertGlobal!(result.title);
      }
      setState(() {
        if (edit != null) {
          final idx = alerts.indexWhere((a) => a.id == edit.id);
          if (idx != -1) alerts[idx] = result;
        } else {
          alerts.add(result);
        }
      });
    }
  }

  void _openAlertView(AlertData alert) async {
    final result = await showDialog<_AlertViewResult>(
      context: context,
      builder: (_) => _AlertViewDialog(alert: alert),
    );
    if (result != null) {
      setState(() {
        if (result.action == 'edit') {
          _openAlertDialog(edit: alert);
        } else if (result.action == 'delete') {
          alerts.removeWhere((a) => a.id == alert.id);
        } else if (result.action == 'deactivate') {
          alert.active = false;
        } else if (result.action == 'reactivate') {
          alert.active = true;
          if (isPast(alert)) {
            alert.date = today;
          }
        }
      });
    }
  }

  void _toggleSelection(String id) {
    setState(() {
      if (selectedAlerts.contains(id)) {
        selectedAlerts.remove(id);
      } else {
        selectedAlerts.add(id);
      }
    });
  }

  void _deleteSelected() {
    setState(() {
      alerts.removeWhere((a) => selectedAlerts.contains(a.id));
      selectedAlerts.clear();
      selectionMode = false;
    });
  }

  Widget _buildTabBar() {
    return Row(
      children: [
        Expanded(
          child: TextButton(
            onPressed: () => setState(() {
              tabIndex = 0;
              selectionMode = false;
            }),
            child: Consumer<FontSizeProvider>(
              builder: (context, fontSizeProvider, _) => Text('Actuales',
                style: TextStyle(
                  color: tabIndex == 0
                      ? Theme.of(context).colorScheme.primary
                      : Colors.grey,
                  fontWeight: FontWeight.bold,
                  fontSize: fontSizeProvider.fontSize,
                ),
              ),
            ),
          ),
        ),
        Expanded(
          child: TextButton(
            onPressed: () => setState(() {
              tabIndex = 1;
              selectionMode = false;
            }),
            child: Consumer<FontSizeProvider>(
              builder: (context, fontSizeProvider, _) => Text('Pasadas',
                style: TextStyle(
                  color: tabIndex == 1
                      ? Theme.of(context).colorScheme.primary
                      : Colors.grey,
                  fontWeight: FontWeight.bold,
                  fontSize: fontSizeProvider.fontSize,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSection(String title, List<AlertData> list) {
    if (list.isEmpty) return const SizedBox();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12),
          child: Consumer<FontSizeProvider>(
            builder: (context, fontSizeProvider, _) => Text(title,
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: fontSizeProvider.fontSize + 2)),
          ),
        ),
        ...list.map((a) => _AlertCard(
              alert: a,
              onTap: () => selectionMode && tabIndex == 1
                  ? _toggleSelection(a.id)
                  : _openAlertView(a),
              selected: selectedAlerts.contains(a.id),
              selectionMode: selectionMode && tabIndex == 1,
            )),
        const SizedBox(height: 8),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Consumer<FontSizeProvider>(
          builder: (context, fontSizeProvider, _) => Text('Alertas', style: TextStyle(fontSize: fontSizeProvider.fontSize + 2)),
        ),
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
                    _buildSection('Pasadas', pasadas),
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
                        label: Consumer<FontSizeProvider>(
                          builder: (context, fontSizeProvider, _) => Text('Eliminar Seleccionadas', style: TextStyle(fontSize: fontSizeProvider.fontSize)),
                        ),
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

// Tarjeta de alerta visualmente fiel a la maqueta
class _AlertCard extends StatelessWidget {
  final AlertData alert;
  final VoidCallback onTap;
  final bool selected;
  final bool selectionMode;
  const _AlertCard(
      {required this.alert,
      required this.onTap,
      this.selected = false,
      this.selectionMode = false});

  Color get _color {
    if (!alert.active) return Colors.grey.shade400;
    switch (alert.priority) {
      case AlertPriority.alta:
        return Colors.red.shade400;
      case AlertPriority.media:
        return Colors.amber.shade600;
      case AlertPriority.baja:
        return Colors.blue.shade400;
    }
  }

  IconData get _icon {
    if (!alert.active) return Icons.remove_circle_outline;
    switch (alert.priority) {
      case AlertPriority.alta:
        return Icons.warning_amber_rounded;
      case AlertPriority.media:
        return Icons.notifications_active_rounded;
      case AlertPriority.baja:
        return Icons.check_circle_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      elevation: selected ? 6 : 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: selected
            ? const BorderSide(color: Colors.blue, width: 2)
            : BorderSide.none,
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                decoration: BoxDecoration(
                  color: _color.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                padding: const EdgeInsets.all(8),
                child: Icon(_icon, color: _color, size: 28),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Consumer<FontSizeProvider>(
                            builder: (context, fontSizeProvider, _) => Text(
                              alert.title,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: alert.active ? Colors.black : Colors.grey,
                                decoration: alert.active
                                    ? null
                                    : TextDecoration.lineThrough,
                                fontSize: fontSizeProvider.fontSize + 2,
                              ),
                            ),
                          ),
                        ),
                        Consumer<FontSizeProvider>(
                          builder: (context, fontSizeProvider, _) => Text(
                            _formatDate(alert.date),
                            style: TextStyle(
                                fontSize: fontSizeProvider.fontSize - 1, color: Colors.grey.shade600),
                          ),
                        ),
                      ],
                    ),
                    if (alert.description.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 2.0),
                        child: Consumer<FontSizeProvider>(
                          builder: (context, fontSizeProvider, _) => Text(alert.description,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(color: Colors.grey.shade700, fontSize: fontSizeProvider.fontSize)),
                        ),
                      ),
                    if (alert.object != null && alert.object!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 2.0),
            child: Consumer<FontSizeProvider>(
              builder: (context, fontSizeProvider, _) => Text('Artículo: ${alert.object}',
                style: TextStyle(
                  fontSize: fontSizeProvider.fontSize - 2, color: Colors.grey.shade600)),
            ),
                      ),
                    if (alert.location != null && alert.location!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 2.0),
            child: Consumer<FontSizeProvider>(
              builder: (context, fontSizeProvider, _) => Text('Lugar: ${alert.location}',
                style: TextStyle(
                  fontSize: fontSizeProvider.fontSize - 2, color: Colors.grey.shade600)),
            ),
                      ),
                  ],
                ),
              ),
              if (selectionMode)
                Padding(
                  padding: const EdgeInsets.only(left: 8, top: 8),
                  child: Icon(
                    selected
                        ? Icons.check_circle
                        : Icons.radio_button_unchecked,
                    color: selected ? Colors.blue : Colors.grey,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

String _formatDate(DateTime d) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final diff = d.difference(today).inDays;
  if (diff == 0) return 'Hoy';
  if (diff == 1) return 'Mañana';
  if (diff < 0 && diff > -7) return 'Hace ${-diff} días';
  if (diff > 1 && diff <= 7) return 'En $diff días';
  return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
}

// Modal de edición/creación de alerta
class _AlertEditDialog extends StatefulWidget {
  final AlertData? alert;
  const _AlertEditDialog({this.alert});
  @override
  State<_AlertEditDialog> createState() => _AlertEditDialogState();
}

class _AlertEditDialogState extends State<_AlertEditDialog> {
  late TextEditingController titleCtrl;
  late TextEditingController descCtrl;
  late DateTime date;
  AlertPriority priority = AlertPriority.baja;
  String? location;
  String? object;
  bool repetitive = false;
  String? repeatFrequency;

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
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      child: Container(
        width: 400,
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              widget.alert == null ? 'Añadir Alerta' : 'Editar Alerta',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 22),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 18),
            TextField(
              controller: titleCtrl,
              decoration: const InputDecoration(labelText: 'Título*'),
              autofocus: true,
            ),
            const SizedBox(height: 14),
            TextField(
              controller: descCtrl,
              decoration: const InputDecoration(labelText: 'Descripción'),
              maxLines: 2,
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: InputDatePickerFormField(
                    initialDate: date,
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2100),
                    onDateSubmitted: (d) => setState(() => date = d),
                    onDateSaved: (d) => setState(() => date = d),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<AlertPriority>(
                    value: priority,
                    items: const [
                      DropdownMenuItem(
                          value: AlertPriority.baja, child: Text('Baja')),
                      DropdownMenuItem(
                          value: AlertPriority.media, child: Text('Media')),
                      DropdownMenuItem(
                          value: AlertPriority.alta, child: Text('Alta')),
                    ],
                    onChanged: (v) =>
                        setState(() => priority = v ?? AlertPriority.baja),
                    decoration: const InputDecoration(labelText: 'Prioridad'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            TextField(
              decoration:
                  const InputDecoration(labelText: 'Ubicación (opcional)'),
              onChanged: (v) => location = v,
              controller: TextEditingController(text: location ?? ''),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Checkbox(
                  value: repetitive,
                  onChanged: (v) => setState(() => repetitive = v ?? false),
                ),
                const Text('Periodicidad de repetición'),
                if (repetitive) ...[
                  const SizedBox(width: 8),
                  DropdownButton<String>(
                    value: repeatFrequency ?? 'semanal',
                    items: const [
                      DropdownMenuItem(value: 'semanal', child: Text('Semana')),
                      DropdownMenuItem(value: 'mensual', child: Text('Mes')),
                      DropdownMenuItem(value: 'anual', child: Text('Año')),
                    ],
                    onChanged: (v) => setState(() => repeatFrequency = v),
                  ),
                ]
              ],
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (titleCtrl.text.trim().isEmpty) return;
                    Navigator.pop(
                      context,
                      AlertData(
                        id: widget.alert?.id ?? 'alert${Random().nextInt(100000)}',
                        title: titleCtrl.text.trim(),
                        description: descCtrl.text.trim(),
                        date: date,
                        priority: priority,
                        location: location,
                        object: object,
                        repetitive: repetitive,
                        repeatFrequency:
                            repetitive ? (repeatFrequency ?? 'semanal') : null,
                        active: widget.alert?.active ?? true,
                      ),
                    );
                  },
                  child: const Text('Guardar'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _AlertViewResult {
  final String action;
  _AlertViewResult(this.action);
}

// Modal de visualización de alerta
class _AlertViewDialog extends StatelessWidget {
  final AlertData alert;
  const _AlertViewDialog({required this.alert});

  @override
  Widget build(BuildContext context) {
    final isPast = alert.date.isBefore(DateTime(
        DateTime.now().year, DateTime.now().month, DateTime.now().day));
    return AlertDialog(
      title: Text(alert.title),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                const Icon(Icons.calendar_today, size: 18, color: Colors.blueGrey),
                const SizedBox(width: 6),
                Text(_formatDate(alert.date) +
                    (alert.repetitive && alert.repeatFrequency != null
                        ? ' (Repite ${alert.repeatFrequency})'
                        : '')),
              ],
            ),
            if (alert.description.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(alert.description),
            ],
            if (alert.object != null && alert.object!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Row(children: [
                const Icon(Icons.inventory_2, size: 18, color: Colors.blueGrey),
                const SizedBox(width: 6),
                Text('Artículo: ${alert.object}')
              ]),
            ],
            if (alert.location != null && alert.location!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Row(children: [
                const Icon(Icons.place, size: 18, color: Colors.blueGrey),
                const SizedBox(width: 6),
                Text('Lugar: ${alert.location}')
              ]),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.priority_high,
                    color: alert.priority == AlertPriority.alta
                        ? Colors.red
                        : alert.priority == AlertPriority.media
                            ? Colors.amber
                            : Colors.blue),
                const SizedBox(width: 6),
                Text(
                    'Prioridad: ${alert.priority.name[0].toUpperCase()}${alert.priority.name.substring(1)}'),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(alert.active ? Icons.check_circle : Icons.cancel,
                    color: alert.active ? Colors.green : Colors.grey),
                const SizedBox(width: 6),
                Text(alert.active ? 'Activa' : 'Desactivada'),
              ],
            ),
          ],
        ),
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              if (alert.active && !isPast)
                TextButton.icon(
                  icon: const Icon(Icons.edit),
                  label: const Text('Modificar'),
                  onPressed: () => Navigator.pop(context, _AlertViewResult('edit')),
                ),
              if (alert.active && !isPast)
                TextButton.icon(
                  icon: const Icon(Icons.cancel),
                  label: const Text('Desactivar'),
                  onPressed: () => Navigator.pop(context, _AlertViewResult('deactivate')),
                ),
              if (!alert.active)
                TextButton.icon(
                  icon: const Icon(Icons.check_circle),
                  label: const Text('Reactivar'),
                  onPressed: () => Navigator.pop(context, _AlertViewResult('reactivate')),
                ),
              TextButton.icon(
                icon: const Icon(Icons.delete),
                label: const Text('Eliminar'),
                onPressed: () => Navigator.pop(context, _AlertViewResult('delete')),
              ),
              TextButton(
                child: const Text('Cerrar'),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
