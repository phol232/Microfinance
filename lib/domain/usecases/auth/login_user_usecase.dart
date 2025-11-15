import 'package:fpdart/fpdart.dart';
import '../../core/error/failures.dart';
import '../../entities/login_result.dart';
import '../../repositories/auth_repository.dart';
import '../usecase.dart';

/// Caso de uso para autenticar un usuario con email y contraseña
/// ✅ OPTIMIZACIÓN: Ahora retorna LoginResult con perfil incluido
class LoginUserUseCase implements UseCase<LoginResult, LoginParams> {
  final AuthRepository _repository;

  const LoginUserUseCase(this._repository);

  @override
  Future<Either<Failure, LoginResult>> call(LoginParams params) async {
    // Validaciones de negocio
    final validationResult = _validateParams(params);
    if (validationResult != null) {
      return Left(validationResult);
    }

    try {
      final result = await _repository.signInWithEmailAndPassword(
        email: params.email,
        password: params.password,
        microfinancieraId: params.microfinancieraId,
      );

      if (result != null && result.user != null) {
        return Right(result);
      } else {
        return const Left(AuthFailure('Credenciales inválidas'));
      }
    } catch (e) {
      return Left(_mapExceptionToFailure(e));
    }
  }

  /// Valida los parámetros de entrada
  ValidationFailure? _validateParams(LoginParams params) {
    if (params.email.isEmpty) {
      return const ValidationFailure('El email es requerido');
    }

    if (!_isValidEmail(params.email)) {
      return const ValidationFailure('El formato del email es inválido');
    }

    if (params.password.isEmpty) {
      return const ValidationFailure('La contraseña es requerida');
    }

    if (params.password.length < 6) {
      return const ValidationFailure(
        'La contraseña debe tener al menos 6 caracteres',
      );
    }

    if (params.microfinancieraId.isEmpty) {
      return const ValidationFailure('La microfinanciera es requerida');
    }

    return null;
  }

  /// Valida el formato del email
  bool _isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  /// Mapea excepciones a failures específicos
  Failure _mapExceptionToFailure(dynamic exception) {
    final message = exception.toString().toLowerCase();

    if (message.contains('network') || message.contains('connection')) {
      return const NetworkFailure('Error de conexión. Verifica tu internet.');
    }

    // Errores de credenciales
    if (message.contains('invalid-credential') ||
        message.contains('user-not-found') ||
        message.contains('wrong-password')) {
      return const AuthFailure('Correo o contraseña incorrectos');
    }

    if (message.contains('too-many-requests')) {
      return const AuthFailure('Demasiados intentos. Intenta más tarde.');
    }

    if (message.contains('user-disabled')) {
      return const AuthFailure('Esta cuenta ha sido deshabilitada');
    }

    if (message.contains('invalid-email')) {
      return const AuthFailure('El formato del correo es inválido');
    }

    if (message.contains('email-already-in-use')) {
      return const AuthFailure('Este correo ya está registrado');
    }

    if (message.contains('weak-password')) {
      return const AuthFailure('La contraseña es muy débil');
    }

    if (message.contains('membership-not-found')) {
      return const AuthFailure(
        'Usuario no autorizado para esta microfinanciera',
      );
    }

    return const AuthFailure(
      'Error al iniciar sesión. Verifica tus credenciales.',
    );
  }
}

/// Parámetros para el caso de uso de login
class LoginParams {
  final String email;
  final String password;
  final String microfinancieraId;

  const LoginParams({
    required this.email,
    required this.password,
    required this.microfinancieraId,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LoginParams &&
          runtimeType == other.runtimeType &&
          email == other.email &&
          password == other.password &&
          microfinancieraId == other.microfinancieraId;

  @override
  int get hashCode =>
      email.hashCode ^ password.hashCode ^ microfinancieraId.hashCode;

  @override
  String toString() =>
      'LoginParams(email: $email, microfinancieraId: $microfinancieraId, password: [HIDDEN])';
}
