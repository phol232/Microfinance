import 'package:fpdart/fpdart.dart';
import '../../repositories/loan_application_repository.dart';
import '../../core/error/failures.dart';

class UpdateApplicationStatusUseCase {
  final LoanApplicationRepository repository;

  UpdateApplicationStatusUseCase(this.repository);

  Future<Either<Failure, void>> call({
    required String microfinancieraId,
    required String applicationId,
    required String newStatus,
    required String userId,
    String? reason,
    Map<String, dynamic>? additionalData,
  }) async {
    try {
      // Validaciones
      if (microfinancieraId.isEmpty) {
        return left(const ValidationFailure('ID de microfinanciera no puede estar vacío'));
      }

      if (applicationId.isEmpty) {
        return left(const ValidationFailure('ID de aplicación no puede estar vacío'));
      }

      if (newStatus.isEmpty) {
        return left(const ValidationFailure('Nuevo estado no puede estar vacío'));
      }

      if (userId.isEmpty) {
        return left(const ValidationFailure('ID de usuario no puede estar vacío'));
      }

      await repository.updateApplicationStatus(
        microfinancieraId,
        applicationId,
        newStatus,
        userId,
        reason: reason,
        additionalData: additionalData,
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