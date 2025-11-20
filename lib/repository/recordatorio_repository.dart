import '../models/recordatorio.dart';
import '../models/recordatorio_exception.dart';
import '../services/recordatorio_api_service.dart';

/// Repositorio para gestionar los recordatorios
/// Actua como intermediario entre la UI y el servicio de API
/// Implementa el patron Repository para separar la logica de negocio
class RecordatorioRepository {
  RecordatorioRepository();

  /// Obtiene todos los recordatorios de un usuario
  ///
  /// [correo] El correo del usuario
  ///
  /// Retorna una lista de recordatorios, vacía si no hay ninguno
  /// Lanza RecordatorioException si hay un error
  Future<List<Recordatorio>> obtenerRecordatoriosUsuario(
    String correo,
  ) async {
    try {
      if (correo.isEmpty) {
        throw RecordatorioValidationException(
          'El correo del usuario no puede estar vacío',
        );
      }

      return await RecordatorioApiService.obtenerRecordatoriosPorCorreo(correo);
    } catch (e) {
      print('❌ Error en repositorio al obtener recordatorios: $e');
      rethrow;
    }
  }

  /// Crea un nuevo recordatorio
  ///
  /// [recordatorio] El recordatorio a crear
  ///
  /// Retorna el recordatorio creado con los datos del servidor
  /// Lanza RecordatorioException si hay un error o validación falla
  Future<Recordatorio> crearRecordatorio(Recordatorio recordatorio) async {
    try {
      // Validaciones básicas
      _validarRecordatorio(recordatorio);

      return await RecordatorioApiService.crearRecordatorio(recordatorio);
    } catch (e) {
      print('❌ Error en repositorio al crear recordatorio: $e');
      rethrow;
    }
  }

  /// Actualiza un recordatorio existente
  ///
  /// [tituloOriginal] El título actual del recordatorio (identificador)
  /// [recordatorio] Los nuevos datos del recordatorio
  ///
  /// Retorna el recordatorio actualizado
  /// Lanza RecordatorioException si hay un error
  Future<Recordatorio> actualizarRecordatorio(
    String tituloOriginal,
    Recordatorio recordatorio,
  ) async {
    try {
      if (tituloOriginal.isEmpty) {
        throw RecordatorioValidationException(
          'El título original no puede estar vacío',
        );
      }

      _validarRecordatorio(recordatorio);

      return await RecordatorioApiService.actualizarRecordatorio(
        tituloOriginal,
        recordatorio,
      );
    } catch (e) {
      print('❌ Error en repositorio al actualizar recordatorio: $e');
      rethrow;
    }
  }

  /// Elimina un recordatorio
  ///
  /// [titulo] El título del recordatorio a eliminar
  ///
  /// Retorna true si se eliminó correctamente
  /// Lanza RecordatorioException si hay un error
  Future<bool> eliminarRecordatorio(String titulo) async {
    try {
      if (titulo.isEmpty) {
        throw RecordatorioValidationException(
          'El título del recordatorio no puede estar vacío',
        );
      }

      return await RecordatorioApiService.eliminarRecordatorio(titulo);
    } catch (e) {
      print('❌ Error en repositorio al eliminar recordatorio: $e');
      rethrow;
    }
  }

  /// Alterna el estado activo/inactivo de un recordatorio
  ///
  /// [titulo] El título del recordatorio
  ///
  /// Retorna el recordatorio con el estado actualizado
  /// Lanza RecordatorioException si hay un error
  Future<Recordatorio> toggleActivoRecordatorio(String titulo) async {
    try {
      if (titulo.isEmpty) {
        throw RecordatorioValidationException(
          'El título del recordatorio no puede estar vacío',
        );
      }

      return await RecordatorioApiService.toggleActivoRecordatorio(titulo);
    } catch (e) {
      print('❌ Error en repositorio al cambiar estado: $e');
      rethrow;
    }
  }

  /// Valida los campos requeridos de un recordatorio
  void _validarRecordatorio(Recordatorio recordatorio) {
    if (recordatorio.titulo.isEmpty) {
      throw RecordatorioValidationException(
        'El título del recordatorio es obligatorio',
      );
    }

    if (recordatorio.idUsuario <= 0) {
      throw RecordatorioValidationException(
        'El ID del usuario es obligatorio y debe ser válido',
      );
    }

    // Validar que la fecha no sea muy antigua
    final ahora = DateTime.now();
    final hace1Anio = ahora.subtract(const Duration(days: 365));
    if (recordatorio.fechaHora.isBefore(hace1Anio)) {
      throw RecordatorioValidationException(
        'La fecha del recordatorio no puede ser de hace mas de un anio',
      );
    }

    // Validar repetitivo
    if (recordatorio.esRepetitivo &&
        (recordatorio.frecuenciaRepeticion == null ||
            recordatorio.frecuenciaRepeticion!.isEmpty)) {
      throw RecordatorioValidationException(
        'Si el recordatorio es repetitivo, debe especificar la frecuencia',
      );
    }
  }

  /// Prueba la conexión con el servidor
  Future<bool> probarConexion() async {
    try {
      return await RecordatorioApiService.testConnection();
    } catch (e) {
      print('❌ Error al probar conexión: $e');
      return false;
    }
  }
}
