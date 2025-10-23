import 'package:fpdart/fpdart.dart';
import '../../core/error/failures.dart';
import '../../repositories/auth_repository.dart';
import '../usecase.dart';

/// Caso de uso para cerrar sesión del usuario
class LogoutUserUseCase implements UseCaseNoParams<void> {
  final AuthRepository _repository;

  const LogoutUserUseCase(this._repository);

  @override
  Future<Either<Failure, void>> call() async {
    try {
      await _repository.signOut();
      return const Right(null);
    } catch (e) {
      return Left(_mapExceptionToFailure(e));
    }
  }

  /// Mapea excepciones a failures específicos
  Failure _mapExceptionToFailure(dynamic exception) {
    final message = exception.toString().toLowerCase();
    
    if (message.contains('network') || message.contains('connection')) {
      return const NetworkFailure('Error de conexión durante el logout');
    }
    
    return UnknownFailure('Error inesperado durante logout: ${exception.toString()}');
  }
}