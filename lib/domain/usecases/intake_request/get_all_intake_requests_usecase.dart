import 'package:fpdart/fpdart.dart';
import '../../repositories/intake_request_repository.dart';
import '../../entities/loan_application.dart';
import '../../core/error/failures.dart';
import '../usecase.dart';

class GetAllIntakeRequestsParams {
  const GetAllIntakeRequestsParams();
}

class GetAllIntakeRequestsUseCase implements UseCase<List<LoanApplication>, GetAllIntakeRequestsParams> {
  final IntakeRequestRepository _repository;

  const GetAllIntakeRequestsUseCase(this._repository);

  @override
  Future<Either<Failure, List<LoanApplication>>> call(GetAllIntakeRequestsParams params) async {
    try {
      final requests = await _repository.getAll();
      return right(requests);
    } catch (e) {
      if (e.toString().contains('network')) {
        return left(const NetworkFailure('Error de conexión'));
      }
      if (e.toString().contains('permission')) {
        return left(const AuthorizationFailure('No tienes permisos para ver las solicitudes'));
      }
      return left(UnknownFailure('Error inesperado: ${e.toString()}'));
    }
  }
}