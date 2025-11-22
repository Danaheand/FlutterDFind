import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/alert_data.dart';
import '../models/recordatorio.dart';
import '../models/recordatorio_exception.dart';
import '../providers/recordatorio_provider.dart';
import '../providers/font_size_provider.dart';
import '../services/session_manager.dart';
import '../services/trash_service.dart';
import '../models/trash_item.dart';
import '../utils/time_utils.dart';
import '../utils/alert_utils.dart';
import '../widgets/weekday_indicator.dart';
import '../theme/app_theme.dart';

/// Pantalla moderna de detalle de alerta con diseño tipo hero card
class AlertDetailScreenModern extends StatefulWidget {
  final AlertData alert;

  const AlertDetailScreenModern({super.key, required this.alert});

  @override
  State<AlertDetailScreenModern> createState() =>
      _AlertDetailScreenModernState();
}

class _AlertDetailScreenModernState extends State<AlertDetailScreenModern>
    with TickerProviderStateMixin {
  late AlertData data;
  bool isEditing = false;
  bool isCompleted = false;
  bool deleteConfirm = false;

  // Controladores para modo edición
  late TextEditingController titleController;
  late TextEditingController descriptionController;
  late TextEditingController locationController;
  late List<int> selectedWeekdays;
  late DateTime selectedDate;
  late AlertPriority selectedPriority;
  late Color? selectedColor;

  // ScrollController para manejo de scroll
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    data = widget.alert;
    titleController = TextEditingController(text: data.title);
    descriptionController = TextEditingController(text: data.description);
    locationController = TextEditingController(text: data.location ?? '');
    
    // Si es repetitiva y no hay días seleccionados, marcar todos por defecto
    if (data.repetitive && (data.selectedWeekdays == null || data.selectedWeekdays!.isEmpty)) {
      selectedWeekdays = [0, 1, 2, 3, 4, 5, 6]; // Marcar todos los días
    } else {
      selectedWeekdays = List<int>.from(data.selectedWeekdays ?? []);
    }
    
    selectedDate = data.date;
    selectedPriority = data.priority;
    selectedColor = data.color;

    // Debug: Imprimir datos de la alerta
    print('=== DEBUG ALERTA ===');
    print('Título: ${data.title}');
    print('Repetitiva: ${data.repetitive}');
    print('Frecuencia: ${data.repeatFrequency}');
    print('Días seleccionados: ${data.selectedWeekdays}');
    print('Prioridad: ${data.priority}');
    print('==================');
  }

  @override
  void dispose() {
    titleController.dispose();
    descriptionController.dispose();
    locationController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Color get _priorityColor {
    if (isCompleted) return const Color(0xFF86EFAC);
    if (!data.active) return Colors.grey.shade400;
    return data.color ?? defaultColorFor(selectedPriority);
  }

  Future<void> _saveChanges() async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      final provider = context.read<RecordatorioProvider>();
      final tituloOriginal = data.title;
      final userId = SessionManager.instance.userId ?? 0;

      final recordatorioActualizado = Recordatorio(
        idRecordatorio: data.id,
        idUsuario: userId,
        titulo: titleController.text.trim(),
        descripcion: descriptionController.text.trim(),
        fechaHora: selectedDate,
        prioridad: selectedPriority.name,
        ubicacion: locationController.text.trim().isNotEmpty
            ? locationController.text.trim()
            : null,
        objeto: data.object,
        esRepetitivo: data.repetitive,
        frecuenciaRepeticion: data.repeatFrequency,
        diasSeleccionados:
            selectedWeekdays.isNotEmpty ? selectedWeekdays.join(',') : null,
        color: selectedColor?.value.toString(),
      );

      await provider.actualizarRecordatorio(
        tituloOriginal,
        recordatorioActualizado,
      );

      if (mounted) {
        Navigator.pop(context); // Cerrar loading
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Cambios guardados exitosamente'),
            backgroundColor: AppTheme.primaryLight,
            duration: const Duration(seconds: 2),
          ),
        );

        // Actualizar los datos locales
        setState(() {
          data = AlertData(
            id: data.id,
            title: titleController.text.trim(),
            description: descriptionController.text.trim(),
            date: selectedDate,
            priority: selectedPriority,
            location: locationController.text.trim().isNotEmpty
                ? locationController.text.trim()
                : null,
            object: data.object,
            repetitive: data.repetitive,
            repeatFrequency: data.repeatFrequency,
            active: data.active,
            color: selectedColor,
            imagePath: data.imagePath,
            selectedWeekdays: selectedWeekdays,
            createdAt: data.createdAt,
            updatedAt: DateTime.now(),
          );
        });
        isEditing = false;
      }
    } on RecordatorioException catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.message}'),
            backgroundColor: const Color(0xFFEF4444),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error inesperado: $e'),
            backgroundColor: const Color(0xFFEF4444),
          ),
        );
      }
    }
  }

  void _toggleComplete() {
    setState(() {
      isCompleted = !isCompleted;
    });

    if (isCompleted) {
      _showCustomNotification('Completado', Icons.check_circle);
    } else {
      _showCustomNotification('Recordatorio activado', Icons.restore);
    }
  }

  void _showCustomNotification(String text, IconData icon) {
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
          bottom: 80,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(-1.0, 0.0),
              end: Offset.zero,
            ).animate(animation),
            child: FadeTransition(
              opacity: animation,
              child: Material(
                color: Colors.transparent,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    color: AppTheme.primaryLight,
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

    Future.delayed(const Duration(seconds: 2), () async {
      try {
        await controller.reverse();
      } catch (_) {}
      entry.remove();
      controller.dispose();
    });
  }

  Future<void> _deleteAlert() async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      final provider = context.read<RecordatorioProvider>();
      await provider.eliminarRecordatorio(data.title);

      // Guardar datos completos en papelera
      final alertDataMap = {
        'id': data.id,
        'title': data.title,
        'description': data.description,
        'date': data.date.toIso8601String(),
        'priority': data.priority.name,
        'location': data.location,
        'object': data.object,
        'repetitive': data.repetitive,
        'repeatFrequency': data.repeatFrequency,
        'active': data.active,
        'color': data.color?.value,
        'imagePath': data.imagePath,
        'selectedWeekdays': data.selectedWeekdays,
        'createdAt': data.createdAt?.toIso8601String(),
        'updatedAt': data.updatedAt?.toIso8601String(),
      };

      final trashItem = TrashItem(
        id: data.id,
        name: data.title,
        placeName: data.location ?? 'Sin ubicación',
        category: 'Alerta',
        deletedAt: DateTime.now(),
        originalType: 'alert',
        originalData: alertDataMap,
      );
      final trashService = TrashService.getInstance();
      await trashService.addToTrash(trashItem);

      if (mounted) {
        Navigator.pop(context); // Cerrar loading
        Navigator.pop(context); // Volver atrás
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('🗑️ Alerta eliminada'),
            backgroundColor: Color(0xFF64748B),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al eliminar: $e'),
            backgroundColor: const Color(0xFFEF4444),
          ),
        );
      }
    }
  }

  void _onWeekdayToggle(int dayIndex) {
    setState(() {
      if (selectedWeekdays.contains(dayIndex)) {
        selectedWeekdays.remove(dayIndex);
      } else {
        selectedWeekdays.add(dayIndex);
      }
      selectedWeekdays.sort();
    });
  }

  // Método para hacer scroll cuando se enfoca un campo de texto
  void _scrollToShowField() {
    Future.delayed(const Duration(milliseconds: 300), () {
      if (_scrollController.hasClients) {
        // Calculamos el scroll necesario para que el campo quede visible
        // Dejamos espacio de 200px desde el bottom para que no quede tapado por los botones
        final currentScroll = _scrollController.offset;
        final maxScroll = _scrollController.position.maxScrollExtent;

        // Calculamos un scroll que deje espacio suficiente (250px adicionales)
        final targetScroll = (currentScroll + 250).clamp(0.0, maxScroll);

        _scrollController.animateTo(
          targetScroll,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final timeInfo = TimeUtils.getRelativeTime(selectedDate);
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: Theme.of(context).brightness == Brightness.light
          ? Colors.white
          : AppTheme.backgroundDark,
      body: Stack(
        children: [
          // ===== CAPA 1: HERO BACKGROUND =====
          Container(
            height: screenHeight * 0.25,
            color: _priorityColor,
          ),

          // ===== CAPA 2: SCROLLABLE CONTENT =====
          SingleChildScrollView(
            controller: _scrollController,
            child: Column(
              children: [
                SizedBox(height: screenHeight * 0.17),

                // ===== FLOATING COUNTDOWN CARD (ahora dentro del scroll) =====
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 30),
                  child: GestureDetector(
                    onTap: isEditing ? _showDateTimePicker : null,
                    child: Card(
                      elevation: 8,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                        side: isEditing
                            ? BorderSide(
                                color: AppTheme.primaryLight, width: 3)
                            : BorderSide.none,
                      ),
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          color: isEditing
                              ? AppTheme.primaryLight.withOpacity(0.1)
                              : Theme.of(context).brightness == Brightness.light
                                  ? Colors.white
                                  : AppTheme.cardDark,
                        ),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                // Icon(
                                //   isEditing
                                //       ? Icons.edit_calendar_rounded
                                //       : Icons.calendar_today,
                                //   size: 16,
                                //   color: isEditing
                                //       ? const Color(0xFF3B82F6)
                                //       : Theme.of(context).brightness ==
                                //               Brightness.light
                                //           ? const Color(0xFF64748B)
                                //           : Colors.grey[400],
                                // ),
                                const SizedBox(width: 6),
                                Text(
                                  isCompleted
                                      ? 'LISTO'
                                      : (isEditing
                                          ? 'TOCA PARA EDITAR'
                                          : timeInfo['label']),
                                  style: TextStyle(
                                    fontSize: isEditing ? 13 : 12,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 1.2,
                                    color: isCompleted
                                        ? AppTheme.successLight
                                        : (isEditing
                                            ? AppTheme.primaryLight
                                            : Theme.of(context).brightness ==
                                                    Brightness.light
                                                ? const Color(0xFF64748B)
                                                : Colors.grey[400]),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Consumer<FontSizeProvider>(
                              builder: (context, fontSizeProvider, _) => Text(
                                isCompleted ? '✓' : timeInfo['timeText'],
                                style: TextStyle(
                                  fontSize: fontSizeProvider.getScaledSize(48),
                                  fontWeight: FontWeight.w900,
                                  color: isCompleted
                                      ? AppTheme.successLight
                                      : (isEditing
                                          ? const Color(0xFF3B82F6)
                                          : (Theme.of(context).brightness == Brightness.light
                                              ? Colors.black87
                                              : Colors.white)),
                                  height: 1.1,
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.access_time,
                                  size: 14,
                                  color: isEditing
                                      ? const Color(0xFF3B82F6)
                                      : Theme.of(context).brightness ==
                                              Brightness.light
                                          ? const Color(0xFF94A3B8)
                                          : Colors.grey[500],
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  timeInfo['formattedDate'],
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: isEditing
                                        ? const Color(0xFF3B82F6)
                                        : Theme.of(context).brightness ==
                                                Brightness.light
                                            ? const Color(0xFF64748B)
                                            : Colors.grey[400],
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 10),

                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Theme.of(context).brightness == Brightness.light
                        ? Colors.white
                        : AppTheme.backgroundDark,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(30),
                    ),
                  ),
                  padding: const EdgeInsets.fromLTRB(20, 30, 20, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // PRIORIDAD (arriba del título)
                      _buildPriority(),
                      const SizedBox(height: 12),

                      // SELECTOR DE COLOR (solo en modo edición)
                      if (isEditing) _buildColorSelector(),
                      if (isEditing) const SizedBox(height: 12),

                      // TÍTULO
                      _buildTitle(),
                      const SizedBox(height: 16),

                      // DESCRIPCIÓN (solo si existe o está editando)
                      if (data.description.isNotEmpty || isEditing)
                        _buildDescription(),
                      if (data.description.isNotEmpty || isEditing)
                        const SizedBox(height: 24),

                      // UBICACIÓN (solo si existe o está editando)
                      if ((data.location != null &&
                              data.location!.isNotEmpty) ||
                          isEditing)
                        _buildLocation(),
                      if ((data.location != null &&
                              data.location!.isNotEmpty) ||
                          isEditing)
                        const SizedBox(height: 24),

                      // DÍAS DE LA SEMANA (en lugar de frecuencia)
                      if (data.repetitive || isEditing) _buildWeekdays(),
                      if (data.repetitive || isEditing)
                        const SizedBox(height: 16),

                      // Espaciado inferior para botones
                      const SizedBox(height: 100),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ===== CAPA 3: GRADIENT OVERLAY =====
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: IgnorePointer(
              child: Container(
                height: 120,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: Theme.of(context).brightness == Brightness.light
                        ? [
                            Colors.white,
                            Colors.white.withOpacity(0.8),
                            Colors.white.withOpacity(0),
                          ]
                        : [
                            AppTheme.backgroundDark,
                            AppTheme.backgroundDark.withOpacity(0.8),
                            AppTheme.backgroundDark.withOpacity(0),
                          ],
                  ),
                ),
              ),
            ),
          ),

          // ===== CAPA 4: ACTION DOCK =====
          Positioned(
            bottom: 20,
            left: 20,
            right: 20,
            child: Row(
              children: [
                // Botón Eliminar
                _buildActionButton(
                  icon: deleteConfirm ? Icons.check : Icons.delete_outline,
                  color: const Color(0xFFEF4444),
                  onTap: () {
                    if (deleteConfirm) {
                      _deleteAlert();
                    } else {
                      setState(() {
                        deleteConfirm = true;
                      });
                      Future.delayed(const Duration(seconds: 3), () {
                        if (mounted) {
                          setState(() {
                            deleteConfirm = false;
                          });
                        }
                      });
                    }
                  },
                  label: deleteConfirm ? '¿Seguro?' : null,
                ),
                const SizedBox(width: 12),

                // Botón Central (Completar/Guardar)
                Expanded(
                  child: InkWell(
                    onTap: isEditing ? _saveChanges : _toggleComplete,
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      height: 56,
                      decoration: BoxDecoration(
                        color: AppTheme.successLight.withOpacity(0.2),
                        border: Border.all(
                          color: AppTheme.successLight,
                          width: 1.5,
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            isEditing
                                ? Icons.save
                                : (isCompleted
                                    ? Icons.check_circle
                                    : Icons.check_circle_outline),
                            color: AppTheme.successLight,
                            size: 24,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            isEditing
                                ? 'Guardar'
                                : (isCompleted ? 'Completado' : 'Completar'),
                            style: TextStyle(
                              color: AppTheme.successLight,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // Botón Editar
                _buildActionButton(
                  icon: isEditing ? Icons.close : Icons.edit_outlined,
                  color: AppTheme.primaryLight,
                  onTap: () {
                    setState(() {
                      if (isEditing) {
                        // Cancelar edición - restaurar valores
                        titleController.text = data.title;
                        descriptionController.text = data.description;
                        locationController.text = data.location ?? '';
                        selectedWeekdays =
                            List<int>.from(data.selectedWeekdays ?? []);
                        selectedDate = data.date;
                        selectedPriority = data.priority;
                        selectedColor = data.color;
                      }
                      isEditing = !isEditing;
                      deleteConfirm = false;
                    });
                  },
                ),
              ],
            ),
          ),

          // AppBar transparente
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
              title: Text(
                isCompleted ? 'COMPLETADA' : _getPriorityText().toUpperCase(),
                style: TextStyle(
                  color: isCompleted ? Colors.black87 : Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.5,
                ),
              ),
              centerTitle: true,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    String? label,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.3), width: 1),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 24),
            if (label != null)
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 8,
                    color: color,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTitle() {
    if (isEditing) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Título',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).brightness == Brightness.light
                  ? const Color(0xFF94A3B8)
                  : Colors.grey[500],
            ),
          ),
          const SizedBox(height: 8),
          Consumer<FontSizeProvider>(
            builder: (context, fontSizeProvider, _) => TextField(
              controller: titleController,
              onTap: _scrollToShowField,
              style: TextStyle(
                fontSize: fontSizeProvider.getScaledSize(24),
                fontWeight: FontWeight.bold,
                color: Theme.of(context).brightness == Brightness.light
                    ? const Color(0xFF1E293B)
                    : Colors.white,
              ),
              decoration: InputDecoration(
                hintText: 'Título de la alerta',
                hintStyle: TextStyle(
                  color: Theme.of(context).brightness == Brightness.light
                      ? Colors.grey[400]
                      : Colors.grey[600],
                ),
                filled: true,
                fillColor: Theme.of(context).brightness == Brightness.light
                    ? Colors.grey[50]
                    : AppTheme.cardDark,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                      color: Theme.of(context).brightness == Brightness.light
                          ? const Color(0xFFE2E8F0)
                          : Colors.grey[700]!),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                      color: Theme.of(context).brightness == Brightness.light
                          ? const Color(0xFFE2E8F0)
                          : Colors.grey[700]!),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                      color: Theme.of(context).brightness == Brightness.light
                          ? const Color(0xFF3B82F6)
                          : AppTheme.primaryDark,
                      width: 2),
                ),
                contentPadding: const EdgeInsets.all(16),
              ),
            ),
          ),
        ],
      );
    }

    return Consumer<FontSizeProvider>(
      builder: (context, fontSizeProvider, _) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Título',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).brightness == Brightness.light
                  ? const Color(0xFF94A3B8)
                  : Colors.grey[500],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            data.title,
            style: TextStyle(
              fontSize: fontSizeProvider.getScaledSize(24),
              fontWeight: FontWeight.bold,
              color: Theme.of(context).brightness == Brightness.light
                  ? const Color(0xFF1E293B)
                  : Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDescription() {
    if (isEditing) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Descripción',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).brightness == Brightness.light
                  ? const Color(0xFF94A3B8)
                  : Colors.grey[500],
            ),
          ),
          const SizedBox(height: 8),
          Consumer<FontSizeProvider>(
            builder: (context, fontSizeProvider, _) => TextField(
              controller: descriptionController,
              onTap: _scrollToShowField,
              maxLines: 3,
              style: TextStyle(
                fontSize: fontSizeProvider.getScaledSize(15),
                color: Theme.of(context).brightness == Brightness.light
                    ? const Color(0xFF475569)
                    : Colors.grey[300],
                height: 1.5,
              ),
              decoration: InputDecoration(
                hintText: 'Describe los detalles de tu alerta...',
                hintStyle: TextStyle(
                  color: Theme.of(context).brightness == Brightness.light
                      ? Colors.grey[400]
                      : Colors.grey[600],
                ),
                filled: true,
                fillColor: Theme.of(context).brightness == Brightness.light
                    ? Colors.grey[50]
                    : AppTheme.cardDark,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                      color: Theme.of(context).brightness == Brightness.light
                          ? const Color(0xFFE2E8F0)
                          : Colors.grey[700]!),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                      color: Theme.of(context).brightness == Brightness.light
                          ? const Color(0xFFE2E8F0)
                          : Colors.grey[700]!),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                      color: Theme.of(context).brightness == Brightness.light
                          ? const Color(0xFF3B82F6)
                          : AppTheme.primaryDark,
                      width: 2),
                ),
                contentPadding: const EdgeInsets.all(16),
              ),
            ),
          ),
        ],
      );
    }

    return Consumer<FontSizeProvider>(
      builder: (context, fontSizeProvider, _) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Descripción',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).brightness == Brightness.light
                  ? const Color(0xFF94A3B8)
                  : Colors.grey[500],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            data.description,
            style: TextStyle(
              fontSize: fontSizeProvider.getScaledSize(15),
              color: Theme.of(context).brightness == Brightness.light
                  ? const Color(0xFF475569)
                  : Colors.grey[300],
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocation() {
    if (isEditing) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Ubicación',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).brightness == Brightness.light
                  ? const Color(0xFF94A3B8)
                  : Colors.grey[500],
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: locationController,
            onTap: _scrollToShowField,
            style: TextStyle(
              fontSize: 15,
              color: Theme.of(context).brightness == Brightness.light
                  ? const Color(0xFF475569)
                  : Colors.grey[300],
            ),
            decoration: InputDecoration(
              hintText: 'Ej: Casa, Oficina, Gimnasio...',
              prefixIcon: Icon(
                Icons.location_on,
                color: Theme.of(context).brightness == Brightness.light
                    ? const Color(0xFF94A3B8)
                    : Colors.grey[500],
                size: 20,
              ),
              filled: true,
              fillColor: Theme.of(context).brightness == Brightness.light
                  ? Colors.grey[50]
                  : AppTheme.cardDark,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                    color: Theme.of(context).brightness == Brightness.light
                        ? const Color(0xFFE2E8F0)
                        : Colors.grey[700]!),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                    color: Theme.of(context).brightness == Brightness.light
                        ? const Color(0xFFE2E8F0)
                        : Colors.grey[700]!),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                    color: Theme.of(context).brightness == Brightness.light
                        ? AppTheme.primaryLight
                        : AppTheme.primaryDark,
                    width: 2),
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            ),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Ubicación',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).brightness == Brightness.light
                ? const Color(0xFF94A3B8)
                : Colors.grey[500],
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).brightness == Brightness.light
                ? Colors.grey[50]
                : AppTheme.cardDark,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(
                Icons.location_on,
                size: 20,
                color: Theme.of(context).brightness == Brightness.light
                    ? const Color(0xFF94A3B8)
                    : Colors.grey[500],
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  data.location ?? '',
                  style: TextStyle(
                    fontSize: 15,
                    color: Theme.of(context).brightness == Brightness.light
                        ? const Color(0xFF475569)
                        : Colors.grey[300],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _showDateTimePicker() async {
    final date = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
    );

    if (date != null && mounted) {
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(selectedDate),
      );

      if (time != null && mounted) {
        setState(() {
          selectedDate = DateTime(
            date.year,
            date.month,
            date.day,
            time.hour,
            time.minute,
          );
        });
      }
    }
  }

  Widget _buildWeekdays() {
    // En modo edición, siempre mostrar el switch para activar/desactivar repetición
    if (isEditing) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.repeat,
                  size: 16,
                  color: Theme.of(context).brightness == Brightness.light
                      ? const Color(0xFF94A3B8)
                      : Colors.grey[500]),
              const SizedBox(width: 6),
              Text(
                'Repetición',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).brightness == Brightness.light
                      ? const Color(0xFF94A3B8)
                      : Colors.grey[500],
                ),
              ),
              const Spacer(),
              Switch(
                value: data.repetitive,
                onChanged: (value) {
                  setState(() {
                    data = AlertData(
                      id: data.id,
                      title: data.title,
                      description: data.description,
                      date: data.date,
                      priority: data.priority,
                      location: data.location,
                      object: data.object,
                      repetitive: value,
                      repeatFrequency: value ? 'Semanal' : null,
                      active: data.active,
                      color: data.color,
                      imagePath: data.imagePath,
                      selectedWeekdays: data.selectedWeekdays,
                      createdAt: data.createdAt,
                      updatedAt: data.updatedAt,
                    );
                  });
                },
                activeColor: AppTheme.successLight,
                focusColor: AppTheme.successLight.withOpacity(0.5),
                trackColor: MaterialStateProperty.all(
                  AppTheme.primaryLight.withOpacity(0.1),
                ),
              ),
            ],
          ),
          if (data.repetitive) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                // Botón Marcar/Desmarcar Todos
                InkWell(
                  onTap: () {
                    setState(() {
                      if (selectedWeekdays.length == 7) {
                        selectedWeekdays = [];
                      } else {
                        selectedWeekdays = [0, 1, 2, 3, 4, 5, 6];
                      }
                    });
                  },
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: selectedWeekdays.length == 7
                          ? (Theme.of(context).brightness == Brightness.light
                              ? AppTheme.primaryLight
                              : AppTheme.primaryDark)
                          : (Theme.of(context).brightness == Brightness.light
                              ? AppTheme.primaryLight.withOpacity(0.1)
                              : AppTheme.primaryDark.withOpacity(0.2)),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Theme.of(context).brightness == Brightness.light
                            ? AppTheme.primaryLight.withOpacity(0.3)
                            : AppTheme.primaryDark.withOpacity(0.4),
                        width: 1.5,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          selectedWeekdays.length == 7
                              ? Icons.check_circle
                              : Icons.check_circle_outline,
                          size: 16,
                          color: selectedWeekdays.length == 7
                              ? Colors.white
                              : (Theme.of(context).brightness ==
                                      Brightness.light
                                  ? AppTheme.primaryLight
                                  : AppTheme.primaryDark),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          selectedWeekdays.length == 7
                              ? 'Desmarcar todos'
                              : 'Marcar todos',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: selectedWeekdays.length == 7
                                ? Colors.white
                                : (Theme.of(context).brightness ==
                                        Brightness.light
                                    ? AppTheme.primaryLight
                                    : AppTheme.primaryDark),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            WeekdayIndicator(
              selectedWeekdays: selectedWeekdays,
              isEditing: isEditing,
              onDayToggle: _onWeekdayToggle,
            ),
          ],
        ],
      );
    }

    // Modo normal - solo mostrar si es repetitiva
    if (data.repetitive) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.repeat,
                  size: 16,
                  color: Theme.of(context).brightness == Brightness.light
                      ? const Color(0xFF94A3B8)
                      : Colors.grey[500]),
              const SizedBox(width: 6),
              Text(
                'Frecuencia',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).brightness == Brightness.light
                      ? const Color(0xFF94A3B8)
                      : Colors.grey[500],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          WeekdayIndicator(
            selectedWeekdays: selectedWeekdays,
            isEditing: isEditing,
            onDayToggle: _onWeekdayToggle,
          ),
        ],
      );
    }

    // Si no es repetitiva y no está en edición, no mostrar nada
    return const SizedBox.shrink();
  }

  String _getPriorityText() {
    switch (selectedPriority) {
      case AlertPriority.alta:
        return 'Alta';
      case AlertPriority.media:
        return 'Media';
      case AlertPriority.baja:
        return 'Baja';
    }
  }

  Widget _buildPriority() {
    if (isEditing) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                '! Prioridad',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).brightness == Brightness.light
                      ? const Color(0xFF94A3B8)
                      : Colors.grey[500],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _buildPriorityChip(
                priority: AlertPriority.alta,
                label: 'Alta',
                color: const Color(0xFFEF4444),
              ),
              const SizedBox(width: 8),
              _buildPriorityChip(
                priority: AlertPriority.media,
                label: 'Media',
                color: const Color(0xFFF59E0B),
              ),
              const SizedBox(width: 8),
              _buildPriorityChip(
                priority: AlertPriority.baja,
                label: 'Baja',
                color: const Color(0xFF6A4C93),
              ),
            ],
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Prioridad',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).brightness == Brightness.light
                    ? const Color(0xFF94A3B8)
                    : Colors.grey[500],
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 6,
          ),
          decoration: BoxDecoration(
            color: _priorityColor.withOpacity(0.15),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: _priorityColor.withOpacity(0.3),
              width: 0.5,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${_getPriorityText()}',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: _priorityColor,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPriorityChip({
    required AlertPriority priority,
    required String label,
    required Color color,
  }) {
    final isSelected = selectedPriority == priority;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            selectedPriority = priority;
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? color : color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: color,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isSelected ? Colors.white : color,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildColorSelector() {
    // Colores disponibles para las alertas usando AppTheme
    final availableColors = [
      AppTheme.errorLight, // Rojo
      AppTheme.warningLight, // Naranja
      AppTheme.successLight, // Verde
      AppTheme.primaryLight, // Azul
      const Color(0xFF8B5CF6), // Púrpura
      const Color(0xFFEC4899), // Rosa
      const Color(0xFF06B6D4), // Cyan
      const Color(0xFF84CC16), // Lima
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Color',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).brightness == Brightness.light
                ? const Color(0xFF94A3B8)
                : Colors.grey[500],
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            // Botón para color predeterminado (basado en prioridad)
            GestureDetector(
              onTap: () {
                setState(() {
                  selectedColor = null;
                });
              },
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: selectedColor == null
                      ? defaultColorFor(selectedPriority)
                      : Colors.grey[300],
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: selectedColor == null
                        ? Colors.white
                        : Colors.grey[400]!,
                    width: selectedColor == null ? 3 : 1,
                  ),
                  boxShadow: selectedColor == null
                      ? [
                          BoxShadow(
                            color: defaultColorFor(selectedPriority)
                                .withOpacity(0.4),
                            blurRadius: 8,
                            spreadRadius: 2,
                          )
                        ]
                      : null,
                ),
                child: selectedColor == null
                    ? const Icon(
                        Icons.auto_awesome,
                        color: Colors.white,
                        size: 20,
                      )
                    : null,
              ),
            ),
            // Colores personalizados
            ...availableColors.map((color) {
              final isSelected = selectedColor == color;
              return GestureDetector(
                onTap: () {
                  setState(() {
                    selectedColor = color;
                  });
                },
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected ? Colors.white : Colors.transparent,
                      width: 3,
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: color.withOpacity(0.4),
                              blurRadius: 8,
                              spreadRadius: 2,
                            )
                          ]
                        : null,
                  ),
                  child: isSelected
                      ? const Icon(
                          Icons.check,
                          color: Colors.white,
                          size: 20,
                        )
                      : null,
                ),
              );
            }).toList(),
          ],
        ),
      ],
    );
  }
}
