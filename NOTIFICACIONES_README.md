# 🔔 Sistema de Notificaciones Push en DFind

## 📱 Funcionamiento

El sistema de notificaciones push está completamente implementado y funciona **incluso cuando la app está cerrada**. Las notificaciones se programan automáticamente cuando se crean o modifican recordatorios.

## ✨ Características Principales

### 1. **Notificaciones Automáticas**
- ✅ Se programan automáticamente al crear un recordatorio
- ✅ Se actualizan al modificar un recordatorio
- ✅ Se cancelan al eliminar un recordatorio
- ✅ Se gestionan al pausar/activar recordatorios

### 2. **Notificaciones en Background**
- ✅ Funcionan incluso con la app cerrada
- ✅ Verificación periódica cada 15 minutos
- ✅ Sincronización automática con el servidor
- ✅ Persistencia después de reiniciar el dispositivo

### 3. **Tipos de Notificaciones**

#### Notificación Principal
- Se muestra a la hora exacta programada
- Incluye título, descripción, ubicación y objeto
- Prioridad visual según importancia del recordatorio

#### Notificación Previa (5 minutos antes)
- Alerta 5 minutos antes de cada recordatorio
- Ayuda a prepararse para la tarea

#### Notificaciones Repetitivas
- Para recordatorios recurrentes
- Se programan automáticamente según los días seleccionados
- Se repiten semanalmente

### 4. **Indicadores de Prioridad**
- 🔴 **Alta**: Notificaciones urgentes
- 🟡 **Media**: Notificaciones normales
- 🟢 **Baja**: Notificaciones informativas

## 🔧 Componentes del Sistema

### 1. **BackgroundNotificationService**
```dart
lib/services/background_notification_service.dart
```

**Funciones principales:**
- `initialize()`: Inicia el servicio y la verificación periódica
- `checkAndScheduleNotifications()`: Verifica y programa notificaciones cada 15 min
- `scheduleNotificationForRecordatorio()`: Programa notificación para un recordatorio
- `cancelNotificationForRecordatorio()`: Cancela notificación de un recordatorio
- `cancelAllNotifications()`: Cancela todas las notificaciones
- `getPendingNotificationsCount()`: Obtiene cantidad de notificaciones pendientes

### 2. **NotificationService**
```dart
lib/services/notification_service.dart
```

**Funciones principales:**
- `initialize()`: Inicializa el sistema de notificaciones locales
- `scheduleAlarmNotification()`: Programa una notificación única
- `scheduleRepeatingAlarmNotification()`: Programa notificaciones repetitivas
- `cancelNotification()`: Cancela una notificación específica

### 3. **RecordatorioProvider (Integración)**
```dart
lib/providers/recordatorio_provider.dart
```

**Integración automática:**
- Al crear recordatorio → programa notificación
- Al actualizar recordatorio → reprograma notificación
- Al eliminar recordatorio → cancela notificación
- Al cambiar estado activo/inactivo → gestiona notificación
- Al cerrar sesión → cancela todas las notificaciones

## 📋 Permisos Configurados (Android)

```xml
<uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED"/>
<uses-permission android:name="android.permission.VIBRATE" />
<uses-permission android:name="android.permission.USE_EXACT_ALARM" />
<uses-permission android:name="android.permission.SCHEDULE_EXACT_ALARM" />
<uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>
<uses-permission android:name="android.permission.WAKE_LOCK" />
<uses-permission android:name="android.permission.FOREGROUND_SERVICE" />
```

### Receivers Configurados
- `ScheduledNotificationBootReceiver`: Restaura notificaciones después de reiniciar
- `ScheduledNotificationReceiver`: Gestiona las notificaciones programadas

## 🚀 Uso Automático

No necesitas hacer nada especial. El sistema funciona automáticamente:

```dart
// Al crear un recordatorio
await provider.crearRecordatorio(nuevoRecordatorio);
// → Automáticamente programa la notificación

// Al actualizar un recordatorio
await provider.actualizarRecordatorio(titulo, recordatorioActualizado);
// → Automáticamente actualiza la notificación

// Al eliminar un recordatorio
await provider.eliminarRecordatorio(titulo);
// → Automáticamente cancela la notificación
```

