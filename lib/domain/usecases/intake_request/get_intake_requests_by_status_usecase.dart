import 'package:fpdart/fpdart.dart';
import '../../repositories/intake_request_repository.dart';
import '../../entities/loan_application.dart';
import '../../core/error/failures.dart';
import '../usecase.dart';

class GetIntakeRequestsByStatusParams {
  final String status;

  const GetIntakeRequestsByStatusParams({required this.status});
}

class GetIntakeRequestsByStatusUseCase
    implements UseCase<List<LoanApplication>, GetIntakeRequestsByStatusParams> {
  final IntakeRequestRepository _repository;

  const GetIntakeRequestsByStatusUseCase(this._repository);

  @override
  Future<Either<Failure, List<LoanApplication>>> call(
    GetIntakeRequestsByStatusParams params,
  ) async {
    try {
      if (params.status.trim().isEmpty) {
        return left(const ValidationFailure('El estado es requerido'));
      }

      const validStatuses = [
        'received',
        'validated',
        'routed',
        'rejected',
        'converted',
      ];
      if (!validStatuses.contains(params.status.toLowerCase())) {
        return left(const ValidationFailure('Estado inválido'));
      }

      final requests = await _repository.getByStatus(params.status);
      return right(requests);
    } catch (e) {
      if (e.toString().contains('network')) {
        return left(const NetworkFailure('Error de conexión'));
      }
      if (e.toString().contains('permission')) {
        return left(
          const AuthorizationFailure(
            'No tienes permisos para ver las solicitudes',
          ),
        );
      }
      return left(UnknownFailure('Error inesperado: ${e.toString()}'));
    }
  }
}
