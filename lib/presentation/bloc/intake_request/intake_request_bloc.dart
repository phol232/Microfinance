import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/usecases/intake_request/get_all_intake_requests_usecase.dart';
import '../../../domain/usecases/intake_request/get_intake_requests_by_status_usecase.dart';
import '../../../domain/usecases/intake_request/get_recent_intake_requests_usecase.dart';
import '../../../domain/usecases/intake_request/get_intake_request_by_id_usecase.dart';
import '../../../domain/usecases/intake_request/get_intake_request_status_counts_usecase.dart';
import '../../../domain/core/error/failures.dart';
import 'intake_request_event.dart';
import 'intake_request_state.dart';

class IntakeRequestBloc extends Bloc<IntakeRequestEvent, IntakeRequestState> {
  final GetAllIntakeRequestsUseCase _getAllIntakeRequestsUseCase;
  final GetIntakeRequestsByStatusUseCase _getIntakeRequestsByStatusUseCase;
  final GetRecentIntakeRequestsUseCase _getRecentIntakeRequestsUseCase;
  final GetIntakeRequestByIdUseCase _getIntakeRequestByIdUseCase;
  final GetIntakeRequestStatusCountsUseCase _getIntakeRequestStatusCountsUseCase;

  IntakeRequestBloc(
    this._getAllIntakeRequestsUseCase,
    this._getIntakeRequestsByStatusUseCase,
    this._getRecentIntakeRequestsUseCase,
    this._getIntakeRequestByIdUseCase,
    this._getIntakeRequestStatusCountsUseCase,
  ) : super(const IntakeRequestState()) {
    on<IntakeRequestLoadRequested>(_onLoadRequested);
    on<IntakeRequestLoadByStatus>(_onLoadByStatus);
    on<IntakeRequestLoadRecent>(_onLoadRecent);
    on<IntakeRequestLoadById>(_onLoadById);
    on<IntakeRequestRefreshRequested>(_onRefreshRequested);
  }

  Future<void> _onLoadRequested(
    IntakeRequestLoadRequested event,
    Emitter<IntakeRequestState> emit,
  ) async {
    emit(state.copyWith(status: IntakeRequestStatus.loading));

    final requestsResult = await _getAllIntakeRequestsUseCase(const GetAllIntakeRequestsParams());
    final countsResult = await _getIntakeRequestStatusCountsUseCase(const GetIntakeRequestStatusCountsParams());

    requestsResult.fold(
      (failure) => emit(
        state.copyWith(
          status: IntakeRequestStatus.error,
          errorMessage: _getFailureMessage(failure),
        ),
      ),
      (requests) => countsResult.fold(
        (failure) => emit(
          state.copyWith(
            status: IntakeRequestStatus.error,
            errorMessage: _getFailureMessage(failure),
          ),
        ),
        (counts) => emit(
          state.copyWith(
            status: IntakeRequestStatus.success,
            requests: requests,
            statusCounts: counts,
          ),
        ),
      ),
    );
  }

  Future<void> _onLoadByStatus(
    IntakeRequestLoadByStatus event,
    Emitter<IntakeRequestState> emit,
  ) async {
    emit(state.copyWith(status: IntakeRequestStatus.loading));

    final requestsResult = await _getIntakeRequestsByStatusUseCase(
      GetIntakeRequestsByStatusParams(status: event.status),
    );
    final countsResult = await _getIntakeRequestStatusCountsUseCase(const GetIntakeRequestStatusCountsParams());

    requestsResult.fold(
      (failure) => emit(
        state.copyWith(
          status: IntakeRequestStatus.error,
          errorMessage: _getFailureMessage(failure),
        ),
      ),
      (requests) => countsResult.fold(
        (failure) => emit(
          state.copyWith(
            status: IntakeRequestStatus.error,
            errorMessage: _getFailureMessage(failure),
          ),
        ),
        (counts) => emit(
          state.copyWith(
            status: IntakeRequestStatus.success,
            requests: requests,
            statusCounts: counts,
          ),
        ),
      ),
    );
  }

  Future<void> _onLoadRecent(
    IntakeRequestLoadRecent event,
    Emitter<IntakeRequestState> emit,
  ) async {
    emit(state.copyWith(status: IntakeRequestStatus.loading));

    final requestsResult = await _getRecentIntakeRequestsUseCase(
      GetRecentIntakeRequestsParams(limit: event.limit),
    );
    final countsResult = await _getIntakeRequestStatusCountsUseCase(const GetIntakeRequestStatusCountsParams());

    requestsResult.fold(
      (failure) => emit(
        state.copyWith(
          status: IntakeRequestStatus.error,
          errorMessage: _getFailureMessage(failure),
        ),
      ),
      (requests) => countsResult.fold(
        (failure) => emit(
          state.copyWith(
            status: IntakeRequestStatus.error,
            errorMessage: _getFailureMessage(failure),
          ),
        ),
        (counts) => emit(
          state.copyWith(
            status: IntakeRequestStatus.success,
            requests: requests,
            statusCounts: counts,
          ),
        ),
      ),
    );
  }

  Future<void> _onLoadById(
    IntakeRequestLoadById event,
    Emitter<IntakeRequestState> emit,
  ) async {
    emit(state.copyWith(status: IntakeRequestStatus.loading));

    final result = await _getIntakeRequestByIdUseCase(
      GetIntakeRequestByIdParams(id: event.id),
    );

    result.fold(
      (failure) => emit(
        state.copyWith(
          status: IntakeRequestStatus.error,
          errorMessage: _getFailureMessage(failure),
        ),
      ),
      (request) => emit(
        state.copyWith(
          status: IntakeRequestStatus.success,
          selectedRequest: request,
        ),
      ),
    );
  }

  Future<void> _onRefreshRequested(
    IntakeRequestRefreshRequested event,
    Emitter<IntakeRequestState> emit,
  ) async {
    final requestsResult = await _getAllIntakeRequestsUseCase(const GetAllIntakeRequestsParams());
    final countsResult = await _getIntakeRequestStatusCountsUseCase(const GetIntakeRequestStatusCountsParams());

    requestsResult.fold(
      (failure) => emit(
        state.copyWith(
          status: IntakeRequestStatus.error,
          errorMessage: _getFailureMessage(failure),
        ),
      ),
      (requests) => countsResult.fold(
        (failure) => emit(
          state.copyWith(
            status: IntakeRequestStatus.error,
            errorMessage: _getFailureMessage(failure),
          ),
        ),
        (counts) => emit(
          state.copyWith(
            status: IntakeRequestStatus.success,
            requests: requests,
            statusCounts: counts,
          ),
        ),
      ),
    );
  }

  String _getFailureMessage(Failure failure) {
    return switch (failure) {
      NetworkFailure _ => 'Error de conexión. Verifica tu internet.',
      AuthorizationFailure _ => 'No tienes permisos para realizar esta acción.',
      AuthFailure _ => 'Error de autenticación.',
      ServerFailure _ => 'Error del servidor. Intenta más tarde.',
      NotFoundFailure _ => 'Información no encontrada.',
      CacheFailure _ => 'Error de almacenamiento local.',
      ValidationFailure failure => failure.message,
      UnknownFailure _ => 'Error inesperado. Intenta nuevamente.',
      _ => 'Error desconocido: ${failure.message}',
    };
  }
}