## 📊 Verificación de Notificaciones Pendientes

```dart
final service = BackgroundNotificationService();
final count = await service.getPendingNotificationsCount();
print('Notificaciones pendientes: $count');
```

## 🔄 Comportamiento del Sistema

### Al Iniciar la App
1. Se inicializa el `NotificationService`
2. Se inicializa el `BackgroundNotificationService`
3. Se verifica inmediatamente si hay notificaciones que programar
4. Se inicia la verificación periódica cada 15 minutos

### Durante el Uso
1. Cada operación CRUD actualiza automáticamente las notificaciones
2. No se requiere intervención manual
3. Las notificaciones persisten en el sistema operativo

### Con la App Cerrada
1. El sistema operativo mantiene las notificaciones programadas
2. Se muestran en el momento exacto configurado
3. Incluyen vibración y sonido de alarma
4. Se muestran en pantalla completa para alarmas importantes

### Después de Reiniciar el Dispositivo
1. El `BootReceiver` restaura las notificaciones automáticamente
2. No se pierde ninguna notificación programada

## 🎨 Personalización de Notificaciones

### Sonido y Vibración
```dart
// Android
sound: RawResourceAndroidNotificationSound('alarm_sound')
vibrationPattern: [0, 1000, 500, 1000]

// iOS
sound: 'alarm_sound.caf'
interruptionLevel: InterruptionLevel.critical
```

### Prioridad
```dart
importance: Importance.max
priority: Priority.high
fullScreenIntent: true // Pantalla completa para alarmas
```

## ⚙️ Configuración Periódica

El servicio verifica automáticamente cada **15 minutos** si hay nuevos recordatorios que programar o cambios en los existentes.

```dart
Timer.periodic(
  const Duration(minutes: 15),
  (_) => checkAndScheduleNotifications(),
);
```

## 🧪 Pruebas

Para probar el sistema de notificaciones:

```dart
// Probar notificación inmediata (en 3 segundos)
await NotificationService().testNotification();
```

## 📱 Compatibilidad

- ✅ **Android 6.0+**: Totalmente funcional
- ✅ **Android 12+**: Soporte para alarmas exactas
- ✅ **Android 13+**: Soporte para notificaciones con permiso
- ✅ **iOS 10+**: Totalmente funcional
- ⚠️ **Web**: No soportado (requiere notificaciones nativas del SO)

## 🔍 Debugging

Para ver los logs del sistema de notificaciones:

```dart
// Verificación periódica
🔔 Verificando recordatorios para programar notificaciones...
✅ X notificaciones programadas

// Al crear recordatorio
✅ Notificación programada para "Título del recordatorio"

// Al cancelar
✅ Notificación cancelada para "Título del recordatorio"

// Estado del servicio
✅ BackgroundNotificationService inicializado
🛑 BackgroundNotificationService detenido
```

## 📝 Notas Importantes

1. **Primera Vez**: Al iniciar la app por primera vez, se solicitarán permisos de notificaciones
2. **Permisos Exactos**: En Android 12+, se puede requerir permiso adicional para alarmas exactas
3. **Batería**: El sistema está optimizado para no consumir batería excesiva
4. **Sincronización**: El servicio sincroniza con el servidor cada 15 minutos
5. **Persistencia**: Las notificaciones persisten incluso después de reiniciar el dispositivo

## 🎯 Ventajas del Sistema

- ✅ **100% Automático**: No requiere configuración manual
- ✅ **Fiable**: Las notificaciones no se pierden
- ✅ **Eficiente**: Bajo consumo de batería
- ✅ **Inteligente**: Solo programa notificaciones necesarias
- ✅ **Persistente**: Funciona después de reinicios
- ✅ **Sincronizado**: Se actualiza con cambios del servidor

---

**¡El sistema está listo para usar! Las notificaciones funcionarán automáticamente. 🎉**
