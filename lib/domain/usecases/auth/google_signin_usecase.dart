import 'package:fpdart/fpdart.dart';
import '../../entities/app_user.dart';
import '../../repositories/auth_repository.dart';
import '../../core/error/failures.dart';
import '../usecase.dart';

class GoogleSignInParams {
  final String microfinancieraId;
  final List<String> roles;

  const GoogleSignInParams({
    required this.microfinancieraId,
    required this.roles,
  });
}

class GoogleSignInUseCase implements UseCase<AppUser, GoogleSignInParams> {
  final AuthRepository _authRepository;

  const GoogleSignInUseCase(this._authRepository);

  @override
  Future<Either<Failure, AppUser>> call(GoogleSignInParams params) async {
    try {
      // Validaciones de negocio
      if (params.microfinancieraId.trim().isEmpty) {
        return left(const ValidationFailure('La microfinanciera es requerida'));
      }

      if (params.roles.isEmpty) {
        return left(const ValidationFailure('Al menos un rol es requerido'));
      }

      final user = await _authRepository.signInWithGoogle(
        microfinancieraId: params.microfinancieraId,
        roles: params.roles,
      );

      if (user == null) {
        return left(const AuthFailure('Error al iniciar sesión con Google'));
      }

      return right(user);
    } catch (e) {
      if (e.toString().contains('network')) {
        return left(const NetworkFailure('Error de conexión'));
      }
      return left(UnknownFailure('Error inesperado: ${e.toString()}'));
    }
  }
}