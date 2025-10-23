import 'package:fpdart/fpdart.dart';
import '../../core/error/failures.dart';
import '../usecase.dart';
import '../../../data/datasources/backend_api_datasource.dart';

class GetConversionMetricsUseCase implements UseCase<Map<String, dynamic>, GetConversionMetricsParams> {
  final BackendApiDatasource _datasource;
  
  // TODO: Inyectar mediante dependency injection
  GetConversionMetricsUseCase() : _datasource = BackendApiDatasource();

  @override
  Future<Either<Failure, Map<String, dynamic>>> call(GetConversionMetricsParams params) async {
    try {
      final result = await _datasource.getConversionMetrics(
        microfinancieraId: params.microfinancieraId,
        dateFrom: params.dateFrom,
        dateTo: params.dateTo,
      );
      
      return right(result);
    } catch (e) {
      return left(ServerFailure('Error obteniendo métricas: $e'));
    }
  }
}

class GetConversionMetricsParams {
  final String microfinancieraId;
  final DateTime dateFrom;
  final DateTime dateTo;

  const GetConversionMetricsParams({
    required this.microfinancieraId,
    required this.dateFrom,
    required this.dateTo,
  });
}