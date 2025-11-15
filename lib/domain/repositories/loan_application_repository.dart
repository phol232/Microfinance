import '../entities/loan_application.dart';

abstract class LoanApplicationRepository {
  Future<String> createApplication(
    String microfinancieraId,
    LoanApplication application,
  );

  Future<List<LoanApplication>> getAllApplications(String microfinancieraId);

  Future<List<LoanApplication>> getAssignedToAgent(
    String microfinancieraId,
    String agentId, {
    List<String>? statusFilter,
  });

  Future<List<LoanApplication>> getApplicationsByStatus(
    String microfinancieraId,
    List<String> statuses,
  );

  Future<LoanApplication?> getApplicationById(
    String microfinancieraId,
    String applicationId,
  );

  Future<void> takeOwnership(
    String microfinancieraId,
    String applicationId,
    String agentId,
    String agentUserId,
  );

  Future<void> updateApplicationStatus(
    String microfinancieraId,
    String applicationId,
    String newStatus,
    String userId, {
    String? reason,
    Map<String, dynamic>? additionalData,
  });

  Stream<List<LoanApplication>> watchAssignedApplications(
    String microfinancieraId,
    String agentId,
  );

  Stream<List<LoanApplication>> watchApplicationsByStatus(
    String microfinancieraId,
    List<String> statuses,
  );

  Future<Map<String, int>> getApplicationStats(String microfinancieraId);

  Future<Map<String, int>> getAgentStats(
    String microfinancieraId,
    String agentId,
  );
}
