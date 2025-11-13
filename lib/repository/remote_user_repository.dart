// lib/repository/remote_user_repository.dart
import 'dart:convert';
import 'package:http/http.dart' as http;

import '../models/user.dart';

class RemoteUserRepository {
  RemoteUserRepository._internal();

  /// Singleton
  static final RemoteUserRepository instance = RemoteUserRepository._internal();

  /// ⚠️ Cambia esta URL por la de tu API en Render (sin / al final)
  static const String _baseUrl = 'https://dfindapi-yfcq.onrender.com';

  Uri _uri(String path) => Uri.parse('$_baseUrl$path');

  // ======================
  // LOGIN
  // ======================
  Future<User> login({
    required String email,
    required String contrasenaHash,
  }) async {
    final url = _uri('/api/Auth/login');

    final bodyMap = {
      "correo": email,
      "contrasenaHash": contrasenaHash,
    };

    final bodyJson = jsonEncode(bodyMap);

    // Logs para depurar
    print('POST $url');
    print('Body: $bodyJson');

    final resp = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
      },
      body: bodyJson,
    );

    print('Resp status: ${resp.statusCode}');
    print('Resp body: ${resp.body}');

    if (resp.statusCode == 200) {
      final data = jsonDecode(resp.body) as Map<String, dynamic>;
      return User.fromJson(data);
    } else {
      throw Exception(
        'Error de login: ${resp.statusCode} - ${resp.body}',
      );
    }
  }

  // ======================
  // REGISTRO
  // ======================
  Future<User> register({
    required String nombreUsuario,
    required String email,
    required String contrasenaHash,
    bool aceptoTerminos = true,
    String versionTerminos = '1.0',
    String? ipAceptacion,
  }) async {
    final url = _uri('/api/Auth/register');

    final bodyMap = {
      "nombreUsuario": nombreUsuario,
      "correo": email,
      "contrasenaHash": contrasenaHash,
      "aceptoTerminos": aceptoTerminos,
      "versionTerminos": versionTerminos,
      "ipAceptacion": ipAceptacion,
    };

    final bodyJson = jsonEncode(bodyMap);

    print('POST $url');
    print('Body: $bodyJson');

    final resp = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
      },
      body: bodyJson,
    );

    print('Resp status: ${resp.statusCode}');
    print('Resp body: ${resp.body}');

    if (resp.statusCode == 200) {
      final data = jsonDecode(resp.body) as Map<String, dynamic>;
      return User.fromJson(data);
    } else {
      throw Exception(
        'Error de registro: ${resp.statusCode} - ${resp.body}',
      );
    }
  }

  // ======================
  // ACTUALIZAR PERFIL POR CORREO
  // ======================
  Future<User> updateProfileByEmail({
    required String correoActual,
    String? nuevoNombre,
    String? nuevoCorreo,
  }) async {
    final url = _uri('/api/Auth/profile/by-email/$correoActual');

    final bodyMap = {
      "nombreUsuario": nuevoNombre,
      "correo": nuevoCorreo,
    };

    final bodyJson = jsonEncode(bodyMap);

    print('PUT $url');
    print('Body: $bodyJson');

    final resp = await http.put(
      url,
      headers: {
        'Content-Type': 'application/json',
      },
      body: bodyJson,
    );

    print('Resp status: ${resp.statusCode}');
    print('Resp body: ${resp.body}');

    if (resp.statusCode == 200) {
      final data = jsonDecode(resp.body) as Map<String, dynamic>;
      return User.fromJson(data);
    } else {
      throw Exception(
        'Error al actualizar perfil: ${resp.statusCode} - ${resp.body}',
      );
    }
  }
}
