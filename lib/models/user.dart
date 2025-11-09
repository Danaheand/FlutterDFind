class User {
  final int idUsuario;
  final String nombreUsuario;
  final String email;
  final String contrasenaHash;
  final String fechaCreacionIso;
  final String telefono;

  User({
    required this.idUsuario,
    required this.nombreUsuario,
    required this.email,
    required this.contrasenaHash,
    required this.fechaCreacionIso,
    this.telefono = '',
  });

  Map<String, dynamic> toJson() => {
    'id_usuario': idUsuario,
    'nombre_usuario': nombreUsuario,
    'email': email,
    'contrasena_hash': contrasenaHash,
    'fecha_creacion': fechaCreacionIso,
    'telefono': telefono,
  };

  factory User.fromJson(Map<String, dynamic> json) => User(
    idUsuario: json['id_usuario'] as int,
    nombreUsuario: json['nombre_usuario'] as String,
    email: json['email'] as String,
    contrasenaHash: json['contrasena_hash'] as String,
    fechaCreacionIso: json['fecha_creacion'] as String,
    telefono: json['telefono'] as String? ?? '',
  );

  User copyWith({
    int? idUsuario,
    String? nombreUsuario,
    String? email,
    String? contrasenaHash,
    String? fechaCreacionIso,
    String? telefono,
  }) {
    return User(
      idUsuario: idUsuario ?? this.idUsuario,
      nombreUsuario: nombreUsuario ?? this.nombreUsuario,
      email: email ?? this.email,
      contrasenaHash: contrasenaHash ?? this.contrasenaHash,
      fechaCreacionIso: fechaCreacionIso ?? this.fechaCreacionIso,
      telefono: telefono ?? this.telefono,
    );
  }
}