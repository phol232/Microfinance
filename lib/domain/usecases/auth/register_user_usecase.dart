import 'package:fpdart/fpdart.dart';
import '../../core/error/failures.dart';
import '../../entities/app_user.dart';
import '../../repositories/auth_repository.dart';
import '../usecase.dart';

/// Caso de uso para registrar un nuevo usuario
class RegisterUserUseCase implements UseCase<AppUser, RegisterParams> {
  final AuthRepository _repository;

  const RegisterUserUseCase(this._repository);

  @override
  Future<Either<Failure, AppUser>> call(RegisterParams params) async {
    // Validaciones de negocio
    final validationResult = _validateParams(params);
    if (validationResult != null) {
      return Left(validationResult);
    }

    try {
      final user = await _repository.registerWithEmailAndPassword(
        email: params.email,
        password: params.password,
        firstName: params.firstName,
        lastName: params.lastName,
        dni: params.dni,
        phone: params.phone,
        microfinancieraId: params.microfinancieraId,
        roles: params.roles,
      );
      
      if (user != null) {
        return Right(user);
      } else {
        return const Left(AuthFailure('Error al crear la cuenta'));
      }
    } catch (e) {
      return Left(_mapExceptionToFailure(e));
    }
  }

  /// Valida los parámetros de entrada
  ValidationFailure? _validateParams(RegisterParams params) {
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
      return const ValidationFailure('La contraseña debe tener al menos 6 caracteres');
    }
    
    if (params.firstName.isEmpty) {
      return const ValidationFailure('El nombre es requerido');
    }
    
    if (params.lastName.isEmpty) {
      return const ValidationFailure('El apellido es requerido');
    }
    
    if (params.dni.isEmpty) {
      return const ValidationFailure('El DNI es requerido');
    }
    
    if (!_isValidDni(params.dni)) {
      return const ValidationFailure('El DNI debe tener 8 dígitos');
    }
    
    if (params.phone.isEmpty) {
      return const ValidationFailure('El teléfono es requerido');
    }
    
    if (!_isValidPhone(params.phone)) {
      return const ValidationFailure('El formato del teléfono es inválido');
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

  /// Valida el formato del DNI (8 dígitos)
  bool _isValidDni(String dni) {
    return RegExp(r'^\d{8}$').hasMatch(dni);
  }

  /// Valida el formato del teléfono
  bool _isValidPhone(String phone) {
    // Acepta formatos: +51999999999, 999999999, 51999999999
    return RegExp(r'^(\+?51)?[9]\d{8}$').hasMatch(phone);
  }

  /// Mapea excepciones a failures específicos
  Failure _mapExceptionToFailure(dynamic exception) {
    final message = exception.toString().toLowerCase();
    
    if (message.contains('network') || message.contains('connection')) {
      return const NetworkFailure('Error de conexión. Verifica tu internet.');
    }
    
    if (message.contains('email-already-in-use')) {
      return const AuthFailure('Este email ya está registrado');
    }
    
    if (message.contains('weak-password')) {
      return const AuthFailure('La contraseña es muy débil');
    }
    
    if (message.contains('invalid-email')) {
      return const AuthFailure('El formato del email es inválido');
    }
    
    return UnknownFailure('Error inesperado: ${exception.toString()}');
  }
}

/// Parámetros para el caso de uso de registro
class RegisterParams {
  final String email;
  final String password;
  final String firstName;
  final String lastName;
  final String dni;
  final String phone;
  final String microfinancieraId;
  final List<String> roles;

  const RegisterParams({
    required this.email,
    required this.password,
    required this.firstName,
    required this.lastName,
    required this.dni,
    required this.phone,
    required this.microfinancieraId,
    this.roles = const ['customer'],
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RegisterParams &&
          runtimeType == other.runtimeType &&
          email == other.email &&
          password == other.password &&
          firstName == other.firstName &&
          lastName == other.lastName &&
          dni == other.dni &&
          phone == other.phone &&
          microfinancieraId == other.microfinancieraId &&
          _listEquals(roles, other.roles);

  @override
  int get hashCode =>
      email.hashCode ^
      password.hashCode ^
      firstName.hashCode ^
      lastName.hashCode ^
      dni.hashCode ^
      phone.hashCode ^
      microfinancieraId.hashCode ^
      roles.hashCode;

  @override
  String toString() => 'RegisterParams('
      'email: $email, '
      'firstName: $firstName, '
      'lastName: $lastName, '
      'dni: $dni, '
      'phone: $phone, '
      'microfinancieraId: $microfinancieraId, '
      'roles: $roles, '
      'password: [HIDDEN])';

  /// Compara dos listas de strings
  bool _listEquals(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
