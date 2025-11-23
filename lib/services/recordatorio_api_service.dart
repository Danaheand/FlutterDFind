import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/recordatorio.dart';
import '../models/recordatorio_exception.dart';

/// Servicio para las operaciones de API relacionadas con recordatorios
/// Maneja todas las peticiones HTTP a los endpoints de recordatorios
class RecordatorioApiService {
  static const String baseUrl = 'https://dfindapi-yfcq.onrender.com/api';
  static const Duration timeout = Duration(seconds: 30);

  /// Headers comunes para todas las peticiones
  static Map<String, String> get _headers => {
        'Content-Type': 'application/json; charset=UTF-8',
        'Accept': 'application/json',
      };

  /// 1️⃣ GET - Obtener todos los recordatorios de un usuario por correo
  ///
  /// Endpoint: GET /api/Recordatorios/usuario-por-correo?correo={correo}
  ///
  /// Uso:
  /// - Cuando abre la app
  /// - Cuando recarga la pantalla de recordatorios
  /// - Para mostrar la lista completa de recordatorios
  ///
  /// Retorna: Lista de recordatorios del usuario
  /// Lanza: RecordatorioException en caso de error
  static Future<List<Recordatorio>> obtenerRecordatoriosPorCorreo(
    String correo,
  ) async {
    try {
      print('📋 Obteniendo recordatorios para correo: $correo');

      final uri = Uri.parse('$baseUrl/Recordatorios/usuario-por-correo')
          .replace(queryParameters: {'correo': correo});

      print('🌐 URL: $uri');

      final response = await http.get(uri, headers: _headers).timeout(timeout);

      print('📨 Status: ${response.statusCode}');
      print('📄 Response: ${response.body}');

      if (response.statusCode == 200) {
        final List<dynamic> jsonList = jsonDecode(response.body);
        final recordatorios =
            jsonList.map((json) => Recordatorio.fromJson(json)).toList();

        print('✅ ${recordatorios.length} recordatorios obtenidos');
        return recordatorios;
      } else if (response.statusCode == 404) {
        // No hay recordatorios, retornar lista vacía
        print('ℹ️ No se encontraron recordatorios para el usuario');
        return [];
      } else if (response.statusCode >= 500) {
        throw RecordatorioServerException(
          'Error del servidor al obtener recordatorios',
          response.statusCode,
        );
      } else {
        // Error del cliente (400, 401, etc.)
        String errorMessage = 'Error al obtener recordatorios';
        try {
          final errorData = jsonDecode(response.body);
          errorMessage = errorData['message'] ?? errorMessage;
        } catch (_) {
          errorMessage = 'Error ${response.statusCode}: ${response.body}';
        }
        throw RecordatorioClientException(errorMessage, response.statusCode);
      }
    } on RecordatorioException {
      rethrow; // Re-lanzar nuestras excepciones personalizadas
    } catch (e) {
      print('❌ Error de red: $e');
      throw RecordatorioNetworkException(
        'Error de conexión al obtener recordatorios: ${e.toString()}',
        originalError: e,
      );
    }
  }

  /// 2️⃣ POST - Crear un nuevo recordatorio
  ///
  /// Endpoint: POST /api/Recordatorios
  ///
  /// Uso:
  /// - Cuando el usuario presiona el botón "+" o "Crear recordatorio"
  /// - Después de llenar el formulario y presionar "Guardar"
  ///
  /// Retorna: El recordatorio creado con datos del servidor
  /// Lanza: RecordatorioException en caso de error
  static Future<Recordatorio> crearRecordatorio(
    Recordatorio recordatorio,
  ) async {
    try {
      print('➕ Creando recordatorio: ${recordatorio.titulo}');

      final requestBody = recordatorio.toJson();
      print('📦 Request body: ${jsonEncode(requestBody)}');

      final response = await http
          .post(
            Uri.parse('$baseUrl/Recordatorios'),
            headers: _headers,
            body: jsonEncode(requestBody),
          )
          .timeout(timeout);

      print('📨 Status: ${response.statusCode}');
      print('📄 Response: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = jsonDecode(response.body);
        final recordatorioCreado = Recordatorio.fromJson(responseData);

        print('✅ Recordatorio creado exitosamente');
        return recordatorioCreado;
      } else if (response.statusCode >= 500) {
        throw RecordatorioServerException(
          'Error del servidor al crear recordatorio',
          response.statusCode,
        );
      } else if (response.statusCode == 400) {
        String errorMessage = 'Datos inválidos para crear recordatorio';
        try {
          final errorData = jsonDecode(response.body);
          errorMessage = errorData['message'] ?? errorMessage;
        } catch (_) {}
        throw RecordatorioValidationException(errorMessage);
      } else {
        String errorMessage = 'Error al crear recordatorio';
        try {
          final errorData = jsonDecode(response.body);
          errorMessage = errorData['message'] ?? errorMessage;
        } catch (_) {
          errorMessage = 'Error ${response.statusCode}: ${response.body}';
        }
        throw RecordatorioClientException(errorMessage, response.statusCode);
      }
    } on RecordatorioException {
      rethrow;
    } catch (e) {
      print('❌ Error de red: $e');
      throw RecordatorioNetworkException(
        'Error de conexión al crear recordatorio: ${e.toString()}',
        originalError: e,
      );
    }
  }

