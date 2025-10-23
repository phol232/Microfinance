import 'package:fpdart/fpdart.dart';
import '../../core/error/failures.dart';
import '../../entities/microfinanciera.dart';
import '../../repositories/auth_repository.dart';
import '../usecase.dart';

/// Caso de uso para obtener la lista de microfinancieras activas
class GetMicrofinancierasUseCase implements UseCaseNoParams<List<Microfinanciera>> {
  final AuthRepository _repository;

  const GetMicrofinancierasUseCase(this._repository);

  @override
  Future<Either<Failure, List<Microfinanciera>>> call() async {
    try {
      final microfinancieras = await _repository.getActiveMicrofinancieras();
      
      if (microfinancieras.isEmpty) {
        return const Left(NotFoundFailure('No hay microfinancieras disponibles'));
      }
      
      return Right(microfinancieras);
    } catch (e) {
      return Left(_mapExceptionToFailure(e));
    }
  }

  /// Mapea excepciones a failures específicos
  Failure _mapExceptionToFailure(dynamic exception) {
    final message = exception.toString().toLowerCase();
    
    if (message.contains('network') || message.contains('connection')) {
      return const NetworkFailure('Error de conexión. Verifica tu internet.');
    }
    
    if (message.contains('permission') || message.contains('unauthorized')) {
      return const AuthorizationFailure('No tienes permisos para acceder a esta información');
    }
    
    return UnknownFailure('Error inesperado: ${exception.toString()}');
  }
}