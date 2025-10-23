import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/logging/app_logger.dart';
import '../../../domain/usecases/loan_application/get_assigned_applications_usecase.dart';
import '../../../domain/usecases/loan_application/get_applications_by_status_usecase.dart';
import '../../../domain/usecases/loan_application/take_ownership_of_application_usecase.dart';
import '../../../domain/usecases/loan_application/update_application_status_usecase.dart';
import '../../../domain/usecases/loan_application/get_application_stats_usecase.dart';
import '../../../domain/usecases/loan_application/get_agent_stats_usecase.dart';
import '../../../domain/core/error/failures.dart';
import 'advisor_inbox_event.dart';
import 'advisor_inbox_state.dart';

class AdvisorInboxBloc extends Bloc<AdvisorInboxEvent, AdvisorInboxState> {
  final GetAssignedApplicationsUseCase _getAssignedApplicationsUseCase;
  final GetApplicationsByStatusUseCase _getApplicationsByStatusUseCase;
  final TakeOwnershipOfApplicationUseCase _takeOwnershipOfApplicationUseCase;
  final UpdateApplicationStatusUseCase _updateApplicationStatusUseCase;
  final GetApplicationStatsUseCase _getApplicationStatsUseCase;
  final GetAgentStatsUseCase _getAgentStatsUseCase;

  AdvisorInboxBloc({
    required GetAssignedApplicationsUseCase getAssignedApplicationsUseCase,
    required GetApplicationsByStatusUseCase getApplicationsByStatusUseCase,
    required TakeOwnershipOfApplicationUseCase takeOwnershipOfApplicationUseCase,
    required UpdateApplicationStatusUseCase updateApplicationStatusUseCase,
    required GetApplicationStatsUseCase getApplicationStatsUseCase,
    required GetAgentStatsUseCase getAgentStatsUseCase,
  }) : _getAssignedApplicationsUseCase = getAssignedApplicationsUseCase,
       _getApplicationsByStatusUseCase = getApplicationsByStatusUseCase,
       _takeOwnershipOfApplicationUseCase = takeOwnershipOfApplicationUseCase,
       _updateApplicationStatusUseCase = updateApplicationStatusUseCase,
       _getApplicationStatsUseCase = getApplicationStatsUseCase,
       _getAgentStatsUseCase = getAgentStatsUseCase,
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

    final result = await _getAssignedApplicationsUseCase(
      microfinancieraId: event.microfinancieraId,
      agentId: event.agentId,
      statusFilter: state.currentStatusFilter.isNotEmpty
          ? state.currentStatusFilter
          : null,
    );

    result.fold(
      (failure) => emit(
        state.copyWith(
          isLoading: false,
          error: _getFailureMessage(failure),
        ),
      ),
      (applications) => emit(
        state.copyWith(applications: applications, isLoading: false),
      ),
    );
  }

  Future<void> _onLoadApplicationsByStatus(
    LoadApplicationsByStatus event,
    Emitter<AdvisorInboxState> emit,
  ) async {
    emit(state.copyWith(isLoading: true, error: null));

    final result = await _getApplicationsByStatusUseCase(
      microfinancieraId: event.microfinancieraId,
      statuses: event.statuses,
    );

    result.fold(
      (failure) => emit(
        state.copyWith(
          isLoading: false,
          error: _getFailureMessage(failure),
        ),
      ),
      (applications) => emit(
        state.copyWith(
          applications: applications,
          currentStatusFilter: event.statuses,
          isLoading: false,
        ),
      ),
    );
  }

  Future<void> _onTakeOwnershipOfApplication(
    TakeOwnershipOfApplication event,
    Emitter<AdvisorInboxState> emit,
  ) async {
    emit(state.copyWith(isTakingOwnership: true, error: null));

    final result = await _takeOwnershipOfApplicationUseCase(
      microfinancieraId: event.microfinancieraId,
      applicationId: event.applicationId,
      agentId: event.agentId,
      agentUserId: event.agentUserId,
    );

    result.fold(
      (failure) => emit(
        state.copyWith(
          isTakingOwnership: false,
          error: _getFailureMessage(failure),
        ),
      ),
      (_) {
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
      },
    );
  }

  Future<void> _onUpdateApplicationStatus(
    UpdateApplicationStatus event,
    Emitter<AdvisorInboxState> emit,
  ) async {
    emit(state.copyWith(isUpdatingStatus: true, error: null));

    final result = await _updateApplicationStatusUseCase(
      microfinancieraId: event.microfinancieraId,
      applicationId: event.applicationId,
      newStatus: event.newStatus,
      userId: event.userId,
      reason: event.reason,
      additionalData: event.additionalData,
    );

    result.fold(
      (failure) => emit(
        state.copyWith(
          isUpdatingStatus: false,
          error: _getFailureMessage(failure),
        ),
      ),
      (_) {
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
      },
    );
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
    if (event.agentId != null) {
      final result = await _getAgentStatsUseCase(
        microfinancieraId: event.microfinancieraId,
        agentId: event.agentId!,
      );

      result.fold(
        (failure) {
          // No mostrar error para stats ya que no es crítico
          AppLogger.error('Error cargando estadísticas de agente', tag: 'AdvisorInboxBloc', error: failure);
        },
        (stats) => emit(state.copyWith(stats: stats)),
      );
    } else {
      final result = await _getApplicationStatsUseCase(
        microfinancieraId: event.microfinancieraId,
      );

      result.fold(
        (failure) {
          // No mostrar error para stats ya que no es crítico
          AppLogger.error('Error cargando estadísticas de aplicaciones', tag: 'AdvisorInboxBloc', error: failure);
        },
        (stats) => emit(state.copyWith(stats: stats)),
      );
    }
  }

  void clearError() {
    emit(state.copyWith(error: null));
  }

  void clearSuccessMessage() {
    emit(state.copyWith(successMessage: null));
  }

  String _getFailureMessage(Failure failure) {
    return switch (failure) {
      ValidationFailure(message: final message) => message,
      NetworkFailure() => 'Error de conexión',
      AuthFailure() => 'Error de autenticación',
      AuthorizationFailure() => 'No autorizado',
      ServerFailure() => 'Error del servidor',
      NotFoundFailure() => 'Recurso no encontrado',
      CacheFailure() => 'Error de caché',
      UnknownFailure() => 'Error desconocido',
      _ => 'Error desconocido',
    };
  }
}
