import 'package:fpdart/fpdart.dart';
import '../../repositories/loan_application_repository.dart';
import '../../core/error/failures.dart';

class GetApplicationStatsUseCase {
  final LoanApplicationRepository repository;

  GetApplicationStatsUseCase(this.repository);

  Future<Either<Failure, Map<String, int>>> call({
    required String microfinancieraId,
  }) async {
    try {
      // Validaciones
      if (microfinancieraId.isEmpty) {
        return left(const ValidationFailure('ID de microfinanciera no puede estar vacío'));
      }

      final stats = await repository.getApplicationStats(microfinancieraId);

      // Validar que las estadísticas no estén vacías o con valores negativos
      if (stats.values.any((count) => count < 0)) {
        return left(const ValidationFailure('Las estadísticas contienen valores inválidos'));
      }

      return right(stats);
    } on NetworkException {
      return left(const NetworkFailure('Error de conexión'));
    } on AuthorizationException {
      return left(const AuthorizationFailure('No autorizado'));
    } catch (e) {
      return left(UnknownFailure('Error desconocido: $e'));
    }
  }
}

class NetworkException implements Exception {}
class AuthorizationException implements Exception {}