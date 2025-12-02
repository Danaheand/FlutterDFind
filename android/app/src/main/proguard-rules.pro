# ===================================================================
# REGLAS PROGUARD PARA FLUTTER LOCAL NOTIFICATIONS
# ===================================================================

# --- Mantener TODOS los atributos necesarios para reflexión ---
-keepattributes Signature
-keepattributes *Annotation*
-keepattributes InnerClasses
-keepattributes EnclosingMethod
-keepattributes Exceptions

# --- Flutter Local Notifications Plugin ---
# NO permitir ofuscación ni optimización del plugin
-keep class com.dexterous.flutterlocalnotifications.** { *; }
-keep interface com.dexterous.flutterlocalnotifications.** { *; }

# Mantener específicamente los receivers
-keep class com.dexterous.flutterlocalnotifications.ActionBroadcastReceiver { *; }
-keep class com.dexterous.flutterlocalnotifications.ScheduledNotificationBootReceiver { *; }
-keep class com.dexterous.flutterlocalnotifications.ScheduledNotificationReceiver { *; }

# Mantener todas las clases internas del plugin (esto es CRÍTICO)
-keep class com.dexterous.flutterlocalnotifications.**$* { *; }

# --- GSON - SIN OFUSCACIÓN ---
# Esta es la parte MÁS IMPORTANTE para evitar "Missing type parameter"
-keep class com.google.gson.** { *; }
-keep class * implements com.google.gson.** { *; }

# TypeToken - MANTENER SIN OFUSCACIÓN
-keep class com.google.gson.reflect.TypeToken { *; }
-keep class * extends com.google.gson.reflect.TypeToken { *; }

# Mantener TODAS las clases internas de GSON
-keep class com.google.gson.**$* { *; }

# Mantener constructores de TypeToken
-keepclassmembers class * extends com.google.gson.reflect.TypeToken {
    <init>();
    <init>(...);
}

# Mantener clases anónimas relacionadas con TypeToken
-keep class **$TypeToken { *; }
-keep class **$TypeToken$* { *; }

# Serializers y Deserializers
-keep class * implements com.google.gson.JsonSerializer { *; }
-keep class * implements com.google.gson.JsonDeserializer { *; }

# --- Modelos de datos ---
-keep class com.dexterous.flutterlocalnotifications.models.** { *; }

# Mantener campos con anotaciones de serialización
-keepclassmembers class * {
    @com.google.gson.annotations.SerializedName <fields>;
}

# --- BroadcastReceivers ---
-keep public class * extends android.content.BroadcastReceiver {
    public <init>();
    public <init>(...);
}

# --- Warnings ---
-dontwarn com.google.gson.**
-dontwarn javax.annotation.**
-dontwarn sun.misc.Unsafe

# --- Reglas generales para evitar problemas con reflexión ---
-keepclassmembers class * {
    @android.webkit.JavascriptInterface <methods>;
}

# Mantener nombres de métodos nativos
-keepclasseswithmembernames class * {
    native <methods>;
}