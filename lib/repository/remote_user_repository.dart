// lib/repository/remote_user_repository.dart
import 'dart:convert';
import 'package:http/http.dart' as http;


import '../models/user.dart';

class RemoteUserRepository {
  final String _baseUrl = 'https://dfindapi-yfcq.onrender.com'; // o la que ya usas

  RemoteUserRepository._internal();

  static final RemoteUserRepository instance = RemoteUserRepository._internal();


  Uri _uri(String path) => Uri.parse('$_baseUrl$path');

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
  Future<User> getUserProfile({
    required String email,
  }) async {
    final url = _uri('/api/Auth/profile/by-email/$email');

    print('GET $url');

    final resp = await http.get(
      url,
      headers: {
        'Content-Type': 'application/json',
      },
    );

    print('Resp status: ${resp.statusCode}');
    print('Resp body: ${resp.body}');

    if (resp.statusCode == 200) {
      final data = jsonDecode(resp.body) as Map<String, dynamic>;
      return User.fromJson(data);
    } else {
      throw Exception(
        'Error obteniendo perfil: ${resp.statusCode} - ${resp.body}',
      );
    }
  }

  Future<User> updateProfileByEmail({
    required String correoActual,
    String? nuevoNombre,
    String? nuevoCorreo,
    String? avatarTipo,
    String? avatarClave,
  }) async {
    final url = _uri('/api/Users/profile');
    
    // Construir body solo con los campos que se van a cambiar
    final body = <String, dynamic>{
      'correo': correoActual, // Siempre necesario para identificar al usuario
    };
    
    // Agregar solo los campos que cambiarán
    if (nuevoNombre != null) body['nombreUsuario'] = nuevoNombre;
    if (nuevoCorreo != null) body['nuevoCorreo'] = nuevoCorreo;
    if (avatarTipo != null) {
      body['avatarTipo'] = avatarTipo;
      print('🎨 Avatar Tipo a guardar: $avatarTipo');
    }
    if (avatarClave != null) {
      body['avatarClave'] = avatarClave;
      print('🎨 Avatar Clave a guardar: $avatarClave');
    }

    print('PUT $url');
    print('Body: ${jsonEncode(body)}');

    final response = await http.put(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );

    print('Resp status: ${response.statusCode}');
    print('Resp body: ${response.body}');

    if (response.statusCode == 200 || response.statusCode == 204) {
      // Si el servidor devuelve JSON, parsearlo. Si no (204), hacer GET para obtener el usuario actualizado
      if (response.body.isNotEmpty) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        print('🎨 Usuario actualizado desde response: $data');
        return User.fromJson(data);
      } else {
        // Status 204: obtener el usuario con el correo actualizado
        // Si cambió el correo, usar el nuevo. Si no, usar el actual
        final emailActualizado = nuevoCorreo ?? correoActual;
        
        // Esperar un poco antes de hacer el GET para que el servidor procese el cambio
        await Future.delayed(const Duration(milliseconds: 500));
        
        print('🎨 Obteniendo usuario actualizado con email: $emailActualizado');
        return getUserProfile(email: emailActualizado);
      }
    } else {
      throw Exception('Error actualizando perfil: ${response.body}');
    }
  }
}