import 'package:fpdart/fpdart.dart';
import '../../core/error/failures.dart';
import '../usecase.dart';
import '../../../data/datasources/backend_api_datasource.dart';

class GenerateReportUseCase implements UseCase<List<dynamic>, GenerateReportParams> {
  final BackendApiDatasource _datasource;
  
  // TODO: Inyectar mediante dependency injection
  GenerateReportUseCase() : _datasource = BackendApiDatasource();

  @override
  Future<Either<Failure, List<dynamic>>> call(GenerateReportParams params) async {
    try {
      final result = await _datasource.generateReport(
        microfinancieraId: params.microfinancieraId,
        dateFrom: params.dateFrom,
        dateTo: params.dateTo,
      );
      
      return right(result);
    } catch (e) {
      return left(ServerFailure('Error generando reporte: $e'));
    }
  }
}

class GenerateReportParams {
  final String microfinancieraId;
  final DateTime dateFrom;
  final DateTime dateTo;

  const GenerateReportParams({
    required this.microfinancieraId,
    required this.dateFrom,
    required this.dateTo,
  });
}