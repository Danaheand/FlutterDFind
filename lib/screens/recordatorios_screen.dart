import 'package:Dfind/models/alert_data.dart';
import 'package:Dfind/screens/widgets/tips_recordatorios.dart';
import 'package:Dfind/utils/alert_utils.dart';
import 'package:Dfind/widgets/alert_card.dart';
import 'package:Dfind/widgets/alert_edit_dialog.dart';
import 'package:Dfind/widgets/alert_tab_bar.dart';
import 'package:Dfind/widgets/collapsible_section.dart';
import 'package:Dfind/widgets/tutorial_alert_card.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import "alert_detail_screen_modern.dart";
// import 'recordatorios_detalle_screen.dart' as detail;
import '../services/session_manager.dart';
import '../services/trash_service.dart';
import '../widgets/custom_text_button.dart';
import '../providers/recordatorio_provider.dart';
import '../providers/font_size_provider.dart';
import '../models/recordatorio.dart';
import '../models/recordatorio_exception.dart';
import '../models/trash_item.dart';
import '../theme/app_theme.dart';

class AlertsScreen extends StatefulWidget {
  const AlertsScreen({super.key});

  static DeleteAlertCallback? onAlertDeleted;

  @override
  State<AlertsScreen> createState() => _AlertsScreenState();
}

