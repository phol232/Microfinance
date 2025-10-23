import 'package:fpdart/fpdart.dart';
import '../../repositories/loan_application_repository.dart';
import '../../core/error/failures.dart';

class TakeOwnershipOfApplicationUseCase {
  final LoanApplicationRepository repository;

  TakeOwnershipOfApplicationUseCase(this.repository);

  Future<Either<Failure, void>> call({
    required String microfinancieraId,
    required String applicationId,
    required String agentId,
    required String agentUserId,
  }) async {
    try {
      // Validaciones
      if (microfinancieraId.isEmpty) {
        return left(const ValidationFailure('ID de microfinanciera no puede estar vacío'));
      }

      if (applicationId.isEmpty) {
        return left(const ValidationFailure('ID de aplicación no puede estar vacío'));
      }

      if (agentId.isEmpty) {
        return left(const ValidationFailure('ID de agente no puede estar vacío'));
      }

      if (agentUserId.isEmpty) {
        return left(const ValidationFailure('ID de usuario agente no puede estar vacío'));
      }

      await repository.takeOwnership(
        microfinancieraId,
        applicationId,
        agentId,
        agentUserId,
      );

      return right(null);
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