import 'dart:math';
import 'package:Dfind/models/alert_data.dart';
import 'package:Dfind/screens/widgets/tips_recordatorios.dart';
import 'package:Dfind/utils/alert_utils.dart';
import 'package:Dfind/widgets/alert_card.dart';
import 'package:Dfind/widgets/alert_edit_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:provider/provider.dart';
import 'recordatorios_detalle_screen.dart' as detail;
import '../services/notification_service.dart';
import '../services/session_manager.dart';
import '../services/trash_service.dart';
import '../widgets/custom_text_button.dart';
import '../providers/recordatorio_provider.dart';
import '../models/recordatorio.dart';
import '../models/recordatorio_exception.dart';
import '../models/trash_item.dart';

class AlertsScreen extends StatefulWidget {
  const AlertsScreen({super.key});

  static DeleteAlertCallback? onAlertDeleted;

  @override
  State<AlertsScreen> createState() => _AlertsScreenState();
}

class _AlertsScreenState extends State<AlertsScreen> {
  Set<String> selectedAlerts = {};
  int tabIndex = 0;
  bool selectionMode = false;
  String? _userEmail;
  int? _userId;

  @override
  void initState() {
    super.initState();
    AlertsScreen.onAlertDeleted = _onAlertDeleted;
    _loadUserAndRecordatorios();
  }

  Future<void> _loadUserAndRecordatorios() async {
    try {
      // Obtener email del usuario desde SessionManager
      _userEmail = SessionManager.instance.userEmail;
      _userId = SessionManager.instance.userId;

      if (_userEmail != null && _userId != null && mounted) {
        // Cargar recordatorios del servidor
        final provider = context.read<RecordatorioProvider>();
        await provider.cargarRecordatorios();
      }
    } catch (e) {
      print('❌ Error cargando recordatorios: $e');
    }
  }

  void _onAlertDeleted(AlertData alert) {
    // Esta función se llama cuando se elimina un recordatorio desde el detalle
    if (_userEmail != null) {
      context.read<RecordatorioProvider>().eliminarRecordatorio(alert.title);
    }
  }

  @override
  void dispose() {
    AlertsScreen.onAlertDeleted = null;
    super.dispose();
  }

  // Convertir Recordatorio a AlertData para compatibilidad
  AlertData _recordatorioToAlertData(Recordatorio rec) {
    AlertPriority priority = AlertPriority.media;
    switch (rec.prioridad.toLowerCase()) {
      case 'alta':
        priority = AlertPriority.alta;
        break;
      case 'baja':
        priority = AlertPriority.baja;
        break;
      default:
        priority = AlertPriority.media;
    }

    Color? color;
    if (rec.color != null) {
      try {
        // Intentar parsear el color (ej: "#FF5733" o "0xFFFF5733")
        final colorStr = rec.color!.replaceAll('#', '');
        color = Color(int.parse(
                colorStr.startsWith('0x') ? colorStr.substring(2) : colorStr,
                radix: 16) |
            0xFF000000);
      } catch (e) {
        color = null;
      }
    }

    // Convertir diasSeleccionados string a List<int> si existe
    List<int>? weekdays;
    if (rec.diasSeleccionados != null && rec.diasSeleccionados!.isNotEmpty) {
      try {
        weekdays = rec.diasSeleccionados!
            .split(',')
            .map((s) => int.tryParse(s.trim()))
            .where((n) => n != null)
            .cast<int>()
            .toList();
      } catch (e) {
        weekdays = null;
      }
    }

    return AlertData(
      id: rec.idRecordatorio ?? rec.titulo.hashCode.toString(),
      title: rec.titulo,
      description: rec.descripcion,
      date: rec.fechaHora,
      priority: priority,
      location: rec.ubicacion,
      object: rec.objeto,
      repetitive: rec.esRepetitivo,
      repeatFrequency: rec.frecuenciaRepeticion,
      active: rec.activo,
      color: color ?? defaultColorFor(priority),
      selectedWeekdays: weekdays,
      imagePath: rec.rutaImagen,
      createdAt: rec.creadoEl,
      updatedAt: rec.actualizadoEl,
    );
  }

