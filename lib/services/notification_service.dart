import 'dart:typed_data';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'package:permission_handler/permission_handler.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();

  Future<void> initialize() async {
    try {
      tz.initializeTimeZones();
      
      const AndroidInitializationSettings androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
      const DarwinInitializationSettings iosSettings = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );
      
      const InitializationSettings settings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      await _notifications.initialize(settings);
      await _requestPermissions();
    } catch (e) {
      print('Error al inicializar notificaciones: $e');
      // No hacer throw para permitir que la app continúe en web
    }
  }

  Future<void> _requestPermissions() async {
    try {
      await Permission.notification.request();
      
      // Para Android 13+
      if (await Permission.scheduleExactAlarm.isDenied) {
        await Permission.scheduleExactAlarm.request();
      }
    } catch (e) {
      print('Error al solicitar permisos: $e');
      // No hacer throw para permitir que la app continúe en web
    }
  }

  Future<void> scheduleAlarmNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
    String? payload,
  }) async {
    try {
    final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'alarm_channel',
      'Alarmas',
      channelDescription: 'Notificaciones de alarmas importantes',
      importance: Importance.max,
      priority: Priority.high,
      sound: const RawResourceAndroidNotificationSound('alarm_sound'), // Opcional: sonido personalizado
      enableVibration: true,
      vibrationPattern: Int64List.fromList([0, 1000, 500, 1000]),
      fullScreenIntent: true, // Mostrar en pantalla completa
      category: AndroidNotificationCategory.alarm,
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      sound: 'alarm_sound.caf', // Opcional: sonido personalizado
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      interruptionLevel: InterruptionLevel.critical,
    );

    final NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.zonedSchedule(
      id,
      title,
      body,
      tz.TZDateTime.from(scheduledDate, tz.local),
      notificationDetails,
      payload: payload,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.dateAndTime,
    );
    } catch (e) {
      print('Error programando notificación: $e');
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
    try {
      for (int i = 0; i < weekdays.length; i++) {
        final weekday = weekdays[i];
        final notificationId = baseId + i;
        
        // Calcular la próxima fecha para este día de la semana
        DateTime nextDate = _getNextWeekday(scheduledDate, weekday);
        
        final androidDetails = AndroidNotificationDetails(
          'alarm_channel',
          'Alarmas',
          channelDescription: 'Notificaciones de alarmas importantes',
          importance: Importance.max,
          priority: Priority.high,
          sound: const RawResourceAndroidNotificationSound('alarm_sound'),
          enableVibration: true,
          vibrationPattern: Int64List.fromList([0, 1000, 500, 1000]),
          fullScreenIntent: true,
          category: AndroidNotificationCategory.alarm,
        );

        const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
          sound: 'alarm_sound.caf',
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
          interruptionLevel: InterruptionLevel.critical,
        );

        final NotificationDetails notificationDetails = NotificationDetails(
          android: androidDetails,
          iOS: iosDetails,
        );

        await _notifications.zonedSchedule(
          notificationId,
          title,
          '$body (${_getWeekdayName(weekday)})',
          tz.TZDateTime.from(nextDate, tz.local),
          notificationDetails,
          payload: payload,
          uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
          matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
        );
      }
    } catch (e) {
      print('Error programando notificaciones repetitivas: $e');
    }
  }

  DateTime _getNextWeekday(DateTime from, int weekday) {
    int daysToAdd = (weekday - from.weekday) % 7;
    if (daysToAdd == 0 && from.isBefore(DateTime.now())) {
      daysToAdd = 7; // Si es el mismo día pero ya pasó, programar para la próxima semana
    }
    return DateTime(from.year, from.month, from.day, from.hour, from.minute).add(Duration(days: daysToAdd));
  }

  String _getWeekdayName(int weekday) {
    const names = ['', 'Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes', 'Sábado', 'Domingo'];
    return names[weekday];
  }

  Future<void> cancelNotification(int id) async {
    await _notifications.cancel(id);
  }

  Future<void> cancelAllNotifications() async {
    await _notifications.cancelAll();
  }

  Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    return await _notifications.pendingNotificationRequests();
  }
}