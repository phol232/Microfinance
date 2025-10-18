import '../entities/loan_application.dart';

abstract class IntakeRequestRepository {
  Future<List<LoanApplication>> getAll();
  Future<List<LoanApplication>> getByStatus(String status);
  Future<List<LoanApplication>> getRecent({int limit = 10});
  Future<LoanApplication?> getById(String id);
  Stream<List<LoanApplication>> watchAll();
  Stream<List<LoanApplication>> watchByStatus(String status);
  Future<Map<String, int>> getStatusCounts();
  Future<void> updateStatus(String applicationId, String newStatus);
}
