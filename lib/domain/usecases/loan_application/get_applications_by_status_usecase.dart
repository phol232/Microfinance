import 'package:fpdart/fpdart.dart';
import '../../entities/loan_application.dart';
import '../../repositories/loan_application_repository.dart';
import '../../core/error/failures.dart';

class GetApplicationsByStatusUseCase {
  final LoanApplicationRepository repository;

  GetApplicationsByStatusUseCase(this.repository);

  Future<Either<Failure, List<LoanApplication>>> call({
    required String microfinancieraId,
    required List<String> statuses,
  }) async {
    try {
      // Validaciones
      if (microfinancieraId.isEmpty) {
        return left(const ValidationFailure('ID de microfinanciera no puede estar vacío'));
      }

      if (statuses.isEmpty) {
        return left(const ValidationFailure('Lista de estados no puede estar vacía'));
      }

      final applications = await repository.getApplicationsByStatus(
        microfinancieraId,
        statuses,
      );

      return right(applications);
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