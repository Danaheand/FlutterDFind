import 'package:Dfind/services/trash_service.dart';
import 'package:flutter/foundation.dart';
import '../models/recordatorio.dart';
import '../models/recordatorio_exception.dart';
import '../repository/recordatorio_repository.dart';
import '../services/session_manager.dart';
import '../services/background_notification_service.dart';

/// Provider para gestionar el estado de los recordatorios en la aplicación
/// Utiliza ChangeNotifier para notificar cambios a los widgets que escuchan
class RecordatorioProvider extends ChangeNotifier {
  final RecordatorioRepository _repository;
  final trashService = TrashService.getInstance();
  final BackgroundNotificationService _notificationService =
      BackgroundNotificationService();

  // Estado
  List<Recordatorio> _recordatorios = [];
  bool _isLoading = false;
  String? _error;

  // Getters
  List<Recordatorio> get recordatorios => List.unmodifiable(_recordatorios);
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Obtiene el correo del usuario desde el SessionManager
  String? get correoUsuario => SessionManager.instance.userEmail;

  /// Recordatorios activos (no pausados)
  List<Recordatorio> get recordatoriosActivos =>
      _recordatorios.where((r) => r.activo).toList();

  /// Recordatorios inactivos (pausados)
  List<Recordatorio> get recordatoriosInactivos =>
      _recordatorios.where((r) => !r.activo).toList();

  /// Cuenta total de recordatorios
  int get totalRecordatorios => _recordatorios.length;

  /// Cuenta de recordatorios activos
  int get totalActivos => recordatoriosActivos.length;

  /// Cuenta de recordatorios inactivos
  int get totalInactivos => recordatoriosInactivos.length;

  RecordatorioProvider({RecordatorioRepository? repository})
      : _repository = repository ?? RecordatorioRepository();

  /// 1️⃣ Cargar todos los recordatorios del usuario
  ///
  /// Debe llamarse al:
  /// - Abrir la app
  /// - Recargar la pantalla de recordatorios
  /// - Después de login exitoso
  ///
  /// Ya no necesitas pasar el correo, se obtiene automáticamente del SessionManager
  Future<void> cargarRecordatorios() async {
    final email = SessionManager.instance.userEmail;

    if (email == null || email.isEmpty) {
      _error = 'No hay un usuario autenticado';
      notifyListeners();
      return;
    }

    _setLoading(true);
    _error = null;

    try {
      print('📱 Provider: Cargando recordatorios para $email');

      _recordatorios = await _repository.obtenerRecordatoriosUsuario(email);

      print('✅ Provider: ${_recordatorios.length} recordatorios cargados');
      _setLoading(false);
    } on RecordatorioException catch (e) {
      _error = e.message;
      _setLoading(false);
      print('❌ Provider: Error al cargar recordatorios: ${e.message}');
      rethrow;
    } catch (e) {
      _error = 'Error inesperado al cargar recordatorios';
      _setLoading(false);
      print('❌ Provider: Error inesperado: $e');
      rethrow;
    }
  }

  /// 2️⃣ Crear un nuevo recordatorio
  ///
  /// [recordatorio] El recordatorio a crear
  /// [autoReload] Si debe recargar la lista después de crear (default: true)
  Future<Recordatorio> crearRecordatorio(
    Recordatorio recordatorio, {
    bool autoReload = true,
  }) async {
    _setLoading(true);
    _error = null;

    try {
      print('📱 Provider: Creando recordatorio "${recordatorio.titulo}"');

      final recordatorioCreado =
          await _repository.crearRecordatorio(recordatorio);

      // Agregar a la lista local
      _recordatorios.add(recordatorioCreado);

      // Programar notificación para el recordatorio
      await _notificationService
          .scheduleNotificationForRecordatorio(recordatorioCreado);

      print('✅ Provider: Recordatorio creado exitosamente');
      _setLoading(false);

      // Opcional: recargar para sincronizar con el servidor
      if (autoReload) {
        await cargarRecordatorios();
      }

      return recordatorioCreado;
    } on RecordatorioException catch (e) {
      _error = e.message;
      _setLoading(false);
      print('❌ Provider: Error al crear recordatorio: ${e.message}');
      rethrow;
    } catch (e) {
      _error = 'Error inesperado al crear recordatorio';
      _setLoading(false);
      print('❌ Provider: Error inesperado: $e');
      rethrow;
    }
  }

  /// 3️⃣ Actualizar un recordatorio existente
  ///
  /// [tituloOriginal] El título actual (identificador)
  /// [recordatorio] Los nuevos datos
  /// [autoReload] Si debe recargar la lista después de actualizar (default: true)
  Future<Recordatorio> actualizarRecordatorio(
    String tituloOriginal,
    Recordatorio recordatorio, {
    bool autoReload = true,
  }) async {
    _setLoading(true);
    _error = null;

    try {
      print('📱 Provider: Actualizando recordatorio "$tituloOriginal"');

      final recordatorioActualizado = await _repository.actualizarRecordatorio(
        tituloOriginal,
        recordatorio,
      );

      // Actualizar en la lista local
      final index =
          _recordatorios.indexWhere((r) => r.titulo == tituloOriginal);
      if (index != -1) {
        _recordatorios[index] = recordatorioActualizado;
      }

      // Cancelar notificación anterior y programar nueva
      await _notificationService
          .cancelNotificationForRecordatorio(tituloOriginal);
      await _notificationService
          .scheduleNotificationForRecordatorio(recordatorioActualizado);

      print('✅ Provider: Recordatorio actualizado exitosamente');
      _setLoading(false);

      // Opcional: recargar para sincronizar
      if (autoReload) {
        await cargarRecordatorios();
      }

      return recordatorioActualizado;
    } on RecordatorioException catch (e) {
      _error = e.message;
      _setLoading(false);
      print('❌ Provider: Error al actualizar recordatorio: ${e.message}');
      rethrow;
    } catch (e) {
      _error = 'Error inesperado al actualizar recordatorio';
      _setLoading(false);
      print('❌ Provider: Error inesperado: $e');
      rethrow;
    }
  }

