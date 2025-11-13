import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../providers/font_size_provider.dart';
import '../theme/app_theme.dart';

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

  IconData _getPriorityIcon() {
    switch (alert.priority) {
      case AlertPriority.alta:
        return Icons.warning_amber_rounded;
      case AlertPriority.media:
        return Icons.notifications_active_rounded;
      case AlertPriority.baja:
        return Icons.check_circle_rounded;
    }
  }

  Color get _color {
    if (!alert.active) return Colors.grey.shade400;
    return alert.color ?? _defaultColorFor(alert.priority);
  }

  String _formatDate(DateTime date) {
    final months = [
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
    return '${date.day} de ${months[date.month - 1]} ${date.year}';
  }

  String _formatTime(DateTime date) {
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
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
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    child: Text(
                      '${editDate.day.toString().padLeft(2, '0')}/${editDate.month.toString().padLeft(2, '0')}/${editDate.year}',
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<AlertPriority>(
                  initialValue: editPriority,
                  decoration: const InputDecoration(
                    labelText: 'Prioridad',
                    prefixIcon: Icon(Icons.priority_high_rounded),
                  ),
                  items: const [
                    DropdownMenuItem(value: AlertPriority.baja, child: Text('Baja')),
                    DropdownMenuItem(value: AlertPriority.media, child: Text('Media')),
                    DropdownMenuItem(value: AlertPriority.alta, child: Text('Alta')),
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
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => Navigator.pop(context),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: const Text(
                    'Cancelar',
                    style: TextStyle(
                      color: Colors.blue,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ),
            ElevatedButton.icon(
              onPressed: () {
                setState(() {
                  alert = AlertData(
                    id: alert.id,
                    title: titleCtrl.text.trim(),
                    description: descCtrl.text.trim(),
                    date: editDate,
                    priority: editPriority,
                    location: locationCtrl.text.trim().isEmpty ? null : locationCtrl.text.trim(),
                    object: objectCtrl.text.trim().isEmpty ? null : objectCtrl.text.trim(),
                    repetitive: alert.repetitive,
                    repeatFrequency: alert.repeatFrequency,
                    active: alert.active,
                    color: editColor,
                    imagePath: alert.imagePath,
                  );
                });
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Recordatorio actualizado')),
                );
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
      return 'En ${difference.inDays} día${difference.inDays > 1 ? 's' : ''} y ${difference.inHours % 24} hora${difference.inHours % 24 != 1 ? 's' : ''}';
    } else if (difference.inHours > 0) {
      return 'En ${difference.inHours} hora${difference.inHours > 1 ? 's' : ''}';
    } else {
      return 'En ${difference.inMinutes} minuto${difference.inMinutes > 1 ? 's' : ''}';
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isLight = Theme.of(context).brightness == Brightness.light;
    final now = DateTime.now();
    final isPast = alert.date.isBefore(now);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalle del Recordatorio'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              _showEditDialog();
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header con color de prioridad
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    _color,
                    _color.withOpacity(0.8),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: _color.withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.25),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.3),
                            width: 2,
                          ),
                        ),
                        child: Icon(
                          _getPriorityIcon(),
                          color: Colors.white,
                          size: 36,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Consumer<FontSizeProvider>(
                              builder: (context, fontSizeProvider, _) => Text(
                                alert.title,
                                style: TextStyle(
                                  fontSize: fontSizeProvider.fontSize + 6,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  height: 1.2,
                                  shadows: [
                                    Shadow(
                                      color: Colors.black.withOpacity(0.2),
                                      offset: const Offset(0, 2),
                                      blurRadius: 4,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.25),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.3),
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    _getPriorityIcon(),
                                    color: Colors.white,
                                    size: 14,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Prioridad ${_getPriorityText()}',
                                    style: const TextStyle(
                                      fontSize: 13,
                                      color: Colors.white,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Tiempo restante o vencido
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isPast
                      ? (isLight
                          ? [
                              AppTheme.errorLight.withOpacity(0.1),
                              AppTheme.errorLight.withOpacity(0.05),
                            ]
                          : [
                              AppTheme.errorDark.withOpacity(0.15),
                              AppTheme.errorDark.withOpacity(0.1),
                            ])
                      : (isLight
                          ? [
                              AppTheme.primaryLight.withOpacity(0.1),
                              AppTheme.secondaryLight.withOpacity(0.1),
                            ]
                          : [
                              AppTheme.primaryDark.withOpacity(0.15),
                              AppTheme.secondaryDark.withOpacity(0.15),
                            ]),
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isPast
                      ? (isLight
                          ? AppTheme.errorLight.withOpacity(0.4)
                          : AppTheme.errorDark.withOpacity(0.4))
                      : (isLight
                          ? AppTheme.primaryLight.withOpacity(0.4)
                          : AppTheme.primaryDark.withOpacity(0.4)),
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: (isPast
                            ? (isLight
                                ? AppTheme.errorLight
                                : AppTheme.errorDark)
                            : (isLight
                                ? AppTheme.primaryLight
                                : AppTheme.primaryDark))
                        .withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: isPast
                              ? (isLight
                                  ? AppTheme.errorLight.withOpacity(0.15)
                                  : AppTheme.errorDark.withOpacity(0.2))
                              : (isLight
                                  ? AppTheme.primaryLight.withOpacity(0.15)
                                  : AppTheme.primaryDark.withOpacity(0.2)),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          isPast ? Icons.event_busy : Icons.access_time_rounded,
                          color: isPast
                              ? (isLight
                                  ? AppTheme.errorLight
                                  : AppTheme.errorDark)
                              : (isLight
                                  ? AppTheme.primaryLight
                                  : AppTheme.primaryDark),
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Consumer<FontSizeProvider>(
                          builder: (context, fontSizeProvider, _) => Text(
                            isPast
                                ? _formatTimeRemaining(alert.date)
                                : _formatTimeRemaining(alert.date),
                            style: TextStyle(
                              fontSize: fontSizeProvider.fontSize + 3,
                              fontWeight: FontWeight.bold,
                              color: isPast
                                  ? (isLight
                                      ? AppTheme.errorLight
                                      : AppTheme.errorDark)
                                  : (isLight
                                      ? AppTheme.primaryLight
                                      : AppTheme.primaryDark),
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (!alert.active) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: isLight
                            ? Colors.grey.shade200
                            : Colors.grey.shade800,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.pause_circle_filled,
                            size: 16,
                            color: isLight
                                ? Colors.grey.shade700
                                : Colors.grey.shade400,
                          ),
                          const SizedBox(width: 6),
                          Consumer<FontSizeProvider>(
                            builder: (context, fontSizeProvider, _) => Text(
                              'Recordatorio desactivado',
                              style: TextStyle(
                                fontSize: fontSizeProvider.fontSize - 2,
                                fontWeight: FontWeight.w600,
                                color: isLight
                                    ? Colors.grey.shade700
                                    : Colors.grey.shade400,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // Información principal
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Imagen (si existe)
                  if (alert.imagePath != null &&
                      alert.imagePath!.isNotEmpty) ...[
                    _buildImageCard(context),
                    const SizedBox(height: 24),
                  ],

                  // Contenedor compacto con toda la información
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: isLight ? AppTheme.cardLight : AppTheme.cardDark,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isLight
                            ? AppTheme.dividerLight
                            : AppTheme.dividerDark,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: isLight
                              ? Colors.black.withOpacity(0.05)
                              : Colors.black.withOpacity(0.2),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Título de la sección
                        Consumer<FontSizeProvider>(
                          builder: (context, fontSizeProvider, _) => Text(
                            'Detalles del Recordatorio',
                            style: TextStyle(
                              fontSize: fontSizeProvider.fontSize + 2,
                              fontWeight: FontWeight.bold,
                              color: isLight
                                  ? AppTheme.textPrimaryLight
                                  : AppTheme.textPrimaryDark,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Fecha y hora
                        _buildCompactInfoRow(
                          context,
                          icon: Icons.event_rounded,
                          label: 'Fecha',
                          value: _formatDate(alert.date),
                        ),
                        const SizedBox(height: 12),

                        _buildCompactInfoRow(
                          context,
                          icon: Icons.access_time_rounded,
                          label: 'Hora',
                          value: _formatTime(alert.date),
                        ),

                        // Descripción
                        if (alert.description.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          _buildCompactInfoRow(
                            context,
                            icon: Icons.notes_rounded,
                            label: 'Descripción',
                            value: alert.description,
                            multiline: true,
                          ),
                        ],

                        // Artículo
                        if (alert.object != null &&
                            alert.object!.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          _buildCompactInfoRow(
                            context,
                            icon: Icons.inventory_2_rounded,
                            label: 'Artículo',
                            value: alert.object!,
                          ),
                        ],

                        // Ubicación
                        if (alert.location != null &&
                            alert.location!.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          _buildCompactInfoRow(
                            context,
                            icon: Icons.location_on_rounded,
                            label: 'Ubicación',
                            value: alert.location!,
                          ),
                        ],

                        // Repetitiva
                        if (alert.repetitive) ...[
                          const SizedBox(height: 12),
                          _buildCompactInfoRow(
                            context,
                            icon: Icons.repeat_rounded,
                            label: 'Repetición',
                            value: alert.repeatFrequency ?? 'Sin especificar',
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Botones de acción
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  if (alert.active && !isPast)
                    ElevatedButton.icon(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Recordatorio desactivado'),
                          ),
                        );
                        Navigator.pop(context);
                      },
                      icon: const Icon(Icons.pause_circle_filled),
                      label: const Text('Desactivar Recordatorio'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isLight
                            ? AppTheme.warningLight
                            : AppTheme.warningDark,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 52),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 2,
                      ),
                    ),
                  if (alert.active && !isPast) const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: Row(
                            children: [
                              Icon(
                                Icons.warning_rounded,
                                color: isLight
                                    ? AppTheme.errorLight
                                    : AppTheme.errorDark,
                              ),
                              const SizedBox(width: 8),
                              const Text('Eliminar Recordatorio'),
                            ],
                          ),
                          content: const Text(
                            '¿Estás seguro de que quieres eliminar este Recordatorio? Esta acción no se puede deshacer.',
                          ),
                          actions: [
                            Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: () => Navigator.pop(context),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                  child: const Text(
                                    'Cancelar',
                                    style: TextStyle(
                                      color: Colors.blue,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            ElevatedButton.icon(
                              onPressed: () {
                                Navigator.pop(context); // Cierra el diálogo
                                Navigator.pop(
                                    context); // Cierra la pantalla de detalle
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: const Text('Recordatorio eliminado'),
                                    backgroundColor: isLight
                                        ? AppTheme.errorLight
                                        : AppTheme.errorDark,
                                  ),
                                );
                              },
                              icon: const Icon(Icons.delete),
                              label: const Text('Eliminar'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: isLight
                                    ? AppTheme.errorLight
                                    : AppTheme.errorDark,
                                foregroundColor: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                    icon: const Icon(Icons.delete_outline),
                    label: const Text('Eliminar Recordatorio'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor:
                          isLight ? AppTheme.errorLight : AppTheme.errorDark,
                      side: BorderSide(
                        color:
                            isLight ? AppTheme.errorLight : AppTheme.errorDark,
                        width: 2,
                      ),
                      minimumSize: const Size(double.infinity, 52),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageCard(BuildContext context) {
    final bool isLight = Theme.of(context).brightness == Brightness.light;

    return Container(
      decoration: BoxDecoration(
        color: isLight ? AppTheme.cardLight : AppTheme.cardDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isLight ? AppTheme.dividerLight : AppTheme.dividerDark,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: _color.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header de la imagen
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _color.withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.image,
                  color: _color,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Consumer<FontSizeProvider>(
                  builder: (context, fontSizeProvider, _) => Text(
                    'Imagen adjunta',
                    style: TextStyle(
                      fontSize: fontSizeProvider.fontSize,
                      fontWeight: FontWeight.w600,
                      color: _color,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Imagen
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => _ImageViewer(path: alert.imagePath!),
                ),
              );
            },
            child: ClipRRect(
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(16),
                bottomRight: Radius.circular(16),
              ),
              child: FutureBuilder<Uint8List>(
                future: XFile(alert.imagePath!).readAsBytes(),
                builder: (context, snap) {
                  if (snap.connectionState != ConnectionState.done ||
                      !snap.hasData) {
                    return Container(
                      height: 200,
                      color:
                          isLight ? Colors.grey.shade200 : Colors.grey.shade800,
                      child: Center(
                        child: CircularProgressIndicator(
                          color: _color,
                        ),
                      ),
                    );
                  }
                  return Stack(
                    children: [
                      Image.memory(
                        snap.data!,
                        width: double.infinity,
                        height: 200,
                        fit: BoxFit.cover,
                      ),
                      Positioned(
                        bottom: 8,
                        right: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.6),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.zoom_in,
                                color: Colors.white,
                                size: 16,
                              ),
                              SizedBox(width: 4),
                              Text(
                                'Toca para ampliar',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactInfoRow(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    bool multiline = false,
  }) {
    final bool isLight = Theme.of(context).brightness == Brightness.light;

    return Row(
      crossAxisAlignment:
          multiline ? CrossAxisAlignment.start : CrossAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: _color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: _color,
            size: 20,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Consumer<FontSizeProvider>(
                builder: (context, fontSizeProvider, _) => Text(
                  label,
                  style: TextStyle(
                    fontSize: fontSizeProvider.fontSize - 2,
                    color: AppTheme.getTextSecondary(context),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 2),
              Consumer<FontSizeProvider>(
                builder: (context, fontSizeProvider, _) => Text(
                  value,
                  style: TextStyle(
                    fontSize: fontSizeProvider.fontSize + 1,
                    fontWeight: FontWeight.w600,
                    color: isLight
                        ? AppTheme.textPrimaryLight
                        : AppTheme.textPrimaryDark,
                    height: 1.3,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

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
              return const CircularProgressIndicator(
                color: Colors.white,
              );
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
