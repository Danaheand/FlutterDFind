/// Excepciones personalizadas para el manejo de errores en recordatorios
class RecordatorioException implements Exception {
  final String message;
  final int? statusCode;
  final dynamic originalError;

  RecordatorioException(
    this.message, {
    this.statusCode,
    this.originalError,
  });

  @override
  String toString() => message;
}

/// Error de red (sin conexión, timeout, etc.)
class RecordatorioNetworkException extends RecordatorioException {
  RecordatorioNetworkException(String message, {dynamic originalError})
      : super(
          message,
          statusCode: null,
          originalError: originalError,
        );
}

/// Error del servidor (500, 502, etc.)
class RecordatorioServerException extends RecordatorioException {
  RecordatorioServerException(String message, int statusCode)
      : super(message, statusCode: statusCode);
}

/// Error de cliente (400, 404, etc.)
class RecordatorioClientException extends RecordatorioException {
  RecordatorioClientException(String message, int statusCode)
      : super(message, statusCode: statusCode);
}

/// Recordatorio no encontrado
class RecordatorioNotFoundException extends RecordatorioClientException {
  RecordatorioNotFoundException(String titulo)
      : super('Recordatorio "$titulo" no encontrado', 404);
}

/// Error de validación
class RecordatorioValidationException extends RecordatorioClientException {
  RecordatorioValidationException(String message) : super(message, 400);
}