  /// 4️⃣ Eliminar un recordatorio
  ///
  /// [titulo] El título del recordatorio a eliminar
  /// [autoReload] Si debe recargar la lista después de eliminar (default: true)
  Future<void> eliminarRecordatorio(
    String titulo, {
    bool autoReload = true,
  }) async {
    _setLoading(true);
    _error = null;

    try {
      final email = SessionManager.instance.userEmail;

      if (email == null || email.isEmpty) {
        _error = 'No hay un usuario autenticado';
        notifyListeners();
        return;
      }
      print('📱 Provider: Eliminando recordatorio "$titulo"');

      await _repository.eliminarRecordatorio(titulo, email);

      // Cancelar notificación del recordatorio eliminado
      await _notificationService.cancelNotificationForRecordatorio(titulo);

      // Eliminar de la lista local
      _recordatorios.removeWhere((r) => r.titulo == titulo);

      print('✅ Provider: Recordatorio eliminado exitosamente');
      _setLoading(false);

      // Opcional: recargar para sincronizar
      if (autoReload) {
        await cargarRecordatorios();
      }
    } on RecordatorioException catch (e) {
      _error = e.message;
      _setLoading(false);
      print('❌ Provider: Error al eliminar recordatorio: ${e.message}');
      rethrow;
    } catch (e) {
      _error = 'Error inesperado al eliminar recordatorio';
      _setLoading(false);
      print('❌ Provider: Error inesperado: $e');
      rethrow;
    }
  }

  /// 5️⃣ Alternar estado activo/inactivo de un recordatorio
  ///
  /// [titulo] El título del recordatorio
  /// [autoReload] Si debe recargar la lista después del toggle (default: false)
  Future<Recordatorio> toggleActivoRecordatorio(
    String titulo, {
    bool autoReload = false,
  }) async {
    // No mostrar loading para toggle (es más rápido y no queremos bloquear UI)
    _error = null;

    try {
      print('📱 Provider: Cambiando estado de "$titulo"');
      _setLoading(true);

      final recordatorioActualizado =
          await _repository.toggleActivoRecordatorio(titulo);

      // Actualizar en la lista local
      final index = _recordatorios.indexWhere((r) => r.titulo == titulo);
      if (index != -1) {
        _recordatorios[index] = recordatorioActualizado;
      }

      // Gestionar notificación según el estado
      if (recordatorioActualizado.activo) {
        // Si se activa, programar notificación
        await _notificationService
            .scheduleNotificationForRecordatorio(recordatorioActualizado);
      } else {
        // Si se desactiva, cancelar notificación
        await _notificationService.cancelNotificationForRecordatorio(titulo);
      }

      _setLoading(false);
      print(
          '✅ Provider: Estado cambiado (activo=${recordatorioActualizado.activo})');
      notifyListeners();

      // Opcional: recargar para sincronizar
      if (autoReload) {
        await cargarRecordatorios();
      }

      return recordatorioActualizado;
    } on RecordatorioException catch (e) {
      _error = e.message;
      notifyListeners();
      print('❌ Provider: Error al cambiar estado: ${e.message}');
      rethrow;
    } catch (e) {
      _error = 'Error inesperado al cambiar estado';
      notifyListeners();
      print('❌ Provider: Error inesperado: $e');
      rethrow;
    }
  }

  /// Buscar recordatorios por término
  List<Recordatorio> buscarRecordatorios(String termino) {
    if (termino.isEmpty) return _recordatorios;

    final terminoLower = termino.toLowerCase();
    return _recordatorios.where((r) {
      return r.titulo.toLowerCase().contains(terminoLower) ||
          r.descripcion.toLowerCase().contains(terminoLower) ||
          (r.ubicacion?.toLowerCase().contains(terminoLower) ?? false) ||
          (r.objeto?.toLowerCase().contains(terminoLower) ?? false);
    }).toList();
  }

  /// Obtener recordatorios ordenados por fecha
  List<Recordatorio> get recordatoriosOrdenadosPorFecha {
    final lista = List<Recordatorio>.from(_recordatorios);
    lista.sort((a, b) => a.fechaHora.compareTo(b.fechaHora));
    return lista;
  }

  /// Obtener recordatorios ordenados por prioridad
  List<Recordatorio> get recordatoriosOrdenadosPorPrioridad {
    final lista = List<Recordatorio>.from(_recordatorios);
    lista.sort((a, b) {
      final prioridadA = _prioridadValor(a.prioridad);
      final prioridadB = _prioridadValor(b.prioridad);
      return prioridadB.compareTo(prioridadA); // Mayor prioridad primero
    });
    return lista;
  }

  int _prioridadValor(String? prioridad) {
    switch (prioridad?.toLowerCase()) {
      case 'alta':
        return 3;
      case 'media':
        return 2;
      case 'baja':
        return 1;
      default:
        return 0;
    }
  }

  /// Limpiar el estado (útil al cerrar sesión)
  void limpiar() {
    _recordatorios = [];
    _error = null;
    _isLoading = false;
    // Cancelar todas las notificaciones al limpiar
    _notificationService.cancelAllNotifications();
    notifyListeners();
  }

  /// Método privado para actualizar el estado de carga
  void _setLoading(bool value) {
    print('🔵 Provider: isLoading = $value');
    _isLoading = value;
    notifyListeners();
  }

  /// Recargar recordatorios (pull-to-refresh)
  Future<void> recargar() async {
    await cargarRecordatorios();
  }
}
