import '../../domain/entities/loan_application.dart';
import '../../domain/repositories/loan_application_repository.dart';
import '../datasources/loan_application_datasource.dart';

class LoanApplicationRepositoryImpl implements LoanApplicationRepository {
  final LoanApplicationDataSource _dataSource;

  LoanApplicationRepositoryImpl({required LoanApplicationDataSource dataSource})
      : _dataSource = dataSource;

  @override
  Future<String> createApplication(
    String microfinancieraId,
    LoanApplication application,
  ) async {
    return await _dataSource.createApplication(microfinancieraId, application);
  }

  @override
  Future<List<LoanApplication>> getAllApplications(String microfinancieraId) async {
    return await _dataSource.getAllApplications(microfinancieraId);
  }

  @override
  Future<List<LoanApplication>> getAssignedToAgent(
    String microfinancieraId,
    String agentId, {
    List<String>? statusFilter,
  }) async {
    return await _dataSource.getAssignedToAgent(
      microfinancieraId,
      agentId,
      statusFilter: statusFilter,
    );
  }

  @override
  Future<List<LoanApplication>> getApplicationsByStatus(
    String microfinancieraId,
    List<String> statuses,
  ) async {
    return await _dataSource.getApplicationsByStatus(microfinancieraId, statuses);
  }

  @override
  Future<LoanApplication?> getApplicationById(
    String microfinancieraId,
    String applicationId,
  ) async {
    return await _dataSource.getApplicationById(microfinancieraId, applicationId);
  }

  @override
  Future<void> takeOwnership(
    String microfinancieraId,
    String applicationId,
    String agentId,
    String agentUserId,
  ) async {
    return await _dataSource.takeOwnership(
      microfinancieraId,
      applicationId,
      agentId,
      agentUserId,
    );
  }

  @override
  Future<void> updateApplicationStatus(
    String microfinancieraId,
    String applicationId,
    String newStatus,
    String userId, {
    String? reason,
    Map<String, dynamic>? additionalData,
  }) async {
    return await _dataSource.updateApplicationStatus(
      microfinancieraId,
      applicationId,
      newStatus,
      userId,
      reason: reason,
      additionalData: additionalData,
    );
  }

  @override
  Stream<List<LoanApplication>> watchAssignedApplications(
    String microfinancieraId,
    String agentId,
  ) {
    return _dataSource.watchAssignedApplications(microfinancieraId, agentId);
  }

  @override
  Stream<List<LoanApplication>> watchApplicationsByStatus(
    String microfinancieraId,
    List<String> statuses,
  ) {
    return _dataSource.watchApplicationsByStatus(microfinancieraId, statuses);
  }

  @override
  Future<Map<String, int>> getApplicationStats(String microfinancieraId) async {
    return await _dataSource.getApplicationStats(microfinancieraId);
  }

  @override
  Future<Map<String, int>> getAgentStats(
    String microfinancieraId,
    String agentId,
  ) async {
    return await _dataSource.getAgentStats(microfinancieraId, agentId);
  }
}
