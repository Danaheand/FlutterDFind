import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  // Para desarrollo en web, usa un proxy local o la URL directa
  static const String baseUrl = 'https://dfindapi-yfcq.onrender.com/api';
  
  // Método para registrar usuario
  static Future<Map<String, dynamic>> registerUser({
    required String nombreUsuario,
    required String correo,
    required String contrasenaHash,
    required bool aceptoTerminos,
    required String versionTerminos,
    required String ipAceptacion,
  }) async {
    try {
      print('Enviando registro a: $baseUrl/Auth/register');
      print('Datos: nombreUsuario=$nombreUsuario, correo=$correo');
      
      final response = await http.post(
        Uri.parse('$baseUrl/Auth/register'),
        headers: {
          'Content-Type': 'application/json',
          'Access-Control-Allow-Origin': '*',  // Agregar esto
        },
        body: jsonEncode({
          'nombreUsuario': nombreUsuario,
          'correo': correo,
          'contrasenaHash': contrasenaHash,
          'aceptoTerminos': aceptoTerminos,
          'versionTerminos': versionTerminos,
          'ipAceptacion': ipAceptacion,
        }),
      );

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        return {
          'success': true,
          'data': jsonDecode(response.body),
        };
      } else {
        return {
          'success': false,
          'error': 'Error ${response.statusCode}: ${response.body}',
        };
      }
    } catch (e) {
      print('Error completo: $e');
      return {
        'success': false,
        'error': 'Error de conexión: $e',
      };
    }
  }

  // Método para login
  static Future<Map<String, dynamic>> loginUser({
    required String correo,
    required String contrasenaHash,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/Auth/login'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'correo': correo,
          'contrasenaHash': contrasenaHash,
        }),
      );

      print('Login Response Status: ${response.statusCode}');
      print('Login Response Body: ${response.body}');

      if (response.statusCode == 200) {
        return {
          'success': true,
          'data': jsonDecode(response.body),
        };
      } else {
        return {
          'success': false,
          'error': 'Error ${response.statusCode}: ${response.body}',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Error de conexión: $e',
      };
    }
  }

  // Método para obtener perfil por email
  static Future<Map<String, dynamic>> getUserProfile({
    required String correo,
  }) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/Auth/profile/by-email/$correo'),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      print('Profile Response Status: ${response.statusCode}');
      print('Profile Response Body: ${response.body}');

      if (response.statusCode == 200) {
        return {
          'success': true,
          'data': jsonDecode(response.body),
        };
      } else {
        return {
          'success': false,
          'error': 'Error ${response.statusCode}: ${response.body}',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Error de conexión: $e',
      };
    }
  }
}