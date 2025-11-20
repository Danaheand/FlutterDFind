import 'dart:async';
import 'package:Dfind/models/recordatorio.dart';
import 'package:Dfind/services/notification_service.dart';
import 'package:Dfind/services/session_manager.dart';
import 'package:Dfind/repository/recordatorio_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Servicio para gestionar notificaciones en background
/// Verifica periódicamente las alertas próximas a vencer y programa notificaciones
class BackgroundNotificationService {
  static final BackgroundNotificationService _instance =
      BackgroundNotificationService._internal();
  factory BackgroundNotificationService() => _instance;
  BackgroundNotificationService._internal();

  final NotificationService _notificationService = NotificationService();
  final RecordatorioRepository _repository = RecordatorioRepository();
  Timer? _periodicTimer;
  bool _isInitialized = false;

  static const String _lastCheckKey = 'last_notification_check';
  static const String _notificationIdsKey = 'scheduled_notification_ids';

  /// Inicializa el servicio de notificaciones en background
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      await _notificationService.initialize();
      _isInitialized = true;
      print('✅ BackgroundNotificationService inicializado');

      // Verificar inmediatamente al iniciar
      await checkAndScheduleNotifications();

      // Verificar cada 15 minutos
      _periodicTimer = Timer.periodic(
        const Duration(minutes: 15),
        (_) => checkAndScheduleNotifications(),
      );
    } catch (e) {
      print('❌ Error al inicializar BackgroundNotificationService: $e');
    }
  }

  /// Verifica los recordatorios y programa notificaciones para los próximos a vencer
  Future<void> checkAndScheduleNotifications() async {
    try {
      final email = SessionManager.instance.userEmail;
      if (email == null || email.isEmpty) {
        print(
            '⚠️ No hay usuario autenticado, saltando verificación de notificaciones');
        return;
      }

      print('🔔 Verificando recordatorios para programar notificaciones...');

      // Obtener todos los recordatorios activos del usuario
      final recordatorios =
          await _repository.obtenerRecordatoriosUsuario(email);
      final recordatoriosActivos =
          recordatorios.where((r) => r.activo).toList();

      final now = DateTime.now();
      int notificationsProgrammed = 0;

      for (final recordatorio in recordatoriosActivos) {
        // Solo programar notificaciones para recordatorios futuros
        if (recordatorio.fechaHora.isAfter(now)) {
          await _scheduleNotificationForRecordatorio(recordatorio);
          notificationsProgrammed++;
        }
      }

      // Guardar timestamp de la última verificación
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_lastCheckKey, now.millisecondsSinceEpoch);

      print('✅ $notificationsProgrammed notificaciones programadas');
    } catch (e) {
      print('❌ Error al verificar notificaciones: $e');
    }
  }

  /// Programa una notificación para un recordatorio específico
  Future<void> scheduleNotificationForRecordatorio(
      Recordatorio recordatorio) async {
    try {
      await _scheduleNotificationForRecordatorio(recordatorio);
      print('✅ Notificación programada para "${recordatorio.titulo}"');
    } catch (e) {
      print(
          '❌ Error al programar notificación para "${recordatorio.titulo}": $e');
    }
  }

  Future<void> _scheduleNotificationForRecordatorio(
      Recordatorio recordatorio) async {
    final notificationId = _getNotificationId(recordatorio.titulo);
    final now = DateTime.now();

    if (recordatorio.esRepetitivo && recordatorio.diasSeleccionados != null) {
      // Notificación repetitiva
      final weekdays = _parseDiasSeleccionados(recordatorio.diasSeleccionados!);

      await _notificationService.scheduleRepeatingAlarmNotification(
        baseId: notificationId,
        title: _getPriorityEmoji(recordatorio.prioridad) + recordatorio.titulo,
        body: _buildNotificationBody(recordatorio),
        scheduledDate: recordatorio.fechaHora,
        weekdays: weekdays,
        payload: recordatorio.titulo,
      );
    } else {
      // Notificación única
      if (recordatorio.fechaHora.isAfter(now)) {
        await _notificationService.scheduleAlarmNotification(
          id: notificationId,
          title:
              _getPriorityEmoji(recordatorio.prioridad) + recordatorio.titulo,
          body: _buildNotificationBody(recordatorio),
          scheduledDate: recordatorio.fechaHora,
          payload: recordatorio.titulo,
        );

        // Programar notificación previa (5 minutos antes)
        final reminderTime =
            recordatorio.fechaHora.subtract(const Duration(minutes: 5));
        if (reminderTime.isAfter(now)) {
          await _notificationService.scheduleAlarmNotification(
            id: notificationId +
                10000, // ID diferente para la notificación previa
            title: '⏰ Recordatorio próximo',
            body: '${recordatorio.titulo} - En 5 minutos',
            scheduledDate: reminderTime,
            payload: recordatorio.titulo,
          );
        }
      }
    }

    // Guardar ID de notificación programada
    await _saveNotificationId(notificationId);
  }

  /// Cancela la notificación de un recordatorio
  Future<void> cancelNotificationForRecordatorio(String titulo) async {
    try {
      final notificationId = _getNotificationId(titulo);
      await _notificationService.cancelNotification(notificationId);
      await _notificationService.cancelNotification(
          notificationId + 10000); // Cancelar también la notificación previa

      // Remover ID de notificaciones guardadas
      await _removeNotificationId(notificationId);

      print('✅ Notificación cancelada para "$titulo"');
    } catch (e) {
      print('❌ Error al cancelar notificación para "$titulo": $e');
    }
  }

  /// Cancela todas las notificaciones programadas
  Future<void> cancelAllNotifications() async {
    try {
      await _notificationService.cancelAllNotifications();

      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_notificationIdsKey);

      print('✅ Todas las notificaciones canceladas');
    } catch (e) {
      print('❌ Error al cancelar todas las notificaciones: $e');
    }
  }

  /// Obtiene las notificaciones pendientes
  Future<int> getPendingNotificationsCount() async {
    try {
      final pending = await _notificationService.getPendingNotifications();
      return pending.length;
    } catch (e) {
      print('❌ Error al obtener notificaciones pendientes: $e');
      return 0;
    }
  }

  /// Genera un ID único para cada recordatorio basado en su título
  int _getNotificationId(String titulo) {
    // Usar hashCode del título para generar un ID único
    return titulo.hashCode.abs() % 100000;
  }

  /// Construye el cuerpo de la notificación
  String _buildNotificationBody(Recordatorio recordatorio) {
    final parts = <String>[];

    if (recordatorio.descripcion.isNotEmpty) {
      parts.add(recordatorio.descripcion);
    }

    if (recordatorio.ubicacion != null && recordatorio.ubicacion!.isNotEmpty) {
      parts.add('📍 ${recordatorio.ubicacion}');
    }

    if (recordatorio.objeto != null && recordatorio.objeto!.isNotEmpty) {
      parts.add('📦 ${recordatorio.objeto}');
    }

    return parts.isEmpty ? 'Es hora de tu recordatorio' : parts.join(' • ');
  }

  /// Obtiene el emoji según la prioridad
  String _getPriorityEmoji(String prioridad) {
    switch (prioridad.toLowerCase()) {
      case 'alta':
        return '🔴 ';
      case 'media':
        return '🟡 ';
      case 'baja':
        return '🟢 ';
      default:
        return '📋 ';
    }
  }

  /// Parsea los días seleccionados desde el formato guardado
  List<int> _parseDiasSeleccionados(String diasSeleccionados) {
    try {
      // Formato esperado: "1,2,3,4,5" o "Lunes,Martes,..."
      if (diasSeleccionados.contains(',')) {
        final dias = diasSeleccionados.split(',');
        return dias
            .map((d) {
              final trimmed = d.trim();
              // Si es un número, devolverlo directamente
              final numero = int.tryParse(trimmed);
              if (numero != null) return numero;

              // Si es un nombre de día, convertirlo
              return _weekdayNameToNumber(trimmed);
            })
            .where((d) => d >= 1 && d <= 7)
            .toList();
      }
      return [1]; // Default: Lunes
    } catch (e) {
      print('Error parseando días seleccionados: $e');
      return [1];
    }
  }

  int _weekdayNameToNumber(String name) {
    const map = {
      'lunes': 1,
      'monday': 1,
      'martes': 2,
      'tuesday': 2,
      'miércoles': 3,
      'miercoles': 3,
      'wednesday': 3,
      'jueves': 4,
      'thursday': 4,
      'viernes': 5,
      'friday': 5,
      'sábado': 6,
      'sabado': 6,
      'saturday': 6,
      'domingo': 7,
      'sunday': 7,
    };
    return map[name.toLowerCase()] ?? 1;
  }

  /// Guarda el ID de una notificación programada
  Future<void> _saveNotificationId(int id) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final ids = prefs.getStringList(_notificationIdsKey) ?? [];
      if (!ids.contains(id.toString())) {
        ids.add(id.toString());
        await prefs.setStringList(_notificationIdsKey, ids);
      }
    } catch (e) {
      print('Error guardando ID de notificación: $e');
    }
  }

  /// Remueve el ID de una notificación cancelada
  Future<void> _removeNotificationId(int id) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final ids = prefs.getStringList(_notificationIdsKey) ?? [];
      ids.remove(id.toString());
      await prefs.setStringList(_notificationIdsKey, ids);
    } catch (e) {
      print('Error removiendo ID de notificación: $e');
    }
  }

  /// Detiene el servicio de background
  void dispose() {
    _periodicTimer?.cancel();
    _periodicTimer = null;
    _isInitialized = false;
    print('🛑 BackgroundNotificationService detenido');
  }

  /// Reinicia el servicio de verificación
  Future<void> restart() async {
    dispose();
    await initialize();
  }
}