  List<AlertData> get _alerts {
    final provider = context.read<RecordatorioProvider>();
    return provider.recordatorios.map(_recordatorioToAlertData).toList();
  }

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

  Future<void> _toggleAlertActive(AlertData alert) async {
    if (_userEmail == null) return;

    try {
      final provider = context.read<RecordatorioProvider>();
      await provider.toggleActivoRecordatorio(alert.title);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(alert.active
                ? 'Recordatorio pausado'
                : 'Recordatorio activado'),
            duration: const Duration(seconds: 2),
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
    }
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
      builder: (_) => AlertEditDialog(
        alert: existing,
        userEmail: _userEmail,
      ),
      barrierDismissible: false,
    );
  }

  void _openAlertDialog() async {
    if (_userEmail == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No hay usuario autenticado'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final created = await _openEditor(context, null);
    if (created != null) {
      // Convertir AlertData a Recordatorio y crear en el servidor
      try {
        final provider = context.read<RecordatorioProvider>();

        // Convertir el color a formato hex string para guardarlo
        final colorHex = created.color != null
            ? '0x${created.color!.value.toRadixString(16).padLeft(8, '0')}'
            : null;
        print('🎨 Color convertido para guardar: $colorHex');

        final nuevoRecordatorio = Recordatorio(
          idUsuario: _userId!,
          titulo: created.title,
          descripcion: created.description,
          fechaHora: created.date,
          prioridad: created.priority.name,
          ubicacion: created.location,
          objeto: created.object,
          esRepetitivo: created.repetitive,
          frecuenciaRepeticion: created.repeatFrequency,
          diasSeleccionados: created.selectedWeekdays?.join(','),
          color: colorHex,
        );

        await provider.crearRecordatorio(nuevoRecordatorio);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Recordatorio creado exitosamente'),
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
      }
    }
  }

  void _deleteSelected() async {
    if (_userEmail == null || selectedAlerts.isEmpty) return;

    final provider = context.read<RecordatorioProvider>();
    final alertsToDelete =
        _alerts.where((a) => selectedAlerts.contains(a.id)).toList();

    // Confirmar eliminación
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar eliminación'),
        content: Text('¿Eliminar ${alertsToDelete.length} recordatorio(s)?'),
        actions: [
          CustomTextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          CustomTextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Eliminar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmar != true) return;

    try {
      final trashService = TrashService.getInstance();

      for (var alert in alertsToDelete) {
        // Enviar el recordatorio a la papelera
        final trashItem = TrashItem(
          id: alert.id,
          name: alert.title,
          placeName: alert.location ?? 'Sin ubicación',
          category: 'Recordatorio - ${alert.priority.name}',
          quantity: null,
          deletedAt: DateTime.now(),
          originalType: 'alert',
        );

        // Agregar a la papelera
        await trashService.addToTrash(trashItem);

        // Eliminar de la API
        await provider.eliminarRecordatorio(alert.title);
        AlertsScreen.onAlertDeleted?.call(alert);
      }

      setState(() {
        selectedAlerts.clear();
        selectionMode = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                '♻️ ${alertsToDelete.length} recordatorio(s) enviado(s) a la papelera'),
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
    }
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
          ...alerts
              .map((a) => AlertCard(
                    alert: a,
                    onLongPress: () {
                      print('🟢 onLongPress activado - Alerta: ${a.title}');
                      print('🟢 Estado actual - selectionMode: $selectionMode');
                      setState(() {
                        selectionMode = true;
                        selectedAlerts.add(a.id);
                        print(
                            '🟢 Nuevo estado - selectionMode: $selectionMode, selectedAlerts: $selectedAlerts');
                      });
                    },
                    onTap: () {
                      print(
                          '🔵 onTap - selectionMode: $selectionMode, showSelection: $showSelection');
                      print('🔵 Alert: ${a.title}');
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
                              alert: AlertData(
                                id: a.id,
                                title: a.title,
                                description: a.description,
                                date: a.date,
                                priority:
                                    AlertPriority.values[a.priority.index],
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
                    onDelete: () async {
                      try {
                        // Obtener el provider antes de hacer operaciones async
                        final provider = context.read<RecordatorioProvider>();
                        // final trashService = TrashService.getInstance();

                        // Crear TrashItem y agregar a papelera
                        // final trashItem = TrashItem(
                        //   id: a.id,
                        //   name: a.title,
                        //   placeName: a.location ?? 'Sin ubicación',
                        //   category: 'Recordatorio - ${a.priority.name}',
                        //   quantity: null,
                        //   deletedAt: DateTime.now(),
                        //   originalType: 'alert',
                        // );

                        // await trashService.addToTrash(trashItem);
                        await provider.eliminarRecordatorio(a.title);

                        // Eliminar de la lista actual
                        if (mounted) {
                          setState(() {
                            _alerts.removeWhere((alert) => alert.id == a.id);
                          });

                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('♻️ Recordatorio eliminado'),
                              backgroundColor: Colors.green,
                              duration: Duration(seconds: 2),
                            ),
                          );
                        }
                      } catch (e) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Error: $e'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      }
                    },
                    showCheckbox: showSelection && selectionMode,
                    checked: selectedAlerts.contains(a.id),
                  ))
              .toList()
              .map((card) {
            print(
                '🟡 _buildSection: showSelection=$showSelection, selectionMode=$selectionMode');
            return card;
          }),
          const SizedBox(height: 16),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.read<RecordatorioProvider>();

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Recordatorios'),
        actions: [
          if (_alerts.isNotEmpty)
            IconButton(
              icon: Icon(
                  selectionMode ? Icons.close : Icons.check_box_outline_blank),
              tooltip: selectionMode ? 'Cancelar selección' : 'Seleccionar',
              onPressed: () {
                print('🔴 Botón selección presionado');
                print('🔴 Estado antes - selectionMode: $selectionMode');
                setState(() {
                  selectionMode = !selectionMode;
                  if (!selectionMode) selectedAlerts.clear();
                  print('🔴 Estado después - selectionMode: $selectionMode');
                });
              },
            ),
        ],
      ),
      floatingActionButton: tabIndex == 0
          ? FloatingActionButton(
              onPressed: provider.isLoading ? null : () => _openAlertDialog(),
              tooltip: 'Añadir Alerta',
              child: const Icon(Icons.add_alert),
            )
          : null,
      body: provider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : provider.error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline,
                          size: 64, color: Colors.red),
                      const SizedBox(height: 16),
                      Text(
                        provider.error!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.red),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadUserAndRecordatorios,
                        child: const Text('Reintentar'),
                      ),
                    ],
                  ),
                )
              : _alerts.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.notifications_none,
                              size: 64, color: Colors.grey),
                          const SizedBox(height: 16),
                          const Text(
                            'No tienes recordatorios',
                            style: TextStyle(fontSize: 18, color: Colors.grey),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Presiona + para crear uno',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadUserAndRecordatorios,
                      child: tabIndex == 0
                          ? ListView(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              children: [
                                _buildTabBar(),
                                const TipsRecordatorios(),
                                _buildSection('Importantes', importantes,
                                    showSelection: true),
                                _buildSection('Actuales', proximas,
                                    showSelection: true),
                                _buildSection('Desactivadas', desactivadas,
                                    showSelection: true),
                              ],
                            )
                          : Stack(
                              children: [
                                ListView(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 8),
                                  children: [
                                    _buildTabBar(),
                                    _buildSection('Pasadas', pasadas,
                                        showSelection: true),
                                  ],
                                ),
                                if (selectionMode && selectedAlerts.isNotEmpty)
                                  Positioned(
                                    left: 0,
                                    right: 0,
                                    bottom: 0,
                                    child: Container(
                                      color:
                                          Theme.of(context).colorScheme.surface,
                                      padding: const EdgeInsets.all(12),
                                      child: ElevatedButton.icon(
                                        icon: const Icon(Icons.delete),
                                        label: const Text(
                                            'Eliminar Seleccionadas'),
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
                    ),
    );
  }
}
