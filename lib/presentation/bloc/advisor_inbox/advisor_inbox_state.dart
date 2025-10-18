import 'package:equatable/equatable.dart';
import '../../../domain/entities/loan_application.dart';

class AdvisorInboxState extends Equatable {
  final List<LoanApplication> applications;
  final Map<String, int> stats;
  final List<String> currentStatusFilter;
  final bool isLoading;
  final bool isTakingOwnership;
  final bool isUpdatingStatus;
  final String? error;
  final String? successMessage;

  const AdvisorInboxState({
    this.applications = const [],
    this.stats = const {},
    this.currentStatusFilter = const [],
    this.isLoading = false,
    this.isTakingOwnership = false,
    this.isUpdatingStatus = false,
    this.error,
    this.successMessage,
  });

  AdvisorInboxState copyWith({
    List<LoanApplication>? applications,
    Map<String, int>? stats,
    List<String>? currentStatusFilter,
    bool? isLoading,
    bool? isTakingOwnership,
    bool? isUpdatingStatus,
    String? error,
    String? successMessage,
  }) {
    return AdvisorInboxState(
      applications: applications ?? this.applications,
      stats: stats ?? this.stats,
      currentStatusFilter: currentStatusFilter ?? this.currentStatusFilter,
      isLoading: isLoading ?? this.isLoading,
      isTakingOwnership: isTakingOwnership ?? this.isTakingOwnership,
      isUpdatingStatus: isUpdatingStatus ?? this.isUpdatingStatus,
      error: error,
      successMessage: successMessage,
    );
  }

  // Estados filtrados
  List<LoanApplication> get filteredApplications {
    if (currentStatusFilter.isEmpty) return applications;
    
    return applications
        .where((app) => currentStatusFilter.contains(app.status))
        .toList();
  }

  // Aplicaciones que puede tomar
  List<LoanApplication> get availableApplications {
    return applications.where((app) => 
        app.status == 'routed' && 
        app.routing?.agentId == null
    ).toList();
  }

  // Aplicaciones que ya tiene asignadas
  List<LoanApplication> get assignedApplications {
    return applications.where((app) => app.status == 'in_review').toList();
  }

  // Contadores por estado
  int get receivedCount => stats['received'] ?? 0;
  int get routedCount => stats['routed'] ?? 0;
  int get inReviewCount => stats['in_review'] ?? 0;
  int get approvedCount => stats['approved'] ?? 0;
  int get rejectedCount => stats['rejected'] ?? 0;

  @override
  List<Object?> get props => [
        applications,
        stats,
        currentStatusFilter,
        isLoading,
        isTakingOwnership,
        isUpdatingStatus,
        error,
        successMessage,
      ];
}
