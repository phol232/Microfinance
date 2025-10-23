import 'package:fpdart/fpdart.dart';
import '../../entities/app_user.dart';
import '../../repositories/auth_repository.dart';
import '../../core/error/failures.dart';
import '../usecase.dart';

class AnonymousSignInUseCase implements UseCaseNoParams<AppUser> {
  final AuthRepository _authRepository;

  const AnonymousSignInUseCase(this._authRepository);

  @override
  Future<Either<Failure, AppUser>> call() async {
    try {
      final user = await _authRepository.signInAnonymously();

      if (user == null) {
        return left(const AuthFailure('Error al iniciar sesión anónima'));
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