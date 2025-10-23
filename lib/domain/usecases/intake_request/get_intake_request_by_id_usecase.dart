import 'package:fpdart/fpdart.dart';
import '../../repositories/intake_request_repository.dart';
import '../../entities/loan_application.dart';
import '../../core/error/failures.dart';
import '../usecase.dart';

class GetIntakeRequestByIdParams {
  final String id;

  const GetIntakeRequestByIdParams({required this.id});
}

class GetIntakeRequestByIdUseCase implements UseCase<LoanApplication?, GetIntakeRequestByIdParams> {
  final IntakeRequestRepository _repository;

  const GetIntakeRequestByIdUseCase(this._repository);

  @override
  Future<Either<Failure, LoanApplication?>> call(GetIntakeRequestByIdParams params) async {
    try {
      // Validaciones de negocio
      if (params.id.trim().isEmpty) {
        return left(const ValidationFailure('El ID es requerido'));
      }

      // Validar formato básico del ID (debe ser alfanumérico)
      if (!RegExp(r'^[a-zA-Z0-9_-]+$').hasMatch(params.id)) {
        return left(const ValidationFailure('Formato de ID inválido'));
      }

      final request = await _repository.getById(params.id);
      return right(request);
    } catch (e) {
      if (e.toString().contains('network')) {
        return left(const NetworkFailure('Error de conexión'));
      }
      if (e.toString().contains('permission')) {
        return left(const AuthorizationFailure('No tienes permisos para ver esta solicitud'));
      }
      if (e.toString().contains('not-found')) {
        return left(const ValidationFailure('Solicitud no encontrada'));
      }
      return left(UnknownFailure('Error inesperado: ${e.toString()}'));
    }
  }
}