  /// 3️⃣ PUT - Actualizar/editar un recordatorio existente
  ///
  /// Endpoint: PUT /api/Recordatorios/titulo/{titulo}
  ///
  /// Uso:
  /// - Cuando el usuario presiona "Editar" en un recordatorio
  /// - Después de cambiar los datos y presionar "Guardar cambios"
  /// - Por ejemplo: cambiar la hora de "9:00 AM" a "10:00 AM"
  ///
  /// Retorna: El recordatorio actualizado
  /// Lanza: RecordatorioException en caso de error
  static Future<Recordatorio> actualizarRecordatorio(
    String tituloOriginal,
    Recordatorio recordatorio,
  ) async {
    try {
      print('📝 Actualizando recordatorio: $tituloOriginal');

      // Codificar el título para la URL (por si tiene espacios o caracteres especiales)
      final tituloEncoded = Uri.encodeComponent(tituloOriginal);
      final url = '$baseUrl/Recordatorios/titulo/$tituloEncoded';

      final requestBody = recordatorio.toJson();
      print('📦 Request body: ${jsonEncode(requestBody)}');
      print('🌐 URL: $url');

      final response = await http
          .put(
            Uri.parse(url),
            headers: _headers,
            body: jsonEncode(requestBody),
          )
          .timeout(timeout);

      print('📨 Status: ${response.statusCode}');
      print('📄 Response: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        final recordatorioActualizado = Recordatorio.fromJson(responseData);

        print('✅ Recordatorio actualizado exitosamente');
        return recordatorioActualizado;
      } else if (response.statusCode == 404) {
        throw RecordatorioNotFoundException(tituloOriginal);
      } else if (response.statusCode >= 500) {
        throw RecordatorioServerException(
          'Error del servidor al actualizar recordatorio',
          response.statusCode,
        );
      } else if (response.statusCode == 400) {
        String errorMessage = 'Datos inválidos para actualizar recordatorio';
        try {
          final errorData = jsonDecode(response.body);
          errorMessage = errorData['message'] ?? errorMessage;
        } catch (_) {}
        throw RecordatorioValidationException(errorMessage);
      } else {
        String errorMessage = 'Error al actualizar recordatorio';
        try {
          final errorData = jsonDecode(response.body);
          errorMessage = errorData['message'] ?? errorMessage;
        } catch (_) {
          errorMessage = 'Error ${response.statusCode}: ${response.body}';
        }
        throw RecordatorioClientException(errorMessage, response.statusCode);
      }
    } on RecordatorioException {
      rethrow;
    } catch (e) {
      print('❌ Error de red: $e');
      throw RecordatorioNetworkException(
        'Error de conexión al actualizar recordatorio: ${e.toString()}',
        originalError: e,
      );
    }
  }

