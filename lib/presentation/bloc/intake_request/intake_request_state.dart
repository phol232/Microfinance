import 'package:equatable/equatable.dart';
import '../../../domain/entities/loan_application.dart';

enum IntakeRequestStatus { initial, loading, success, error }

class IntakeRequestState extends Equatable {
  final IntakeRequestStatus status;
  final List<LoanApplication> requests;
  final LoanApplication? selectedRequest;
  final Map<String, int> statusCounts;
  final String? errorMessage;

  const IntakeRequestState({
    this.status = IntakeRequestStatus.initial,
    this.requests = const [],
    this.selectedRequest,
    this.statusCounts = const {},
    this.errorMessage,
  });

  IntakeRequestState copyWith({
    IntakeRequestStatus? status,
    List<LoanApplication>? requests,
    LoanApplication? selectedRequest,
    Map<String, int>? statusCounts,
    String? errorMessage,
  }) {
    return IntakeRequestState(
      status: status ?? this.status,
      requests: requests ?? this.requests,
      selectedRequest: selectedRequest ?? this.selectedRequest,
      statusCounts: statusCounts ?? this.statusCounts,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [
    status,
    requests,
    selectedRequest,
    statusCounts,
    errorMessage,
  ];
}
