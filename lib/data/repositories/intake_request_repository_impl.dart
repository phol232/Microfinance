import '../../domain/entities/loan_application.dart';
import '../../domain/repositories/intake_request_repository.dart';
import '../datasources/intake_request_datasource.dart';

class IntakeRequestRepositoryImpl implements IntakeRequestRepository {
  final IntakeRequestDataSource _dataSource;

  IntakeRequestRepositoryImpl(this._dataSource);

  @override
  Future<List<LoanApplication>> getAll() => _dataSource.getAll();

  @override
  Future<List<LoanApplication>> getByStatus(String status) =>
      _dataSource.getByStatus(status);

  @override
  Future<List<LoanApplication>> getRecent({int limit = 10}) =>
      _dataSource.getRecent(limit: limit);

  @override
  Future<LoanApplication?> getById(String id) => _dataSource.getById(id);

  @override
  Stream<List<LoanApplication>> watchAll() => _dataSource.watchAll();

  @override
  Stream<List<LoanApplication>> watchByStatus(String status) =>
      _dataSource.watchByStatus(status);

  @override
  Future<Map<String, int>> getStatusCounts() => _dataSource.getStatusCounts();

  @override
  Future<void> updateStatus(String applicationId, String newStatus) =>
      _dataSource.updateStatus(applicationId, newStatus);
}
