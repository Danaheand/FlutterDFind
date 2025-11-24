import 'dart:async';
import 'package:Dfind/models/recordatorio.dart';
import 'package:Dfind/repository/recordatorio_repository.dart';
import 'package:Dfind/services/session_manager.dart';

/// Servicio para gestionar notificaciones en web
/// Verifica periódicamente las alertas próximas y muestra notificaciones visuales
class WebNotificationService {
  static final WebNotificationService _instance =
      WebNotificationService._internal();
  factory WebNotificationService() => _instance;
  WebNotificationService._internal();

  final RecordatorioRepository _repository = RecordatorioRepository();
  Timer? _periodicTimer;
  bool _isInitialized = false;
  
  // Callback para mostrar notificaciones
  Function(String title, String body)? _onNotificationCallback;
  
  // Almacenar recordatorios ya notificados en esta sesión
  final Set<String> _notifiedRecordatorios = {};

  /// Inicializa el servicio de notificaciones para web
  Future<void> initialize({
    required Function(String title, String body) onNotification,
  }) async {
    if (_isInitialized) return;

    try {
      _onNotificationCallback = onNotification;
      _isInitialized = true;
      print('✅ WebNotificationService inicializado');

      // Verificar inmediatamente al iniciar
      await checkAndNotifyUpcomingAlerts();

      // Verificar cada minuto para alertas próximas
      _periodicTimer = Timer.periodic(
        const Duration(minutes: 1),
        (_) => checkAndNotifyUpcomingAlerts(),
      );
    } catch (e) {
      print('❌ Error al inicializar WebNotificationService: $e');
    }
  }

  /// Verifica los recordatorios próximos a vencer y muestra notificaciones
  Future<void> checkAndNotifyUpcomingAlerts() async {
    try {
      final email = SessionManager.instance.userEmail;
      if (email == null || email.isEmpty) {
        return;
      }

      print('🔔 Verificando recordatorios próximos en web...');

      // Obtener todos los recordatorios activos del usuario
      final recordatorios =
          await _repository.obtenerRecordatoriosUsuario(email);
      final recordatoriosActivos =
          recordatorios.where((r) => r.activo).toList();

      final now = DateTime.now();
      int alertsShown = 0;

      for (final recordatorio in recordatoriosActivos) {
        // Verificar si el recordatorio es ahora (dentro de 1 minuto)
        final diferencia =
            recordatorio.fechaHora.difference(now).inSeconds.abs();

        // Si es repetitivo, verificar si hoy es uno de los días seleccionados
        bool debeNotificar = false;

        if (recordatorio.esRepetitivo && recordatorio.diasSeleccionados != null) {
          final diasSeleccionados =
              _parseDiasSeleccionados(recordatorio.diasSeleccionados!);
          final hoyEsDiaSeleccionado = diasSeleccionados.contains(now.weekday);

          if (hoyEsDiaSeleccionado && diferencia < 60) {
            debeNotificar = true;
          }
        } else {
          // Si no es repetitivo, solo verificar si es hoy y la hora es cercana
          final mismaFecha = recordatorio.fechaHora.year == now.year &&
              recordatorio.fechaHora.month == now.month &&
              recordatorio.fechaHora.day == now.day;

          if (mismaFecha && diferencia < 60) {
            debeNotificar = true;
          }
        }

        // Mostrar notificación si no se ha mostrado antes en esta sesión
        if (debeNotificar &&
            !_notifiedRecordatorios.contains(recordatorio.titulo)) {
          _showNotification(recordatorio);
          _notifiedRecordatorios.add(recordatorio.titulo);
          alertsShown++;
        }
      }

      if (alertsShown > 0) {
        print('✅ $alertsShown notificaciones mostradas en web');
      }
    } catch (e) {
      print('⚠️ Error en verificación de notificaciones web: $e');
    }
  }

  /// Muestra una notificación visual para un recordatorio
  void _showNotification(Recordatorio recordatorio) {
    final emoji = _getPriorityEmoji(recordatorio.prioridad);
    final title = '$emoji ${recordatorio.titulo}';
    final body = _buildNotificationBody(recordatorio);

    print('🔔 Mostrando notificación: $title');
    _onNotificationCallback?.call(title, body);

    // Reproducir sonido
    _playNotificationSound();
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
        return '🔴';
      case 'media':
        return '🟡';
      case 'baja':
        return '🟢';
      default:
        return '📋';
    }
  }

  /// Parsea los días seleccionados desde el formato guardado
  List<int> _parseDiasSeleccionados(String diasSeleccionados) {
    try {
      if (diasSeleccionados.contains(',')) {
        final dias = diasSeleccionados.split(',');
        return dias
            .map((d) {
              final trimmed = d.trim();
              final numero = int.tryParse(trimmed);
              if (numero != null) return numero;
              return _weekdayNameToNumber(trimmed);
            })
            .where((d) => d >= 1 && d <= 7)
            .toList();
      }
      return [1];
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

  /// Reproduce sonido de notificación
  void _playNotificationSound() {
    try {
      // En web, usar Web Audio API
      // Por ahora solo log, la implementación real usaría dart:web
      print('🔊 Reproduciendo sonido de notificación');
    } catch (e) {
      print('Error reproduciendo sonido: $e');
    }
  }

  /// Limpia los recordatorios notificados (útil al cambiar de día)
  void clearNotifiedRecordatorios() {
    _notifiedRecordatorios.clear();
    print('🧹 Cache de recordatorios notificados limpiado');
  }

  /// Detiene el servicio
  void dispose() {
    _periodicTimer?.cancel();
    _periodicTimer = null;
    _isInitialized = false;
    _onNotificationCallback = null;
    _notifiedRecordatorios.clear();
    print('🛑 WebNotificationService detenido');
  }

  /// Reinicia el servicio
  Future<void> restart({
    required Function(String title, String body) onNotification,
  }) async {
    dispose();
    await initialize(onNotification: onNotification);
  }
}
