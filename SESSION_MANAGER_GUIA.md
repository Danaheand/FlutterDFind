# 🔐 Sistema de Gestión de Sesión - SessionManager

## 📖 Resumen

El `SessionManager` es un **singleton** que centraliza la gestión de la sesión del usuario en toda la aplicación. Elimina la necesidad de pasar el correo del usuario manualmente o acceder repetidamente a `SharedPreferences`.

## ✨ Beneficios

- ✅ **Acceso simple**: Obtén el correo del usuario desde cualquier parte de la app con una línea
- ✅ **Centralizado**: Una única fuente de verdad para los datos del usuario
- ✅ **Automático**: Se inicializa al arrancar la app y persiste la sesión
- ✅ **Sincronizado**: Actualiza automáticamente `SharedPreferences` cuando cambias la sesión
- ✅ **Sin repetición**: No necesitas cargar el usuario desde `SharedPreferences` en cada pantalla

## 🚀 Uso Básico

### 1. Obtener el correo del usuario

```dart
// Antes (engorroso) ❌
final sp = await SharedPreferences.getInstance();
final userJson = sp.getString('current_user');
final userData = json.decode(userJson);
final email = userData['correo'];

// Ahora (simple) ✅
final email = SessionManager.instance.userEmail;
```

### 2. Obtener el usuario completo

```dart
// Obtener todo el objeto User
final user = SessionManager.instance.currentUser;

if (user != null) {
  print('Nombre: ${user.nombreUsuario}');
  print('Email: ${user.email}');
  print('ID: ${user.idUsuario}');
}
```

### 3. Verificar si hay sesión activa

```dart
if (SessionManager.instance.isLoggedIn) {
  // Usuario autenticado
  print('Bienvenido ${SessionManager.instance.userName}');
} else {
  // Redirigir al login
  Navigator.of(context).pushReplacementNamed('/login');
}
```

### 4. Establecer sesión después del login

```dart
// En login_screen.dart
final result = await ApiService.loginUser(
  correo: email,
  password: password,
);

if (result['success']) {
  // Guardar sesión (también guarda en SharedPreferences automáticamente)
  await SessionManager.instance.setUserSession(result['data']);
  
  Navigator.of(context).pushReplacementNamed('/main');
}
```

### 5. Cerrar sesión (logout)

```dart
// En perfil_screen.dart
Future<void> _logout() async {
  // Limpia todo (memoria y SharedPreferences)
  await SessionManager.instance.clearSession();
  
  Navigator.of(context).pushReplacementNamed('/login');
}
```

## 📱 Propiedades Disponibles

```dart
// Obtener el correo del usuario (más común)
String? email = SessionManager.instance.userEmail;

// Obtener el usuario completo
User? user = SessionManager.instance.currentUser;

// Verificar si está autenticado
bool isLoggedIn = SessionManager.instance.isLoggedIn;

// Obtener ID del usuario
int? userId = SessionManager.instance.userId;

// Obtener nombre del usuario
String? userName = SessionManager.instance.userName;
```

## 🔧 Métodos Disponibles

### `initialize()`
Inicializa el SessionManager cargando la sesión desde SharedPreferences.
**Debe llamarse en `main()` al iniciar la app.**

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Inicializar sesión
  await SessionManager.instance.initialize();
  
  runApp(const MyApp());
}
```

### `setUserSession(Map<String, dynamic> userData)`
Establece la sesión del usuario después del login.
Guarda automáticamente en SharedPreferences.

```dart
await SessionManager.instance.setUserSession(result['data']);
```

### `setUser(User user)`
Establece la sesión usando un objeto User directamente.

```dart
await SessionManager.instance.setUser(updatedUser);
```

### `clearSession()`
Cierra la sesión del usuario, limpiando memoria y SharedPreferences.

```dart
await SessionManager.instance.clearSession();
```

### `requireUserEmail()`
Obtiene el correo del usuario o lanza una excepción si no hay sesión.
Útil para métodos que requieren autenticación obligatoria.

```dart
try {
  final email = SessionManager.instance.requireUserEmail();
  // Usar el email con seguridad
} catch (e) {
  // No hay usuario autenticado
}
```

## 🎯 Integración con RecordatorioProvider

El `RecordatorioProvider` ahora usa el `SessionManager` automáticamente:

```dart
// Antes ❌
final provider = context.read<RecordatorioProvider>();
provider.setCorreoUsuario(email); // Tenías que pasar el email
await provider.cargarRecordatorios(correo: email); // Y pasarlo de nuevo

