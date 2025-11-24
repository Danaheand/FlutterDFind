import 'dart:typed_data';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  Future<void> initialize() async {
    // No inicializar en web
    if (kIsWeb) {
      print('⚠️ NotificationService deshabilitado en web');
      return;
    }

    try {
      tz.initializeTimeZones();

      const AndroidInitializationSettings androidSettings =
          AndroidInitializationSettings('@mipmap/ic_launcher');
      const DarwinInitializationSettings iosSettings =
          DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

      const InitializationSettings settings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      await _notifications.initialize(
        settings,
        onDidReceiveNotificationResponse: _handleNotificationTap,
      );
      await _requestPermissions();
      print('✅ NotificationService inicializado en móvil');
    } catch (e) {
      print('Error al inicializar notificaciones: $e');
    }
  }

  void _handleNotificationTap(NotificationResponse response) {
    print('📲 Notificación tocada: ${response.payload}');
    // Aquí puedes manejar qué hacer cuando el usuario toca la notificación
  }

  Future<void> _requestPermissions() async {
    try {
      // Solicitar permiso de notificaciones
      final notificationStatus = await Permission.notification.request();
      print('📱 Permiso de notificaciones: $notificationStatus');

      // Para Android 13+
      final alarmStatus = await Permission.scheduleExactAlarm.request();
      print('⏰ Permiso de alarma exacta: $alarmStatus');
    } catch (e) {
      print('Error al solicitar permisos: $e');
    }
  }

  Future<void> scheduleAlarmNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
    String? payload,
  }) async {
    if (kIsWeb) return;

    try {
      print('📅 Programando notificación ID:$id para: $scheduledDate');
      print('   Título: $title');
      print('   Ahora: ${DateTime.now()}');

      final AndroidNotificationDetails androidDetails =
          AndroidNotificationDetails(
        'alarm_channel_high',
        'Alarmas Importantes',
        channelDescription:
            'Notificaciones de alarmas con sonido y vibración',
        importance: Importance.max,
        priority: Priority.max,
        playSound: true,
        enableVibration: true,
        vibrationPattern: Int64List.fromList([0, 500, 250, 500, 250, 500]),
        fullScreenIntent: true,
        category: AndroidNotificationCategory.alarm,
        autoCancel: false,
        timeoutAfter: 300000, // 5 minutos
      );

      const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        sound: 'default',
        interruptionLevel: InterruptionLevel.critical,
      );

      final NotificationDetails notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      // Convertir a zona horaria local
      final tzDateTime = tz.TZDateTime.from(scheduledDate, tz.local);

      await _notifications.zonedSchedule(
        id,
        title,
        body,
        tzDateTime,
        notificationDetails,
        payload: payload,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.dateAndTime,
      );

      print('✅ Notificación ID:$id programada exitosamente');
      
      // Log de notificaciones pendientes
      final pending = await _notifications.pendingNotificationRequests();
      print('📋 Total de notificaciones pendientes: ${pending.length}');
    } catch (e) {
      print('❌ Error programando notificación ID:$id: $e');
      rethrow;
    }
  }

  Future<void> scheduleRepeatingAlarmNotification({
    required int baseId,
    required String title,
    required String body,
    required DateTime scheduledDate,
    required List<int> weekdays, // [1,2,3,4,5,6,7] para Lun-Dom
    String? payload,
  }) async {
    if (kIsWeb) return;

    try {
      for (int i = 0; i < weekdays.length; i++) {
        final weekday = weekdays[i];
        final notificationId = baseId + i;

        // Calcular la próxima fecha para este día de la semana
        DateTime nextDate = _getNextWeekday(scheduledDate, weekday);

        final androidDetails = AndroidNotificationDetails(
          'alarm_channel_high',
          'Alarmas Importantes',
          channelDescription:
              'Notificaciones de alarmas con sonido y vibración',
          importance: Importance.max,
          priority: Priority.max,
          playSound: true,
          enableVibration: true,
          vibrationPattern: Int64List.fromList([0, 500, 250, 500, 250, 500]),
          fullScreenIntent: true,
          category: AndroidNotificationCategory.alarm,
          autoCancel: false,
        );

        const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
          sound: 'default',
          interruptionLevel: InterruptionLevel.critical,
        );

        final NotificationDetails notificationDetails = NotificationDetails(
          android: androidDetails,
          iOS: iosDetails,
        );

        final tzDateTime = tz.TZDateTime.from(nextDate, tz.local);

        await _notifications.zonedSchedule(
          notificationId,
          title,
          '$body (${_getWeekdayName(weekday)})',
          tzDateTime,
          notificationDetails,
          payload: payload,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
          matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
        );

        print('✅ Notificación repetitiva ID:$notificationId programada');
      }
    } catch (e) {
      print('Error programando notificaciones repetitivas: $e');
    }
  }

  DateTime _getNextWeekday(DateTime from, int weekday) {
    int daysToAdd = (weekday - from.weekday) % 7;
    if (daysToAdd == 0 && from.isBefore(DateTime.now())) {
      daysToAdd = 7;
    }
    return DateTime(from.year, from.month, from.day, from.hour, from.minute)
        .add(Duration(days: daysToAdd));
  }

  String _getWeekdayName(int weekday) {
    const names = [
      '',
      'Lunes',
      'Martes',
      'Miércoles',
      'Jueves',
      'Viernes',
      'Sábado',
      'Domingo'
    ];
    return names[weekday];
  }

  Future<void> cancelNotification(int id) async {
    if (kIsWeb) return;
    await _notifications.cancel(id);
    print('✅ Notificación ID:$id cancelada');
  }

  Future<void> cancelAllNotifications() async {
    if (kIsWeb) return;
    await _notifications.cancelAll();
    print('✅ Todas las notificaciones canceladas');
  }

  Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    if (kIsWeb) return [];
    return await _notifications.pendingNotificationRequests();
  }

  Future<void> testNotification() async {
    if (kIsWeb) return;

    try {
      final now = DateTime.now().add(const Duration(seconds: 3));

      const androidDetails = AndroidNotificationDetails(
        'test_channel',
        'Prueba',
        channelDescription: 'Notificación de prueba',
        importance: Importance.max,
        priority: Priority.max,
        enableVibration: true,
      );

      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _notifications.zonedSchedule(
        999,
        'Prueba de Notificación',
        'Esta es una notificación de prueba en 3 segundos',
        tz.TZDateTime.from(now, tz.local),
        notificationDetails,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.dateAndTime,
      );

      print('✅ Notificación de prueba programada');
    } catch (e) {
      print('❌ Error en notificación de prueba: $e');
    }
  }
}
