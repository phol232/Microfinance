import 'package:fpdart/fpdart.dart';
import '../../repositories/intake_request_repository.dart';
import '../../core/error/failures.dart';
import '../usecase.dart';

class GetIntakeRequestStatusCountsParams {
  const GetIntakeRequestStatusCountsParams();
}

class GetIntakeRequestStatusCountsUseCase
    implements UseCase<Map<String, int>, GetIntakeRequestStatusCountsParams> {
  final IntakeRequestRepository _repository;

  const GetIntakeRequestStatusCountsUseCase(this._repository);

  @override
  Future<Either<Failure, Map<String, int>>> call(
    GetIntakeRequestStatusCountsParams params,
  ) async {
    try {
      final counts = await _repository.getStatusCounts();

      if (counts.isEmpty) {
        return right({
          'received': 0,
          'validated': 0,
          'routed': 0,
          'rejected': 0,
          'converted': 0,
        });
      }

      for (final entry in counts.entries) {
        if (entry.value < 0) {
          return left(const ValidationFailure('Conteos inválidos detectados'));
        }
      }

      return right(counts);
    } catch (e) {
      if (e.toString().contains('network')) {
        return left(const NetworkFailure('Error de conexión'));
      }
      if (e.toString().contains('permission')) {
        return left(
          const AuthorizationFailure(
            'No tienes permisos para ver las estadísticas',
          ),
        );
      }
      return left(UnknownFailure('Error inesperado: ${e.toString()}'));
    }
  }
}
