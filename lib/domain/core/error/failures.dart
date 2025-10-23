/// Clase base para todos los errores del dominio
abstract class Failure {
  final String message;
  final String? code;
  
  const Failure(this.message, {this.code});
  
  @override
  String toString() => 'Failure: $message${code != null ? ' (Code: $code)' : ''}';
  
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Failure &&
          runtimeType == other.runtimeType &&
          message == other.message &&
          code == other.code;

  @override
  int get hashCode => message.hashCode ^ code.hashCode;
}

/// Error de validación de datos
class ValidationFailure extends Failure {
  const ValidationFailure(super.message, {super.code});
}

/// Error de red/conectividad
class NetworkFailure extends Failure {
  const NetworkFailure(super.message, {super.code});
}

/// Error de autenticación
class AuthFailure extends Failure {
  const AuthFailure(super.message, {super.code});
}

/// Error de autorización/permisos
class AuthorizationFailure extends Failure {
  const AuthorizationFailure(super.message, {super.code});
}

/// Error de servidor
class ServerFailure extends Failure {
  const ServerFailure(super.message, {super.code});
}

/// Error de datos no encontrados
class NotFoundFailure extends Failure {
  const NotFoundFailure(super.message, {super.code});
}

/// Error de cache/almacenamiento local
class CacheFailure extends Failure {
  const CacheFailure(super.message, {super.code});
}

/// Error desconocido/genérico
class UnknownFailure extends Failure {
  const UnknownFailure(super.message, {super.code});
}