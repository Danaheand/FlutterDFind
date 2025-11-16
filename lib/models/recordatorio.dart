/// Modelo de datos para los recordatorios
/// Representa un recordatorio en el sistema con todos sus campos y validaciones
class Recordatorio {
  final String? idRecordatorio;
  final int idUsuario;
  final String titulo;
  final String descripcion;
  final DateTime fechaHora;
  final String prioridad;
  final String? ubicacion;
  final String? objeto;
  final bool esRepetitivo;
  final String? frecuenciaRepeticion;
  final String? diasSeleccionados;
  final String? color;
  final String? rutaImagen;
  final bool activo;
  final DateTime? creadoEl;
  final DateTime? actualizadoEl;

  Recordatorio({
    this.idRecordatorio,
    required this.idUsuario,
    required this.titulo,
    required this.descripcion,
    required this.fechaHora,
    required this.prioridad,
    this.ubicacion,
    this.objeto,
    this.esRepetitivo = false,
    this.frecuenciaRepeticion,
    this.diasSeleccionados,
    this.color,
    this.rutaImagen,
    this.activo = true,
    this.creadoEl,
    this.actualizadoEl,
  });

  /// Crea una instancia desde JSON (respuesta de la API)
  factory Recordatorio.fromJson(Map<String, dynamic> json) {
    return Recordatorio(
      idRecordatorio: json['idRecordatorio'],
      idUsuario: json['idUsuario'] ?? 0,
      titulo: json['titulo'] ?? '',
      descripcion: json['descripcion'] ?? '',
      fechaHora: json['fechaHora'] != null
          ? DateTime.parse(json['fechaHora'])
          : DateTime.now(),
      prioridad: json['prioridad'] ?? 'Media',
      ubicacion: json['ubicacion'],
      objeto: json['objeto'],
      esRepetitivo: json['esRepetitivo'] ?? false,
      frecuenciaRepeticion: json['frecuenciaRepeticion'],
      diasSeleccionados: json['diasSeleccionados'],
      color: json['color'],
      rutaImagen: json['rutaImagen'],
      activo: json['activo'] ?? true,
      creadoEl:
          json['creadoEl'] != null ? DateTime.parse(json['creadoEl']) : null,
      actualizadoEl: json['actualizadoEl'] != null
          ? DateTime.parse(json['actualizadoEl'])
          : null,
    );
  }

  /// Convierte la instancia a JSON (para enviar a la API)
  Map<String, dynamic> toJson() {
    return {
      'idUsuario': idUsuario,
      'titulo': titulo,
      'descripcion': descripcion,
      'fechaHora': fechaHora.toIso8601String(),
      'prioridad': prioridad,
      if (ubicacion != null) 'ubicacion': ubicacion,
      if (objeto != null) 'objeto': objeto,
      'esRepetitivo': esRepetitivo,
      if (frecuenciaRepeticion != null)
        'frecuenciaRepeticion': frecuenciaRepeticion,
      if (diasSeleccionados != null) 'diasSeleccionados': diasSeleccionados,
      if (color != null) 'color': color,
      if (rutaImagen != null) 'rutaImagen': rutaImagen,
    };
  }

  /// Crea una copia del recordatorio con campos modificados
  Recordatorio copyWith({
    String? idRecordatorio,
    int? idUsuario,
    String? titulo,
    String? descripcion,
    DateTime? fechaHora,
    String? prioridad,
    String? ubicacion,
    String? objeto,
    bool? esRepetitivo,
    String? frecuenciaRepeticion,
    String? diasSeleccionados,
    String? color,
    String? rutaImagen,
    bool? activo,
    DateTime? creadoEl,
    DateTime? actualizadoEl,
  }) {
    return Recordatorio(
      idRecordatorio: idRecordatorio ?? this.idRecordatorio,
      idUsuario: idUsuario ?? this.idUsuario,
      titulo: titulo ?? this.titulo,
      descripcion: descripcion ?? this.descripcion,
      fechaHora: fechaHora ?? this.fechaHora,
      prioridad: prioridad ?? this.prioridad,
      ubicacion: ubicacion ?? this.ubicacion,
      objeto: objeto ?? this.objeto,
      esRepetitivo: esRepetitivo ?? this.esRepetitivo,
      frecuenciaRepeticion: frecuenciaRepeticion ?? this.frecuenciaRepeticion,
      diasSeleccionados: diasSeleccionados ?? this.diasSeleccionados,
      color: color ?? this.color,
      rutaImagen: rutaImagen ?? this.rutaImagen,
      activo: activo ?? this.activo,
      creadoEl: creadoEl ?? this.creadoEl,
      actualizadoEl: actualizadoEl ?? this.actualizadoEl,
    );
  }

  @override
  String toString() {
    return 'Recordatorio(id: $idRecordatorio, titulo: $titulo, '
        'descripcion: $descripcion, fechaHora: $fechaHora, activo: $activo)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Recordatorio &&
        other.idRecordatorio == idRecordatorio &&
        other.titulo == titulo &&
        other.idUsuario == idUsuario;
  }

  @override
  int get hashCode =>
      idRecordatorio.hashCode ^ titulo.hashCode ^ idUsuario.hashCode;
}
