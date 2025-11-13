import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:crypto/crypto.dart';

class ApiService {
  static const String baseUrl = 'https://dfindapi-yfcq.onrender.com/api';
  static const Duration timeout = Duration(seconds: 30);
  
  // Método para hacer hash SHA256
  static String _sha256Hash(String input) {
    final bytes = utf8.encode(input);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }
  
  // Método para registrar usuario
  static Future<Map<String, dynamic>> registerUser({
    required String nombreUsuario,
    required String correo,
    required String password, // Cambiado: recibimos password, no hash
    required bool aceptoTerminos,
    required String versionTerminos,
    required String ipAceptacion,
  }) async {
    try {
      print('🚀 Intentando registro...');
      print('📧 Email: $correo');
      print('👤 Nombre: $nombreUsuario');
      print('🌐 URL: $baseUrl/Auth/register');
      
      // Crear el hash aquí
      final contrasenaHash = _sha256Hash(password);
      print('🔒 Hash generado: ${contrasenaHash.substring(0, 10)}...');
      
      final requestBody = {
        'nombreUsuario': nombreUsuario,
        'correo': correo,
        'contrasenaHash': contrasenaHash,
        'aceptoTerminos': aceptoTerminos,
        'versionTerminos': versionTerminos,
        'ipAceptacion': ipAceptacion,
      };
      
      print('📦 Request body: ${jsonEncode(requestBody)}');
      
      final response = await http.post(
        Uri.parse('$baseUrl/Auth/register'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode(requestBody),
      ).timeout(timeout);

      print('📨 Status: ${response.statusCode}');
      print('📄 Response: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = jsonDecode(response.body);
        return {
          'success': true,
          'data': responseData,
          'message': 'Usuario registrado correctamente',
        };
      } else {
        String errorMessage = 'Error del servidor';
        try {
          final errorData = jsonDecode(response.body);
          errorMessage = errorData['message'] ?? errorData.toString();
        } catch (e) {
          errorMessage = 'Error ${response.statusCode}: ${response.body}';
        }
        
        return {
          'success': false,
          'error': errorMessage,
        };
      }
    } catch (e) {
      print('❌ Error completo: $e');
      return {
        'success': false,
        'error': 'Error de conexión: $e',
      };
    }
  }

  // Método para login
  static Future<Map<String, dynamic>> loginUser({
    required String correo,
    required String password, // Cambiado: recibimos password, no hash
  }) async {
    try {
      print('🔐 Intentando login...');
      print('📧 Email: $correo');
      print('🌐 URL: $baseUrl/Auth/login');
      
      // Crear el hash aquí igual que en registro
      final contrasenaHash = _sha256Hash(password);
      print('🔒 Hash para login: ${contrasenaHash.substring(0, 10)}...');
      
      final requestBody = {
        'correo': correo,
        'contrasenaHash': contrasenaHash,
      };
      
      print('📦 Login body: ${jsonEncode(requestBody)}');
      
      final response = await http.post(
        Uri.parse('$baseUrl/Auth/login'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode(requestBody),
      ).timeout(timeout);

      print('📨 Status: ${response.statusCode}');
      print('📄 Response: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        return {
          'success': true,
          'data': responseData,
          'message': 'Login exitoso',
        };
      } else {
        String errorMessage = 'Credenciales incorrectas';
        try {
          final errorData = jsonDecode(response.body);
          errorMessage = errorData['message'] ?? 'Credenciales incorrectas o error del servidor';
        } catch (e) {
          errorMessage = 'Error ${response.statusCode}: Usuario o contraseña incorrectos';
        }
        
        return {
          'success': false,
          'error': errorMessage,
        };
      }
    } catch (e) {
      print('❌ Error login: $e');
      return {
        'success': false,
        'error': 'Error de conexión: $e',
      };
    }
  }

  // Método para obtener perfil
  static Future<Map<String, dynamic>> getUserProfile({
    required String correo,
  }) async {
    try {
      print('👤 Obteniendo perfil...');
      print('📧 Email: $correo');
      
      final response = await http.get(
        Uri.parse('$baseUrl/Auth/profile/by-email/$correo'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ).timeout(timeout);

      print('📨 Status: ${response.statusCode}');
      print('📄 Response: ${response.body}');

      if (response.statusCode == 200) {
        return {
          'success': true,
          'data': jsonDecode(response.body),
        };
      } else {
        return {
          'success': false,
          'error': 'Error obteniendo perfil: ${response.statusCode}',
        };
      }
    } catch (e) {
      print('❌ Error perfil: $e');
      return {
        'success': false,
        'error': 'Error de conexión: $e',
      };
    }
  }

  // Método para probar conectividad
  static Future<bool> testConnection() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/Auth/register'),
        headers: {'Accept': 'application/json'},
      ).timeout(const Duration(seconds: 10));
      
      print('🌐 Test conexión: ${response.statusCode}');
      return response.statusCode == 405 || response.statusCode == 200; // 405 es normal para GET en POST endpoint
    } catch (e) {
      print('❌ Test conexión falló: $e');
      return false;
    }
  }
}