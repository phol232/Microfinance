import '../entities/loan_application.dart';

abstract class LoanApplicationRepository {
  /// Obtener todas las aplicaciones de una microfinanciera
  Future<List<LoanApplication>> getAllApplications(String microfinancieraId);

  /// Obtener aplicaciones asignadas a un agente específico
  Future<List<LoanApplication>> getAssignedToAgent(
    String microfinancieraId,
    String agentId, {
    List<String>? statusFilter,
  });

  /// Obtener aplicaciones por estado
  Future<List<LoanApplication>> getApplicationsByStatus(
    String microfinancieraId,
    List<String> statuses,
  );

  /// Obtener aplicación específica por ID
  Future<LoanApplication?> getApplicationById(
    String microfinancieraId,
    String applicationId,
  );

  /// Tomar posesión de una aplicación
  Future<void> takeOwnership(
    String microfinancieraId,
    String applicationId,
    String agentId,
    String agentUserId,
  );

  /// Actualizar estado de aplicación
  Future<void> updateApplicationStatus(
    String microfinancieraId,
    String applicationId,
    String newStatus,
    String userId, {
    String? reason,
    Map<String, dynamic>? additionalData,
  });

  /// Stream de aplicaciones asignadas a un agente (tiempo real)
  Stream<List<LoanApplication>> watchAssignedApplications(
    String microfinancieraId,
    String agentId,
  );

  /// Stream de aplicaciones por estado (tiempo real)
  Stream<List<LoanApplication>> watchApplicationsByStatus(
    String microfinancieraId,
    List<String> statuses,
  );

  /// Obtener estadísticas básicas de aplicaciones
  Future<Map<String, int>> getApplicationStats(String microfinancieraId);

  /// Obtener estadísticas por agente
  Future<Map<String, int>> getAgentStats(
    String microfinancieraId,
    String agentId,
  );
}
