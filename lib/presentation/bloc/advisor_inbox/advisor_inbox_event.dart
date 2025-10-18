import 'package:equatable/equatable.dart';

abstract class AdvisorInboxEvent extends Equatable {
  const AdvisorInboxEvent();

  @override
  List<Object?> get props => [];
}

class LoadAssignedApplications extends AdvisorInboxEvent {
  final String microfinancieraId;
  final String agentId;

  const LoadAssignedApplications({
    required this.microfinancieraId,
    required this.agentId,
  });

  @override
  List<Object> get props => [microfinancieraId, agentId];
}

class LoadApplicationsByStatus extends AdvisorInboxEvent {
  final String microfinancieraId;
  final List<String> statuses;

  const LoadApplicationsByStatus({
    required this.microfinancieraId,
    required this.statuses,
  });

  @override
  List<Object> get props => [microfinancieraId, statuses];
}

class TakeOwnershipOfApplication extends AdvisorInboxEvent {
  final String microfinancieraId;
  final String applicationId;
  final String agentId;
  final String agentUserId;

  const TakeOwnershipOfApplication({
    required this.microfinancieraId,
    required this.applicationId,
    required this.agentId,
    required this.agentUserId,
  });

  @override
  List<Object> get props => [microfinancieraId, applicationId, agentId, agentUserId];
}

class UpdateApplicationStatus extends AdvisorInboxEvent {
  final String microfinancieraId;
  final String applicationId;
  final String newStatus;
  final String userId;
  final String? reason;
  final Map<String, dynamic>? additionalData;

  const UpdateApplicationStatus({
    required this.microfinancieraId,
    required this.applicationId,
    required this.newStatus,
    required this.userId,
    this.reason,
    this.additionalData,
  });

  @override
  List<Object?> get props => [
        microfinancieraId,
        applicationId,
        newStatus,
        userId,
        reason,
        additionalData,
      ];
}

class FilterByStatus extends AdvisorInboxEvent {
  final List<String> statuses;

  const FilterByStatus(this.statuses);

  @override
  List<Object> get props => [statuses];
}

class RefreshApplications extends AdvisorInboxEvent {
  final String microfinancieraId;
  final String? agentId;

  const RefreshApplications({
    required this.microfinancieraId,
    this.agentId,
  });

  @override
  List<Object?> get props => [microfinancieraId, agentId];
}

class LoadApplicationStats extends AdvisorInboxEvent {
  final String microfinancieraId;
  final String? agentId;

  const LoadApplicationStats({
    required this.microfinancieraId,
    this.agentId,
  });

  @override
  List<Object?> get props => [microfinancieraId, agentId];
}