  /// 4️⃣ DELETE - Eliminar un recordatorio por título
  ///
  /// Endpoint: DELETE /api/Recordatorios/titulo/{titulo}
  ///
  /// Uso:
  /// - Cuando el usuario presiona "Eliminar" en un recordatorio
  /// - Después de confirmar "¿Estás seguro de que quieres eliminar?"
  ///
  /// Retorna: true si se eliminó correctamente
  /// Lanza: RecordatorioException en caso de error
  static Future<bool> eliminarRecordatorio(String titulo, String correo) async {
    try {
      print('🗑️ Eliminando recordatorio por título: $titulo');

      final tituloEncoded = Uri.encodeComponent(titulo);
      final url = '$baseUrl/Recordatorios/mover-a-papelera';

      print('🌐 URL: $url');
      final requestBody =
          jsonEncode({'titulo': titulo, "correoUsuario": correo});
      print('📦 Request body: $requestBody');
      final response = await http
          .delete(Uri.parse(url), headers: _headers, body: requestBody)
          .timeout(timeout);

      print('📨 Status: ${response.statusCode}');
      print('📄 Response: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 204) {
        print('✅ Recordatorio eliminado exitosamente');
        return true;
      } else if (response.statusCode == 404) {
        print('❌ Recordatorio no encontrado para eliminar: $titulo ');
        throw RecordatorioNotFoundException(titulo);
      } else if (response.statusCode >= 500) {
        throw RecordatorioServerException(
          'Error del servidor al eliminar recordatorio',
          response.statusCode,
        );
      } else {
        String errorMessage = 'Error al eliminar recordatorio';
        try {
          final errorData = jsonDecode(response.body);
          errorMessage = errorData['message'] ?? errorMessage;
        } catch (_) {
          errorMessage = 'Error ${response.statusCode}: ${response.body}';
        }
        throw RecordatorioClientException(errorMessage, response.statusCode);
      }
    } on RecordatorioException catch (e) {
      print('❌ Error de recordatorio: $e');
      rethrow;
    } catch (e) {
      print('❌ Error de red: $e');
      throw RecordatorioNetworkException(
        'Error de conexión al eliminar recordatorio: ${e.toString()}',
        originalError: e,
      );
    }
  }

  /// 5️⃣ PATCH - Alternar estado activo/inactivo de un recordatorio
  ///
  /// Endpoint: PATCH /api/Recordatorios/titulo/{titulo}/toggle-activo
  ///
  /// Uso:
  /// - Cuando el usuario presiona el botón de pausa/play
  /// - Si está ACTIVO → lo pone INACTIVO (pausado)
  /// - Si está INACTIVO → lo pone ACTIVO (reanudado)
  ///
  /// Retorna: El recordatorio con el estado actualizado
  /// Lanza: RecordatorioException en caso de error
  static Future<Recordatorio> toggleActivoRecordatorio(String titulo) async {
    try {
      print('🔄 Cambiando estado del recordatorio: $titulo');

      final tituloEncoded = Uri.encodeComponent(titulo);
      final url = '$baseUrl/Recordatorios/titulo/$tituloEncoded/toggle-activo';

      print('🌐 URL: $url');

      final response =
          await http.patch(Uri.parse(url), headers: _headers).timeout(timeout);

      print('📨 Status: ${response.statusCode}');
      print('📄 Response: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        final recordatorioActualizado = Recordatorio.fromJson(responseData);

        print('✅ Estado cambiado: activo=${recordatorioActualizado.activo}');
        return recordatorioActualizado;
      } else if (response.statusCode == 404) {
        throw RecordatorioNotFoundException(titulo);
      } else if (response.statusCode >= 500) {
        throw RecordatorioServerException(
          'Error del servidor al cambiar estado del recordatorio',
          response.statusCode,
        );
      } else {
        String errorMessage = 'Error al cambiar estado del recordatorio';
        try {
          final errorData = jsonDecode(response.body);
          errorMessage = errorData['message'] ?? errorMessage;
        } catch (_) {
          errorMessage = 'Error ${response.statusCode}: ${response.body}';
        }
        throw RecordatorioClientException(errorMessage, response.statusCode);
      }
    } on RecordatorioException {
      rethrow;
    } catch (e) {
      print('❌ Error de red: $e');
      throw RecordatorioNetworkException(
        'Error de conexión al cambiar estado del recordatorio: ${e.toString()}',
        originalError: e,
      );
    }
  }

  /// 🔧 Método auxiliar para probar la conexión con el servidor
  static Future<bool> testConnection() async {
    try {
      final response = await http
          .get(
            Uri.parse('$baseUrl/Recordatorios/usuario-por-correo?correo=test'),
            headers: _headers,
          )
          .timeout(const Duration(seconds: 10));

      print('🌐 Test conexión recordatorios: ${response.statusCode}');
      // 200, 404 o 400 indican que el servidor responde
      return response.statusCode >= 200 && response.statusCode < 600;
    } catch (e) {
      print('❌ Test conexión falló: $e');
      return false;
    }
  }
}
