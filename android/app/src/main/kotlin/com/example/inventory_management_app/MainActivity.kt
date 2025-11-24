package com.example.inventory_management_app

import android.app.NotificationChannel
import android.app.NotificationManager
import android.content.Context
import android.media.AudioAttributes
import android.media.RingtoneManager
import android.os.Build
import io.flutter.embedding.android.FlutterActivity

class MainActivity : FlutterActivity() {
    override fun onResume() {
        super.onResume()
        createNotificationChannels()
    }

    private fun createNotificationChannels() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager

            // Canal de alarmas de alta prioridad
            val alarmChannel = NotificationChannel(
                "alarm_channel_high",
                "Alarmas Importantes",
                NotificationManager.IMPORTANCE_MAX
            ).apply {
                description = "Notificaciones de alarmas con sonido y vibración fuerte"
                enableVibration(true)
                vibrationPattern = longArrayOf(0, 500, 250, 500, 250, 500, 250, 1000)
                enableLights(true)
                lightColor = 0xFFFF0000.toInt() // Rojo
                
                // Configurar sonido de alarma
                val audioAttributes = AudioAttributes.Builder()
                    .setUsage(AudioAttributes.USAGE_ALARM)
                    .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
                    .build()
                
                val alarmRingtoneUri = RingtoneManager.getDefaultUri(RingtoneManager.TYPE_ALARM)
                setSound(alarmRingtoneUri, audioAttributes)
                
                setShowBadge(true)
            }

            // Canal de prueba
            val testChannel = NotificationChannel(
                "test_channel",
                "Prueba",
                NotificationManager.IMPORTANCE_MAX
            ).apply {
                description = "Notificación de prueba"
                enableVibration(true)
                vibrationPattern = longArrayOf(0, 500, 250, 500)
                
                val audioAttributes = AudioAttributes.Builder()
                    .setUsage(AudioAttributes.USAGE_ALARM)
                    .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
                    .build()
                
                val alarmRingtoneUri = RingtoneManager.getDefaultUri(RingtoneManager.TYPE_ALARM)
                setSound(alarmRingtoneUri, audioAttributes)
                
                setShowBadge(true)
            }

            notificationManager.createNotificationChannel(alarmChannel)
            notificationManager.createNotificationChannel(testChannel)
        }
    }
}
