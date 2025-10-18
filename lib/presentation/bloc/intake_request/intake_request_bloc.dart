import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/repositories/intake_request_repository.dart';
import 'intake_request_event.dart';
import 'intake_request_state.dart';

class IntakeRequestBloc extends Bloc<IntakeRequestEvent, IntakeRequestState> {
  final IntakeRequestRepository _repository;

  IntakeRequestBloc(this._repository) : super(const IntakeRequestState()) {
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

    try {
      final requests = await _repository.getAll();
      final counts = await _repository.getStatusCounts();

      emit(
        state.copyWith(
          status: IntakeRequestStatus.success,
          requests: requests,
          statusCounts: counts,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: IntakeRequestStatus.error,
          errorMessage: e.toString(),
        ),
      );
    }
  }

  Future<void> _onLoadByStatus(
    IntakeRequestLoadByStatus event,
    Emitter<IntakeRequestState> emit,
  ) async {
    emit(state.copyWith(status: IntakeRequestStatus.loading));

    try {
      final requests = await _repository.getByStatus(event.status);
      final counts = await _repository.getStatusCounts();

      emit(
        state.copyWith(
          status: IntakeRequestStatus.success,
          requests: requests,
          statusCounts: counts,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: IntakeRequestStatus.error,
          errorMessage: e.toString(),
        ),
      );
    }
  }

  Future<void> _onLoadRecent(
    IntakeRequestLoadRecent event,
    Emitter<IntakeRequestState> emit,
  ) async {
    emit(state.copyWith(status: IntakeRequestStatus.loading));

    try {
      final requests = await _repository.getRecent(limit: event.limit);
      final counts = await _repository.getStatusCounts();

      emit(
        state.copyWith(
          status: IntakeRequestStatus.success,
          requests: requests,
          statusCounts: counts,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: IntakeRequestStatus.error,
          errorMessage: e.toString(),
        ),
      );
    }
  }

  Future<void> _onLoadById(
    IntakeRequestLoadById event,
    Emitter<IntakeRequestState> emit,
  ) async {
    emit(state.copyWith(status: IntakeRequestStatus.loading));

    try {
      final request = await _repository.getById(event.id);

      emit(
        state.copyWith(
          status: IntakeRequestStatus.success,
          selectedRequest: request,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: IntakeRequestStatus.error,
          errorMessage: e.toString(),
        ),
      );
    }
  }

  Future<void> _onRefreshRequested(
    IntakeRequestRefreshRequested event,
    Emitter<IntakeRequestState> emit,
  ) async {
    try {
      final requests = await _repository.getAll();
      final counts = await _repository.getStatusCounts();

      emit(
        state.copyWith(
          status: IntakeRequestStatus.success,
          requests: requests,
          statusCounts: counts,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: IntakeRequestStatus.error,
          errorMessage: e.toString(),
        ),
      );
    }
  }
}