// Ahora ✅
final provider = context.read<RecordatorioProvider>();
await provider.cargarRecordatorios(); // Todo automático
```

El provider obtiene el email internamente desde el `SessionManager`:

```dart
String? get correoUsuario => SessionManager.instance.userEmail;
```

## 📝 Ejemplos de Uso en Pantallas

### En recordatorios_screen.dart

```dart
Future<void> _loadUserAndRecordatorios() async {
  // Obtener email desde SessionManager
  _userEmail = SessionManager.instance.userEmail;
  _userId = SessionManager.instance.userId;

  if (_userEmail != null && _userId != null && mounted) {
    final provider = context.read<RecordatorioProvider>();
    await provider.cargarRecordatorios(); // Ya no necesitas pasar el correo
  }
}
```

### En perfil_screen.dart

```dart
Future<void> _loadCurrentUser() async {
  // Obtener usuario desde SessionManager
  final user = SessionManager.instance.currentUser;
  
  if (user != null) {
    setState(() {
      _currentUser = user;
      _userName = user.nombreUsuario;
      _userEmail = user.email;
    });
  } else {
    // No hay sesión, redirigir al login
    Navigator.of(context).pushReplacementNamed('/login');
  }
}
```

### En cualquier widget

```dart
class MyWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // Acceso directo al email del usuario
    final email = SessionManager.instance.userEmail;
    
    return Text('Usuario: ${email ?? "No autenticado"}');
  }
}
```

## 🔄 Migración desde el Código Antiguo

### 1. Reemplazar SharedPreferences directas

**Antes:**
```dart
final sp = await SharedPreferences.getInstance();
final userJson = sp.getString('current_user');
if (userJson != null) {
  final userData = json.decode(userJson);
  final email = userData['correo'];
}
```

**Después:**
```dart
final email = SessionManager.instance.userEmail;
```

### 2. Reemplazar setCorreoUsuario en Provider

**Antes:**
```dart
provider.setCorreoUsuario(email);
await provider.cargarRecordatorios(correo: email);
```

**Después:**
```dart
await provider.cargarRecordatorios();
```

### 3. Reemplazar logout manual

**Antes:**
```dart
final sp = await SharedPreferences.getInstance();
await sp.remove('current_user');
```

**Después:**
```dart
await SessionManager.instance.clearSession();
```

## 🎨 Arquitectura

```
┌─────────────────────────────────────────┐
│          SessionManager                 │
│         (Singleton)                     │
│                                         │
│  • currentUser: User?                   │
│  • userEmail: String?                   │
│  • isLoggedIn: bool                     │
│                                         │
│  ↕️  Sincroniza con                     │
│  SharedPreferences                      │
└─────────────────────────────────────────┘
              ↑
              │ Acceso directo desde cualquier parte
              │
    ┌─────────┴─────────┬──────────────┐
    │                   │              │
┌───┴────┐      ┌───────┴──────┐   ┌──┴─────────┐
│Provider│      │ Screen       │   │  Widget    │
│        │      │              │   │            │
│ Auto   │      │ Fácil acceso │   │ Una línea  │
│ obtiene│      │ al usuario   │   │ de código  │
│ email  │      │              │   │            │
└────────┘      └──────────────┘   └────────────┘
```

## 🛡️ Ventajas de Seguridad

1. **Validación centralizada**: Un solo punto para verificar autenticación
2. **Manejo de errores consistente**: Comportamiento predecible en toda la app
3. **Fácil de debuggear**: Todos los cambios de sesión pasan por el mismo lugar
4. **Logs centralizados**: Fácil seguimiento de login/logout

## 📦 Archivo de Implementación

El código completo está en: `lib/services/session_manager.dart`

## 🔍 Debugging

Para ver qué está pasando con la sesión:

```dart
print('Usuario actual: ${SessionManager.instance.currentUser?.nombreUsuario}');
print('Email: ${SessionManager.instance.userEmail}');
print('¿Autenticado?: ${SessionManager.instance.isLoggedIn}');
```

## ⚠️ Consideraciones Importantes

1. **Siempre inicializar en main()**: El SessionManager debe inicializarse antes de usar la app
2. **No modificar SharedPreferences directamente**: Usa siempre los métodos del SessionManager
3. **Thread-safe**: El singleton es seguro para usar desde múltiples lugares simultáneamente
4. **Persistencia**: Los cambios se guardan automáticamente en SharedPreferences

## 🎓 Conclusión

El `SessionManager` simplifica radicalmente el manejo de la sesión del usuario. Ya no necesitas:
- ❌ Pasar el correo como parámetro por todas partes
- ❌ Acceder manualmente a SharedPreferences en cada pantalla
- ❌ Decodificar JSON repetidamente
- ❌ Mantener el estado del usuario sincronizado en múltiples lugares

Todo está centralizado, automático y accesible con una sola línea de código. 🎉
