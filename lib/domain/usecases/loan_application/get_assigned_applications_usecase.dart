import 'package:fpdart/fpdart.dart';
import '../../entities/loan_application.dart';
import '../../repositories/loan_application_repository.dart';
import '../../core/error/failures.dart';

class GetAssignedApplicationsUseCase {
  final LoanApplicationRepository repository;

  GetAssignedApplicationsUseCase(this.repository);

  Future<Either<Failure, List<LoanApplication>>> call({
    required String microfinancieraId,
    required String agentId,
    List<String>? statusFilter,
  }) async {
    try {
      // Validaciones
      if (microfinancieraId.isEmpty) {
        return left(const ValidationFailure('ID de microfinanciera no puede estar vacío'));
      }

      if (agentId.isEmpty) {
        return left(const ValidationFailure('ID de agente no puede estar vacío'));
      }

      final applications = await repository.getAssignedToAgent(
        microfinancieraId,
        agentId,
        statusFilter: statusFilter,
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