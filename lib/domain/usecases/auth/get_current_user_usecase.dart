import 'package:fpdart/fpdart.dart';
import '../../core/error/failures.dart';
import '../../entities/app_user.dart';
import '../../repositories/auth_repository.dart';
import '../usecase.dart';

/// Caso de uso para obtener el usuario actualmente autenticado
class GetCurrentUserUseCase implements UseCaseNoParams<AppUser?> {
  final AuthRepository _repository;

  const GetCurrentUserUseCase(this._repository);

  @override
  Future<Either<Failure, AppUser?>> call() async {
    try {
      final user = _repository.currentUser;
      return Right(user);
    } catch (e) {
      return Left(_mapExceptionToFailure(e));
    }
  }

  /// Mapea excepciones a failures específicos
  Failure _mapExceptionToFailure(dynamic exception) {
    final message = exception.toString().toLowerCase();
    
    if (message.contains('network') || message.contains('connection')) {
      return const NetworkFailure('Error de conexión al obtener usuario');
    }
    
    return UnknownFailure('Error inesperado: ${exception.toString()}');
  }
}