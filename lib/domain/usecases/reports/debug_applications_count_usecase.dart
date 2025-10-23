import 'package:fpdart/fpdart.dart';
import '../../core/error/failures.dart';
import '../usecase.dart';
import '../../../data/datasources/backend_api_datasource.dart';

class DebugApplicationsCountUseCase implements UseCase<Map<String, dynamic>, DebugApplicationsCountParams> {
  final BackendApiDatasource _datasource;
  
  // TODO: Inyectar mediante dependency injection
  DebugApplicationsCountUseCase() : _datasource = BackendApiDatasource();

  @override
  Future<Either<Failure, Map<String, dynamic>>> call(DebugApplicationsCountParams params) async {
    try {
      final result = await _datasource.debugApplicationsCount(
        microfinancieraId: params.microfinancieraId,
      );
      
      return right(result);
    } catch (e) {
      return left(ServerFailure('Error obteniendo conteo de aplicaciones: $e'));
    }
  }
}

class DebugApplicationsCountParams {
  final String microfinancieraId;

  const DebugApplicationsCountParams({
    required this.microfinancieraId,
  });
}