class AppException implements Exception {
  final String message;
  final int? statusCode;
  final dynamic details;

  const AppException(this.message, {this.statusCode, this.details});

  @override
  String toString() => message;
}

class AuthException extends AppException {
  const AuthException([super.message = 'Sesión no autorizada o token vencido.'])
      : super(statusCode: 401);
}

class NotFoundException extends AppException {
  const NotFoundException([super.message = 'El recurso solicitado no fue encontrado.'])
      : super(statusCode: 404);
}

class NetworkException extends AppException {
  const NetworkException([super.message = 'No se pudo conectar con el servidor.']);
}
