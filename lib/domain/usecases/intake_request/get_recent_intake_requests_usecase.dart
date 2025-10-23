import 'package:fpdart/fpdart.dart';
import '../../repositories/intake_request_repository.dart';
import '../../entities/loan_application.dart';
import '../../core/error/failures.dart';
import '../usecase.dart';

class GetRecentIntakeRequestsParams {
  final int limit;

  const GetRecentIntakeRequestsParams({this.limit = 10});
}

class GetRecentIntakeRequestsUseCase
    implements UseCase<List<LoanApplication>, GetRecentIntakeRequestsParams> {
  final IntakeRequestRepository _repository;

  const GetRecentIntakeRequestsUseCase(this._repository);

  @override
  Future<Either<Failure, List<LoanApplication>>> call(
    GetRecentIntakeRequestsParams params,
  ) async {
    try {
      if (params.limit <= 0) {
        return left(const ValidationFailure('El límite debe ser mayor a 0'));
      }

      if (params.limit > 100) {
        return left(
          const ValidationFailure('El límite no puede ser mayor a 100'),
        );
      }

      final requests = await _repository.getRecent(limit: params.limit);
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