class _AlertsScreenState extends State<AlertsScreen>
    with TickerProviderStateMixin {
  Set<String> selectedAlerts = {};
  int tabIndex = 0;
  bool selectionMode = false;
  bool groupByPriority = false; // Toggle para agrupar por prioridad o por fecha
  Set<AlertPriority> selectedPriorities = {
    AlertPriority.alta,
    AlertPriority.media,
    AlertPriority.baja
  }; // Filtros de prioridad
  String? _userEmail;
  int? _userId;
  bool _showTutorial = false;
  AnimationController? _tutorialController;
  Animation<double>? _slideAnimation;

  @override
  void initState() {
    super.initState();
    AlertsScreen.onAlertDeleted = _onAlertDeleted;
    _loadUserAndRecordatorios();
    _checkAndShowTutorial();
  }

  Future<void> _loadUserAndRecordatorios() async {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        // Obtener email del usuario desde SessionManager
        _userEmail = SessionManager.instance.userEmail;
        _userId = SessionManager.instance.userId;

        if (_userEmail != null && _userId != null && mounted) {
          // Cargar recordatorios del servidor
          print('Cargando recordatorios para $_userEmail...');
          final provider = context.read<RecordatorioProvider>();
          await provider.cargarRecordatorios();
          print(' Recordatorios cargados para $_userEmail');
        }
      } catch (e) {
        print('Error cargando recordatorios: $e');
      }
    });
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
    _tutorialController?.dispose();
    super.dispose();
  }

  // ================================================================
  //           MENSAJES SUPER CUTE (CUADRO VERDE, OVERLAY)
  // ================================================================

  void _showCuteMessage(String text, IconData icon, {Color? backgroundColor}) {
    final overlay = Overlay.of(context);

    late OverlayEntry entry;
    final controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
    );
    final animation = CurvedAnimation(
      parent: controller,
      curve: Curves.easeOutBack,
      reverseCurve: Curves.easeIn,
    );

    entry = OverlayEntry(
      builder: (ctx) {
        return Positioned(
          left: 16,
          right: 16,
          bottom: 80, // un poco más arriba de abajo
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(-1.0, 0.0), // entra desde la izquierda
              end: Offset.zero,
            ).animate(animation),
            child: FadeTransition(
              opacity: animation,
              child: Material(
                color: Colors.transparent,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    color: backgroundColor ??
                        const Color.fromARGB(255, 98, 77, 129),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.15),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        icon,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          text,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );

    overlay.insert(entry);
    controller.forward();

    Future.delayed(const Duration(milliseconds: 2500), () async {
      try {
        await controller.reverse();
      } catch (_) {}
      entry.remove();
      controller.dispose();
    });
  }

  Future<void> _checkAndShowTutorial() async {
    print('Verificando si se debe mostrar tutorial de deslizamiento...');
    final prefs = await SharedPreferences.getInstance();
    final hasSeenTutorial = prefs.getBool('has_seen_swipe_tutorial') ?? false;
    print('suario ha visto tutorial antes: $hasSeenTutorial');

    if (!hasSeenTutorial) {
      // Esperar un momento para que se carguen las alertas
      await Future.delayed(const Duration(milliseconds: 1500));

      if (mounted) {
        _startTutorialAnimation();
        // Marcar como visto
        prefs.setBool('has_seen_swipe_tutorial', true);
      }
    }
  }

  void _startTutorialAnimation() {
    // Detener animación anterior si existe
    _tutorialController?.stop();
    _tutorialController?.dispose();

    setState(() {
      _showTutorial = true;
    });

    // Iniciar la animación
    _tutorialController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );

    _slideAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.0, end: 100.0)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 25.0,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 100.0, end: 0.0)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 25.0,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.0, end: -100.0)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 25.0,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: -100.0, end: 0.0)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 25.0,
      ),
    ]).animate(_tutorialController!);

    // Repetir la animación 2 veces
    _tutorialController!.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _tutorialController!.reset();
        if (_showTutorial) {
          _tutorialController!.forward();
        }
      }
    });

    _tutorialController!.forward();

    // Detener después de 2.5 segundos
    Future.delayed(const Duration(milliseconds: 2500), () {
      if (mounted) {
        setState(() {
          _showTutorial = false;
        });
        _tutorialController?.stop();
        _tutorialController?.dispose();
        _tutorialController = null;
      }
    });
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
      completed: !rec.activo, // Si no está activo, se considera completado
      color: color ?? defaultColorFor(priority),
      selectedWeekdays: weekdays,
      imagePath: rec.rutaImagen,
      createdAt: rec.creadoEl,
      updatedAt: rec.actualizadoEl,
    );
  }

  List<AlertData> _getAlerts(RecordatorioProvider provider) {
    print(' Obteniendo recordatorios desde el provider...');
    final recordatorios =
        provider.recordatorios.map(_recordatorioToAlertData).toList();
    print(' Total recordatorios cargados: ${recordatorios.length}');
    return recordatorios;
  }

  List<AlertData> _getHoy(List<AlertData> alerts) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));

    return alerts
        .where((a) =>
            a.active &&
            a.date.isAfter(now) &&
            a.date.isBefore(tomorrow) &&
            selectedPriorities.contains(a.priority))
        .toList()
      ..sort(
          (a, b) => a.date.compareTo(b.date)); // Ordenar solo por fecha y hora
  }

  List<AlertData> _getManana(List<AlertData> alerts) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    final dayAfterTomorrow = tomorrow.add(const Duration(days: 1));

    return alerts
        .where((a) =>
            a.active &&
            a.date.isAfter(tomorrow) &&
            a.date.isBefore(dayAfterTomorrow) &&
            selectedPriorities.contains(a.priority))
        .toList()
      ..sort(
          (a, b) => a.date.compareTo(b.date)); // Ordenar solo por fecha y hora
  }

  List<AlertData> _getProximas(List<AlertData> alerts) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dayAfterTomorrow = today.add(const Duration(days: 2));

    return alerts
        .where((a) =>
            a.active &&
            a.date.isAfter(dayAfterTomorrow) &&
            selectedPriorities.contains(a.priority))
        .toList()
      ..sort(
          (a, b) => a.date.compareTo(b.date)); // Ordenar solo por fecha y hora
  }

  List<AlertData> _getVencidas(List<AlertData> alerts) {
    final now = DateTime.now();
    return alerts
        .where((a) =>
            a.active &&
            a.date.isBefore(now) &&
            selectedPriorities.contains(a.priority))
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date)); // Más recientes primero
  }

  List<AlertData> _getPasadas(List<AlertData> alerts) {
    return alerts.where((a) => !a.active).toList()
      ..sort((a, b) => b.date.compareTo(a.date)); // Más recientes primero
  }

  // Funciones para agrupar por prioridad
  List<AlertData> _getAlta(List<AlertData> alerts) {
    return alerts
        .where((a) => a.active && a.priority == AlertPriority.alta)
        .toList()
      ..sort((a, b) => a.date.compareTo(b.date)); // Ordenar por fecha
  }

  List<AlertData> _getMedia(List<AlertData> alerts) {
    return alerts
        .where((a) => a.active && a.priority == AlertPriority.media)
        .toList()
      ..sort((a, b) => a.date.compareTo(b.date)); // Ordenar por fecha
  }

  List<AlertData> _getBaja(List<AlertData> alerts) {
    return alerts
        .where((a) => a.active && a.priority == AlertPriority.baja)
        .toList()
      ..sort((a, b) => a.date.compareTo(b.date)); // Ordenar por fecha
  }

  Widget _buildPriorityFilters() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.grey.shade900 : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Consumer<FontSizeProvider>(
            builder: (context, fontSizeProvider, _) => Text(
              'Prioridad:',
              style: TextStyle(
                fontSize: fontSizeProvider.fontSize,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).brightness == Brightness.light
                    ? Colors.grey.shade700
                    : Colors.grey.shade300,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildPriorityChip(
                label: 'Todas',
                isSelected: selectedPriorities.length == 3,
                color: Theme.of(context).brightness == Brightness.light
                    ? const Color(0xFF6A4C93)
                    : const Color(0xFF9D84B7),
                onTap: () {
                  setState(() {
                    selectedPriorities = {
                      AlertPriority.alta,
                      AlertPriority.media,
                      AlertPriority.baja
                    };
                  });
                },
              ),
              _buildPriorityChip(
                label: 'Alta',
                isSelected: selectedPriorities.contains(AlertPriority.alta) &&
                    selectedPriorities.length == 1,
                color: Theme.of(context).brightness == Brightness.light
                    ? Colors.red.shade400
                    : Colors.red.shade300,
                onTap: () {
                  setState(() {
                    selectedPriorities = {AlertPriority.alta};
                  });
                },
              ),
              _buildPriorityChip(
                label: 'Media',
                isSelected: selectedPriorities.contains(AlertPriority.media) &&
                    selectedPriorities.length == 1,
                color: Theme.of(context).brightness == Brightness.light
                    ? Colors.orange.shade400
                    : Colors.orange.shade300,
                onTap: () {
                  setState(() {
                    selectedPriorities = {AlertPriority.media};
                  });
                },
              ),
              _buildPriorityChip(
                label: 'Baja',
                isSelected: selectedPriorities.contains(AlertPriority.baja) &&
                    selectedPriorities.length == 1,
                color: Theme.of(context).brightness == Brightness.light
                    ? const Color(0xFFD4C5E2)
                    : const Color(0xFF8B7AA2),
                onTap: () {
                  setState(() {
                    selectedPriorities = {AlertPriority.baja};
                  });
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPriorityChip({
    required String label,
    required bool isSelected,
    required Color color,
    required VoidCallback onTap,
  }) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? color
              : (isDarkMode ? Colors.grey.shade700 : Colors.grey.shade200),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? color
                : (isDarkMode ? Colors.grey.shade600 : Colors.grey.shade300),
            width: 2,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: color.withOpacity(0.4),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon(
            //   isSelected ? Icons.check_circle : Icons.circle_outlined,
            //   size: 18,
            //   color: isSelected
            //       ? Colors.white
            //       : (isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600),
            // ),
            // const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isSelected
                    ? Colors.white
                    : (isDarkMode
                        ? Colors.grey.shade200
                        : Colors.grey.shade700),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Verifica si se pueden completar las alertas seleccionadas
  /// No se pueden completar alertas desactivadas o pasadas
  bool _canCompleteSelection() {
    if (selectedAlerts.isEmpty) return false;

    final provider = context.read<RecordatorioProvider>();
    final alerts = _getAlerts(provider);
    final selectedAlertsList =
        alerts.where((a) => selectedAlerts.contains(a.id)).toList();

    // Verificar que ninguna alerta seleccionada esté desactivada o sea pasada
    return selectedAlertsList
        .every((a) => a.active && a.date.isAfter(DateTime.now()));
  }

  Future<void> _toggleAlertActive(AlertData alert) async {
    if (_userEmail == null) return;

    try {
      final provider = context.read<RecordatorioProvider>();
      await provider.toggleActivoRecordatorio(alert.title);

      if (mounted) {
        _showCuteMessage(
          alert.active ? 'Recordatorio completado' : 'Recordatorio activado',
          alert.active ? Icons.pause_circle_rounded : Icons.play_circle_rounded,
          backgroundColor:
              alert.active ? Colors.orange.shade600 : AppTheme.primaryLight,
        );
      }
    } on RecordatorioException catch (e) {
      if (mounted) {
        _showCuteMessage(
          'Error: ${e.message}',
          Icons.error_rounded,
          backgroundColor: Colors.red.shade600,
        );
      }
    }
  }

  Future<void> _completeSelected() async {
    if (_userEmail == null || selectedAlerts.isEmpty) return;

    final provider = context.read<RecordatorioProvider>();
    final alerts = _getAlerts(provider);
    final alertsToComplete =
        alerts.where((a) => selectedAlerts.contains(a.id)).toList();

    // Validar que no se intenten completar alertas desactivadas o pasadas
    final alertasInvalidas = alertsToComplete.where((a) {
      return !a.active || a.date.isBefore(DateTime.now());
    }).toList();

    if (alertasInvalidas.isNotEmpty) {
      if (mounted) {
        _showCuteMessage(
          'No se pueden completar alertas desactivadas o pasadas (${alertasInvalidas.length})',
          Icons.warning_rounded,
          backgroundColor: Colors.orange.shade600,
        );
      }
      return;
    }

    // Confirmar completado
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar completado'),
        content: Text(
            '¿Marcar como completadas ${alertsToComplete.length} recordatorio(s)?'),
        actions: [
          CustomTextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          CustomTextButton(
            onPressed: () => Navigator.pop(context, true),
            child:
                const Text('Completar', style: TextStyle(color: Colors.green)),
          ),
        ],
      ),
    );

    if (confirmar != true) return;

    try {
      for (var alert in alertsToComplete) {
        // Guardar datos completos del AlertData en la papelera
        // final alertDataMap = {
        //   'id': alert.id,
        //   'title': alert.title,
        //   'description': alert.description,
        //   'date': alert.date.toIso8601String(),
        //   'priority': alert.priority.name,
        //   'location': alert.location,
        //   'object': alert.object,
        //   'repetitive': alert.repetitive,
        //   'repeatFrequency': alert.repeatFrequency,
        //   'active': alert.active,
        //   'color': alert.color?.value,
        //   'imagePath': alert.imagePath,
        //   'selectedWeekdays': alert.selectedWeekdays,
        //   'createdAt': alert.createdAt?.toIso8601String(),
        //   'updatedAt': alert.updatedAt?.toIso8601String(),
        //   'completed': true, // Marcar como completado
        // };

        // Completar en la API
        await provider.toggleActivoRecordatorio(alert.title);
        AlertsScreen.onAlertDeleted?.call(alert);
      }

      setState(() {
        selectedAlerts.clear();
        selectionMode = false;
      });

      if (mounted) {
        _showCuteMessage(
          '${alertsToComplete.length} recordatorio(s) completado(s)',
          Icons.check_circle_rounded,
        );
      }
    } on RecordatorioException catch (e) {
      if (mounted) {
        _showCuteMessage(
          'Error: ${e.message}',
          Icons.error_rounded,
          backgroundColor: Colors.red.shade600,
        );
      }
    }
  }

  Widget _buildAlertCard(AlertData a, bool showSelection,
      {bool isFirst = false}) {
    // Detectar si es la primera tarjeta del tutorial
    final isFirstCard = isFirst && _showTutorial && _slideAnimation != null;

    final alertCard = AlertCard(
      alert: a,
      onLongPress: () {
        print('onLongPress activado - Alerta: ${a.title}');
        print('Estado actual - selectionMode: $selectionMode');
        setState(() {
          selectionMode = true;
          selectedAlerts.add(a.id);
          print(
              ' Nuevo estado - selectionMode: $selectionMode, selectedAlerts: $selectedAlerts');
        });
      },
      onTap: () {
        print(
            'onTap - selectionMode: $selectionMode, showSelection: $showSelection');
        print('Alert: ${a.title}');
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
              builder: (context) => AlertDetailScreenModern(
                alert: AlertData(
                  id: a.id,
                  title: a.title,
                  description: a.description,
                  date: a.date,
                  priority: AlertPriority.values[a.priority.index],
                  location: a.location,
                  object: a.object,
                  repetitive: a.repetitive,
                  repeatFrequency: a.repeatFrequency,
                  active: a.active,
                  completed: a.completed,
                  color: a.color,
                  imagePath: a.imagePath,
                  selectedWeekdays: a.selectedWeekdays,
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
          final trashService = TrashService.getInstance();

          // Crear item de papelera
          final trashItem = TrashItem(
            id: a.id,
            name: a.title,
            placeName: a.location ?? 'Sin ubicación',
            category: 'Recordatorio - ${a.priority.name}',
            quantity: null,
            deletedAt: DateTime.now(),
            originalType: 'alert',
          );

          // Agregar a la papelera
          await trashService.addToTrash(trashItem);

          // Eliminar de la API
          await provider.eliminarRecordatorio(a.title);

          // El provider ya actualizó su lista
          if (mounted) {
            _showCuteMessage(
              'Recordatorio enviado a la papelera',
              Icons.delete_rounded,
            );
          }
        } catch (e) {
          if (mounted) {
            _showCuteMessage(
              'Error: $e',
              Icons.error_rounded,
              backgroundColor: Colors.red.shade600,
            );
          }
        }
      },
      showCheckbox: showSelection && selectionMode,
      checked: selectedAlerts.contains(a.id),
    );

    // Aplicar animación solo si está el tutorial activo
    if (isFirstCard) {
      return AbsorbPointer(
        absorbing: _showTutorial,
        child: Stack(
          children: [
            // Mostrar el fondo de completar cuando desliza a la derecha
            AnimatedBuilder(
              animation: _slideAnimation!,
              builder: (context, child) {
                if (_slideAnimation!.value <= 0) {
                  return const SizedBox.shrink();
                }
                return Positioned.fill(
                  child: Container(
                    margin: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
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
                        Icon(
                          a.active
                              ? Icons.pause_circle_filled
                              : Icons.check_circle,
                          color: Colors.white,
                          size: 36,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          a.active ? 'Completar' : 'Activar',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            // Mostrar el fondo de eliminar cuando desliza a la izquierda
            AnimatedBuilder(
              animation: _slideAnimation!,
              builder: (context, child) {
                if (_slideAnimation!.value >= 0) {
                  return const SizedBox.shrink();
                }
                return Positioned.fill(
                  child: Container(
                    margin: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
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
                        const Icon(
                          Icons.delete_forever,
                          color: Colors.white,
                          size: 36,
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Eliminar',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            // La tarjeta encima con la animación de deslizamiento
            AnimatedBuilder(
              animation: _slideAnimation!,
              builder: (context, child) {
                return Transform.translate(
                  offset: Offset(_slideAnimation!.value, 0),
                  child: child,
                );
              },
              child: alertCard,
            ),
          ],
        ),
      );
    }

    return alertCard;
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
      _showCuteMessage(
        'No hay usuario autenticado',
        Icons.warning_rounded,
        backgroundColor: Colors.orange.shade600,
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
          _showCuteMessage(
            'Recordatorio creado exitosamente',
            Icons.add_alert_rounded,
          );
        }
      } on RecordatorioException catch (e) {
        if (mounted) {
          _showCuteMessage(
            'Error: ${e.message}',
            Icons.error_rounded,
            backgroundColor: Colors.red.shade600,
          );
        }
      }
    }
  }

  void _deleteSelected() async {
    if (_userEmail == null || selectedAlerts.isEmpty) return;

    final provider = context.read<RecordatorioProvider>();
    final alerts = _getAlerts(provider);
    final alertsToDelete =
        alerts.where((a) => selectedAlerts.contains(a.id)).toList();

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
        // Guardar datos completos del AlertData para poder restaurarlo
        final alertDataMap = {
          'id': alert.id,
          'title': alert.title,
          'description': alert.description,
          'date': alert.date.toIso8601String(),
          'priority': alert.priority.name,
          'location': alert.location,
          'object': alert.object,
          'repetitive': alert.repetitive,
          'repeatFrequency': alert.repeatFrequency,
          'active': alert.active,
          'color': alert.color?.value,
          'imagePath': alert.imagePath,
          'selectedWeekdays': alert.selectedWeekdays,
          'createdAt': alert.createdAt?.toIso8601String(),
          'updatedAt': alert.updatedAt?.toIso8601String(),
        };

        // Enviar el recordatorio a la papelera con datos completos
        final trashItem = TrashItem(
          id: alert.id,
          name: alert.title,
          placeName: alert.location ?? 'Sin ubicación',
          category: 'Recordatorio - ${alert.priority.name}',
          quantity: null,
          deletedAt: DateTime.now(),
          originalType: 'alert',
          originalData: alertDataMap,
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
        _showCuteMessage(
          '${alertsToDelete.length} recordatorio(s) enviado(s) a la papelera',
          Icons.delete_rounded,
        );
      }
    } on RecordatorioException catch (e) {
      if (mounted) {
        _showCuteMessage(
          'Error: ${e.message}',
          Icons.error_rounded,
          backgroundColor: Colors.red.shade600,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<RecordatorioProvider>();

    // Calcular las listas de alertas una sola vez al inicio del build
    final alerts = _getAlerts(provider);
    final vencidas = _getVencidas(alerts);

    // Agrupar por fecha o por prioridad según el toggle
    final hoy = groupByPriority ? null : _getHoy(alerts);
    final manana = groupByPriority ? null : _getManana(alerts);
    final proximas = groupByPriority ? null : _getProximas(alerts);

    final alta = groupByPriority ? _getAlta(alerts) : null;
    final media = groupByPriority ? _getMedia(alerts) : null;
    final baja = groupByPriority ? _getBaja(alerts) : null;

    final pasadas = _getPasadas(alerts);

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Recordatorios'),
        actions: [
          // Botón para mostrar tutorial de deslizamiento
          // if (alerts.isNotEmpty && hoy.isNotEmpty)
          IconButton(
            icon: const Icon(Icons.help_outline),
            tooltip: 'Ver tutorial de deslizamiento',
            onPressed: () {
              if (!_showTutorial) {
                _startTutorialAnimation();
              }
            },
          ),
          if (alerts.isNotEmpty)
            IconButton(
              icon: Icon(
                  selectionMode ? Icons.close : Icons.check_box_outline_blank),
              tooltip: selectionMode ? 'Cancelar selección' : 'Seleccionar',
              onPressed: () {
                print(' Botón selección presionado');
                print(' Estado antes - selectionMode: $selectionMode');
                setState(() {
                  selectionMode = !selectionMode;
                  if (!selectionMode) selectedAlerts.clear();
                  print('Estado después - selectionMode: $selectionMode');
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
                      Icon(Icons.error_outline,
                          size: 64,
                          color:
                              Theme.of(context).brightness == Brightness.light
                                  ? Colors.red
                                  : AppTheme.errorDark),
                      const SizedBox(height: 16),
                      Text(
                        provider.error!,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            color:
                                Theme.of(context).brightness == Brightness.light
                                    ? Colors.red
                                    : AppTheme.errorDark),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadUserAndRecordatorios,
                        child: const Text('Reintentar'),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadUserAndRecordatorios,
                  child: Stack(
                    children: [
                      tabIndex == 0
                          ? ListView(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              children: [
                                AlertTabBar(
                                  tabIndex: tabIndex,
                                  onTabChanged: (index) =>
                                      setState(() => tabIndex = index),
                                  groupByPriority: groupByPriority,
                                  onGroupByPriorityChanged: (value) {
                                    setState(() {
                                      groupByPriority = value;
                                    });
                                  },
                                ),
                                const TipsRecordatorios(),
                                // Filtros de prioridad (solo en modo fecha)
                                if (!groupByPriority) _buildPriorityFilters(),
                                if (alerts.isEmpty)
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 16, vertical: 32),
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.notifications_none,
                                            size: 64,
                                            color: AppTheme.getTextSecondary(
                                                context)),
                                        const SizedBox(height: 16),
                                        Text(
                                          'No tienes recordatorios',
                                          style: TextStyle(
                                              fontSize: 18,
                                              color: AppTheme.getTextSecondary(
                                                  context)),
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          'Presiona + para crear uno',
                                          style: TextStyle(
                                              color: AppTheme.getTextSecondary(
                                                  context)),
                                        ),
                                      ],
                                    ),
                                  )
                                else if (_showTutorial &&
                                    _slideAnimation != null)
                                  Column(
                                    children: [
                                      TutorialAlertCard(
                                        slideAnimation: _slideAnimation,
                                      ),
                                      const SizedBox(height: 16),
                                    ],
                                  )
                                else ...[
                                  // Banner de vencidas (si hay)
                                  if (vencidas.isNotEmpty)
                                    ExpiredAlertsBanner(
                                      expiredAlerts: vencidas,
                                      children:
                                          vencidas.asMap().entries.map((entry) {
                                        return _buildAlertCard(
                                            entry.value, true,
                                            isFirst: entry.key == 0);
                                      }).toList(),
                                    ),
                                  // Secciones colapsables - Agrupación por fecha o por prioridad
                                  if (!groupByPriority) ...[
                                    // Agrupación por fecha
                                    if (hoy != null)
                                      CollapsibleSection(
                                        title: 'Hoy',
                                        count: hoy.length,
                                        icon: Icons.today,
                                        children:
                                            hoy.asMap().entries.map((entry) {
                                          return _buildAlertCard(
                                              entry.value, true,
                                              isFirst: entry.key == 0 &&
                                                  vencidas.isEmpty);
                                        }).toList(),
                                      ),
                                    if (manana != null)
                                      CollapsibleSection(
                                        title: 'Mañana',
                                        count: manana.length,
                                        icon: Icons.wb_sunny_outlined,
                                        headerColor: Colors.amber.shade50,
                                        children: manana.map((a) {
                                          return _buildAlertCard(a, true);
                                        }).toList(),
                                      ),
                                    if (proximas != null)
                                      CollapsibleSection(
                                        title: 'Próximos',
                                        count: proximas.length,
                                        icon: Icons.calendar_month,
                                        children: proximas.map((a) {
                                          return _buildAlertCard(a, true);
                                        }).toList(),
                                      ),
                                  ] else ...[
                                    // Agrupación por prioridad
                                    if (alta != null && alta.isNotEmpty)
                                      CollapsibleSection(
                                        title: 'Prioridad Alta',
                                        count: alta.length,
                                        icon: Icons.priority_high,
                                        headerColor: Colors.red.shade50,
                                        children:
                                            alta.asMap().entries.map((entry) {
                                          return _buildAlertCard(
                                              entry.value, true,
                                              isFirst: entry.key == 0 &&
                                                  vencidas.isEmpty);
                                        }).toList(),
                                      ),
                                    if (media != null && media.isNotEmpty)
                                      CollapsibleSection(
                                        title: 'Prioridad Media',
                                        count: media.length,
                                        icon: Icons.remove,
                                        headerColor: Colors.orange.shade50,
                                        children: media.map((a) {
                                          return _buildAlertCard(a, true);
                                        }).toList(),
                                      ),
                                    if (baja != null && baja.isNotEmpty)
                                      CollapsibleSection(
                                        title: 'Prioridad Baja',
                                        count: baja.length,
                                        icon: Icons.low_priority,
                                        headerColor: Colors.green.shade50,
                                        children: baja.map((a) {
                                          return _buildAlertCard(a, true);
                                        }).toList(),
                                      ),
                                  ],
                                ],
                                if (selectionMode && selectedAlerts.isNotEmpty)
                                  const SizedBox(height: 80),
                              ],
                            )
                          : ListView(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              children: [
                                AlertTabBar(
                                  tabIndex: tabIndex,
                                  onTabChanged: (index) =>
                                      setState(() => tabIndex = index),
                                  groupByPriority: groupByPriority,
                                  onGroupByPriorityChanged: (value) {
                                    setState(() {
                                      groupByPriority = value;
                                    });
                                  },
                                ),
                                const TipsRecordatorios(),
                                if (pasadas.isNotEmpty)
                                  CollapsibleSection(
                                    title: 'Historial',
                                    count: pasadas.length,
                                    icon: Icons.history,
                                    headerColor: Colors.grey.shade200,
                                    children: pasadas.map((a) {
                                      return _buildAlertCard(a, true);
                                    }).toList(),
                                  )
                                else
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 16, vertical: 32),
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.check_circle_outline,
                                            size: 64,
                                            color: AppTheme.getTextSecondary(
                                                context)),
                                        const SizedBox(height: 16),
                                        Text(
                                          'No hay alertas en el historial',
                                          style: TextStyle(
                                              fontSize: 18,
                                              color: AppTheme.getTextSecondary(
                                                  context)),
                                        ),
                                      ],
                                    ),
                                  ),
                                if (selectionMode && selectedAlerts.isNotEmpty)
                                  const SizedBox(height: 80),
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
                            child: tabIndex == 0
                                ? Row(
                                    children: [
                                      Expanded(
                                        child: ElevatedButton.icon(
                                          icon: const Icon(Icons.check_circle),
                                          label: const Text('Completar'),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor:
                                                _canCompleteSelection()
                                                    ? Colors.green
                                                    : Colors.grey,
                                            foregroundColor: Colors.white,
                                          ),
                                          onPressed: _canCompleteSelection()
                                              ? _completeSelected
                                              : null,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: ElevatedButton.icon(
                                          icon: const Icon(Icons.delete),
                                          label: const Text('Eliminar'),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.red,
                                            foregroundColor: Colors.white,
                                          ),
                                          onPressed: _deleteSelected,
                                        ),
                                      ),
                                    ],
                                  )
                                : ElevatedButton.icon(
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
                ),
    );
  }
}
