import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';

/// Gestor centralizado de sesión del usuario
///
/// Singleton que permite acceder fácilmente a los datos del usuario
/// autenticado desde cualquier parte de la aplicación.
///
/// Uso básico:
/// ```dart
/// // Obtener el correo del usuario actual
/// final email = SessionManager.instance.userEmail;
///
/// // Verificar si hay sesión activa
/// if (SessionManager.instance.isLoggedIn) {
///   // Usuario autenticado
/// }
///
/// // Obtener todos los datos del usuario
/// final user = SessionManager.instance.currentUser;
/// ```
class SessionManager {
  // Singleton
  static final SessionManager _instance = SessionManager._internal();
  static SessionManager get instance => _instance;

  SessionManager._internal();

  // Estado de la sesión
  User? _currentUser;
  String? _userEmail;

  /// Usuario actualmente autenticado (null si no hay sesión)
  User? get currentUser => _currentUser;

  /// Correo del usuario actualmente autenticado
  ///
  /// Retorna null si no hay sesión activa.
  /// Este es el método más común para obtener el email del usuario.
  String? get userEmail => _userEmail ?? _currentUser?.email;

  /// Verifica si hay un usuario autenticado
  bool get isLoggedIn => _userEmail != null || _currentUser != null;

  /// ID del usuario (útil para operaciones con la API)
  int? get userId => _currentUser?.idUsuario;

  /// Nombre del usuario
  String? get userName => _currentUser?.nombreUsuario;

  /// Inicializar la sesión al iniciar la app
  ///
  /// Debe llamarse en `main()` o al inicio de la app para
  /// restaurar la sesión desde SharedPreferences.
  Future<void> initialize() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userData = prefs.getString('current_user');

      if (userData != null && userData.isNotEmpty) {
        final json = jsonDecode(userData);
        _currentUser = User.fromJson(json);
        _userEmail = _currentUser?.email;
        print('✅ Sesión restaurada: $_userEmail');
      } else {
        print('ℹ️ No hay sesión guardada');
      }
    } catch (e) {
      print('⚠️ Error al inicializar sesión: $e');
      await clearSession();
    }
  }

  /// Establecer la sesión del usuario después del login
  ///
  /// Guarda los datos del usuario tanto en memoria como en SharedPreferences.
  ///
  /// [userData] Map con los datos del usuario (generalmente viene del API)
  Future<void> setUserSession(Map<String, dynamic> userData) async {
    try {
      _currentUser = User.fromJson(userData);
      _userEmail = _currentUser?.email;

      // Guardar en SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('current_user', jsonEncode(userData));

      print('✅ Sesión establecida: $_userEmail');
    } catch (e) {
      print('❌ Error al establecer sesión: $e');
      rethrow;
    }
  }

  /// Establecer la sesión usando un objeto User directamente
  Future<void> setUser(User user) async {
    _currentUser = user;
    _userEmail = user.email;

    // Guardar en SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('current_user', jsonEncode(user.toJson()));

    print('✅ Sesión establecida: $_userEmail');
  }

  /// Actualizar solo el correo (útil en casos específicos)
  void updateEmail(String email) {
    _userEmail = email;
    if (_currentUser != null) {
      // Actualizar el usuario en memoria
      _currentUser = User(
        idUsuario: _currentUser!.idUsuario,
        nombreUsuario: _currentUser!.nombreUsuario,
        email: email,
        contrasenaHash: _currentUser!.contrasenaHash,
        fechaCreacionIso: _currentUser!.fechaCreacionIso,
        telefono: _currentUser!.telefono,
      );
    }
  }

  /// Cerrar sesión (logout)
  ///
  /// Limpia todos los datos del usuario tanto de memoria como de SharedPreferences.
  Future<void> clearSession() async {
    _currentUser = null;
    _userEmail = null;

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('current_user');

    print('✅ Sesión cerrada');
  }

  /// Refrescar sesión desde SharedPreferences
  ///
  /// Útil si los datos se actualizaron externamente.
  Future<void> refreshSession() async {
    await initialize();
  }

  /// Validar que hay una sesión activa
  ///
  /// Lanza una excepción si no hay usuario autenticado.
  /// Útil para métodos que requieren autenticación.
  String requireUserEmail() {
    if (!isLoggedIn) {
      throw Exception('No hay un usuario autenticado');
    }
    return userEmail!;
  }
}
