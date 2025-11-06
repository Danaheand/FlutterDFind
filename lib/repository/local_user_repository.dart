import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';

class LocalUserRepository {
  LocalUserRepository._();
  static final LocalUserRepository instance = LocalUserRepository._();

  static const _kUsersStorageKey = 'users_v1';
  static const _kLegacyKey =
      'demo_users_v1'; // antigua key usada en register_screen.dart

  Future<List<User>> _loadRaw() async {
    final sp = await SharedPreferences.getInstance();
    String? jsonStr = sp.getString(_kUsersStorageKey);
    if (jsonStr == null) return [];

    try {
      final list = jsonDecode(jsonStr) as List<dynamic>;
      return list
          .map((e) => User.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    } catch (e) {
      return [];
    }
  }

  Future<void> _saveRaw(List<User> users) async {
    final sp = await SharedPreferences.getInstance();
    await sp.setString(
        _kUsersStorageKey, jsonEncode(users.map((u) => u.toJson()).toList()));
  }

  Future<List<User>> getAll() => _loadRaw();

  Future<User?> findByEmail(String email) async {
    final q = email.trim().toLowerCase();
    final all = await _loadRaw();
    try {
      return all.firstWhere((u) => u.email.trim().toLowerCase() == q);
    } catch (_) {
      return null;
    }
  }

  Future<int> _nextId() async {
    final all = await _loadRaw();
    if (all.isEmpty) return 1;
    return all.map((u) => u.idUsuario).reduce((a, b) => a > b ? a : b) + 1;
  }

  Future<User> addUser({
    required String nombreUsuario,
    required String email,
    required String contrasenaHash,
  }) async {
    final id = await _nextId();
    final now = DateTime.now().toUtc().toIso8601String();
    final user = User(
      idUsuario: id,
      nombreUsuario: nombreUsuario,
      email: email.trim(),
      contrasenaHash: contrasenaHash,
      fechaCreacionIso: now,
    );
    final all = await _loadRaw();
    all.add(user);
    await _saveRaw(all);
    return user;
  }

  static const _testUser = {
    'id_usuario': 999,
    'nombre_usuario': 'Usuario Demo',
    'email': 'demo@dfind.com',
    'contrasena_hash':
        'a665a45920422f9d417e4867efdc4fb8a04a1f3fff1fa07e998e86f7f7a27ae3', // contraseña: '123'
    'fecha_creacion': '2023-01-01T00:00:00.000Z'
  };

  Future<void> ensureTestUser() async {
    final users = await _loadRaw();
    final testExists = users.any((u) => u.email == _testUser['email']);
    if (!testExists) {
      users.add(User.fromJson(_testUser));
      await _saveRaw(users);
    }
  }

  Future<void> clearAll() async {
    final sp = await SharedPreferences.getInstance();
    await sp.remove(_kUsersStorageKey);
    await ensureTestUser(); // Restaura el usuario de prueba después de limpiar
  }

  // Llamar esto al iniciar la app
  Future<void> init() async {
    await ensureTestUser();
  }
}
