import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/repositories/loan_application_repository.dart';
import 'advisor_inbox_event.dart';
import 'advisor_inbox_state.dart';

class AdvisorInboxBloc extends Bloc<AdvisorInboxEvent, AdvisorInboxState> {
  final LoanApplicationRepository _repository;

  AdvisorInboxBloc({required LoanApplicationRepository repository})
    : _repository = repository,
      super(const AdvisorInboxState()) {
    on<LoadAssignedApplications>(_onLoadAssignedApplications);
    on<LoadApplicationsByStatus>(_onLoadApplicationsByStatus);
    on<TakeOwnershipOfApplication>(_onTakeOwnershipOfApplication);
    on<UpdateApplicationStatus>(_onUpdateApplicationStatus);
    on<FilterByStatus>(_onFilterByStatus);
    on<RefreshApplications>(_onRefreshApplications);
    on<LoadApplicationStats>(_onLoadApplicationStats);
  }

  Future<void> _onLoadAssignedApplications(
    LoadAssignedApplications event,
    Emitter<AdvisorInboxState> emit,
  ) async {
    emit(state.copyWith(isLoading: true, error: null));

    try {
      final applications = await _repository.getAssignedToAgent(
        event.microfinancieraId,
        event.agentId,
        statusFilter: state.currentStatusFilter.isNotEmpty
            ? state.currentStatusFilter
            : null,
      );

      emit(state.copyWith(applications: applications, isLoading: false));
    } catch (e) {
      emit(
        state.copyWith(
          isLoading: false,
          error: 'Error cargando aplicaciones: $e',
        ),
      );
    }
  }

  Future<void> _onLoadApplicationsByStatus(
    LoadApplicationsByStatus event,
    Emitter<AdvisorInboxState> emit,
  ) async {
    emit(state.copyWith(isLoading: true, error: null));

    try {
      final applications = await _repository.getApplicationsByStatus(
        event.microfinancieraId,
        event.statuses,
      );

      emit(
        state.copyWith(
          applications: applications,
          currentStatusFilter: event.statuses,
          isLoading: false,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          isLoading: false,
          error: 'Error cargando aplicaciones: $e',
        ),
      );
    }
  }

  Future<void> _onTakeOwnershipOfApplication(
    TakeOwnershipOfApplication event,
    Emitter<AdvisorInboxState> emit,
  ) async {
    emit(state.copyWith(isTakingOwnership: true, error: null));

    try {
      await _repository.takeOwnership(
        event.microfinancieraId,
        event.applicationId,
        event.agentId,
        event.agentUserId,
      );

      // Recargar aplicaciones después de tomar posesión
      add(
        LoadAssignedApplications(
          microfinancieraId: event.microfinancieraId,
          agentId: event.agentId,
        ),
      );

      emit(
        state.copyWith(
          isTakingOwnership: false,
          successMessage: 'Caso tomado exitosamente',
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          isTakingOwnership: false,
          error: 'Error tomando posesión: $e',
        ),
      );
    }
  }

  Future<void> _onUpdateApplicationStatus(
    UpdateApplicationStatus event,
    Emitter<AdvisorInboxState> emit,
  ) async {
    emit(state.copyWith(isUpdatingStatus: true, error: null));

    try {
      await _repository.updateApplicationStatus(
        event.microfinancieraId,
        event.applicationId,
        event.newStatus,
        event.userId,
        reason: event.reason,
        additionalData: event.additionalData,
      );

      // Recargar aplicaciones después de actualizar estado
      if (state.currentStatusFilter.isNotEmpty) {
        add(
          LoadApplicationsByStatus(
            microfinancieraId: event.microfinancieraId,
            statuses: state.currentStatusFilter,
          ),
        );
      }

      emit(
        state.copyWith(
          isUpdatingStatus: false,
          successMessage: 'Estado actualizado exitosamente',
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          isUpdatingStatus: false,
          error: 'Error actualizando estado: $e',
        ),
      );
    }
  }

  void _onFilterByStatus(
    FilterByStatus event,
    Emitter<AdvisorInboxState> emit,
  ) {
    emit(
      state.copyWith(
        currentStatusFilter: event.statuses,
        error: null,
        successMessage: null,
      ),
    );
  }

  Future<void> _onRefreshApplications(
    RefreshApplications event,
    Emitter<AdvisorInboxState> emit,
  ) async {
    if (event.agentId != null) {
      add(
        LoadAssignedApplications(
          microfinancieraId: event.microfinancieraId,
          agentId: event.agentId!,
        ),
      );
    } else if (state.currentStatusFilter.isNotEmpty) {
      add(
        LoadApplicationsByStatus(
          microfinancieraId: event.microfinancieraId,
          statuses: state.currentStatusFilter,
        ),
      );
    }

    // Recargar estadísticas también
    add(
      LoadApplicationStats(
        microfinancieraId: event.microfinancieraId,
        agentId: event.agentId,
      ),
    );
  }

  Future<void> _onLoadApplicationStats(
    LoadApplicationStats event,
    Emitter<AdvisorInboxState> emit,
  ) async {
    try {
      Map<String, int> stats;

      if (event.agentId != null) {
        stats = await _repository.getAgentStats(
          event.microfinancieraId,
          event.agentId!,
        );
      } else {
        stats = await _repository.getApplicationStats(event.microfinancieraId);
      }

      emit(state.copyWith(stats: stats));
    } catch (e) {
      // No mostrar error para stats ya que no es crítico
      print('Error cargando estadísticas: $e');
    }
  }

  void clearError() {
    emit(state.copyWith(error: null));
  }

  void clearSuccessMessage() {
    emit(state.copyWith(successMessage: null));
  }
}
