class User {
  final int idUsuario;
  final String nombreUsuario;
  final String email;
  final String contrasenaHash;
  final String fechaCreacionIso;
  final String telefono;
  final String? avatarTipo;
  final String? avatarClave;
  final bool modoOscuro;
  final bool notificacionesSonido;
  final bool notificacionesVibracion;
  final int tamanoFuente;

  User({
    required this.idUsuario,
    required this.nombreUsuario,
    required this.email,
    required this.contrasenaHash,
    required this.fechaCreacionIso,
    this.telefono = '',
    this.avatarTipo,
    this.avatarClave,
    this.modoOscuro = false,
    this.notificacionesSonido = true,
    this.notificacionesVibracion = true,
    this.tamanoFuente = 0,
  });

  Map<String, dynamic> toJson() => {
        'id_usuario': idUsuario,
        'nombre_usuario': nombreUsuario,
        'email': email,
        'contrasena_hash': contrasenaHash,
        'fecha_creacion': fechaCreacionIso,
        'telefono': telefono,
        'avatarTipo': avatarTipo,
        'avatarClave': avatarClave,
        'modoOscuro': modoOscuro,
        'notificacionesSonido': notificacionesSonido,
        'notificacionesVibracion': notificacionesVibracion,
        'tamanoFuente': tamanoFuente,
      };

  factory User.fromJson(Map<String, dynamic> json) {
    // Debug opcional
    print('User.fromJson recibió: $json');

    return User(
      idUsuario: _parseIntSafely(json['id_usuario'] ?? json['idUsuario']),
      nombreUsuario:
          _parseStringSafely(json['nombre_usuario'] ?? json['nombreUsuario']),
      email: _parseStringSafely(json['email'] ?? json['correo']),
      contrasenaHash:
          _parseStringSafely(json['contrasena_hash'] ?? json['contrasenaHash']),
      fechaCreacionIso:
          _parseStringSafely(json['fecha_creacion'] ?? json['fechaCreacion']),
      telefono: _parseStringSafely(json['telefono']),
      avatarTipo:
          json['avatar_tipo'] as String? ?? json['avatarTipo'] as String?,
      avatarClave:
          json['avatar_clave'] as String? ?? json['avatarClave'] as String?,
      modoOscuro: _parseBoolSafely(json['modo_oscuro'] ?? json['modoOscuro']),
      notificacionesSonido: _parseBoolSafely(
          json['notificaciones_sonido'] ?? json['notificacionesSonido']),
      notificacionesVibracion: _parseBoolSafely(
          json['notificaciones_vibracion'] ?? json['notificacionesVibracion']),
      tamanoFuente:
          _parseIntSafely(json['tamano_fuente'] ?? json['tamanoFuente']),
    );
  }

  // Métodos auxiliares para parseo seguro
  static int _parseIntSafely(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is String) {
      return int.tryParse(value) ?? 0;
    }
    return 0;
  }

  static String _parseStringSafely(dynamic value) {
    if (value == null) return '';
    return value.toString();
  }

  static bool _parseBoolSafely(dynamic value) {
    if (value == null) return false;
    if (value is bool) return value;
    if (value is String) {
      return value.toLowerCase() == 'true' || value == '1';
    }
    if (value is int) return value == 1;
    return false;
  }

  User copyWith({
    int? idUsuario,
    String? nombreUsuario,
    String? email,
    String? contrasenaHash,
    String? fechaCreacionIso,
    String? telefono,
    String? avatarTipo,
    String? avatarClave,
    bool? modoOscuro,
    bool? notificacionesSonido,
    bool? notificacionesVibracion,
    int? tamanoFuente,
  }) {
    return User(
      idUsuario: idUsuario ?? this.idUsuario,
      nombreUsuario: nombreUsuario ?? this.nombreUsuario,
      email: email ?? this.email,
      contrasenaHash: contrasenaHash ?? this.contrasenaHash,
      fechaCreacionIso: fechaCreacionIso ?? this.fechaCreacionIso,
      telefono: telefono ?? this.telefono,
      avatarTipo: avatarTipo ?? this.avatarTipo,
      avatarClave: avatarClave ?? this.avatarClave,
      modoOscuro: modoOscuro ?? this.modoOscuro,
      notificacionesSonido: notificacionesSonido ?? this.notificacionesSonido,
      notificacionesVibracion:
          notificacionesVibracion ?? this.notificacionesVibracion,
      tamanoFuente: tamanoFuente ?? this.tamanoFuente,
    );
  }
}
