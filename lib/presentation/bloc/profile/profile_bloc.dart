import 'package:bloc/bloc.dart';

import '../../../domain/usecases/profile/get_user_profile_usecase.dart';
import '../../../domain/usecases/profile/update_user_profile_usecase.dart';
import '../../../domain/usecases/profile/check_dni_exists_usecase.dart';
import '../../../domain/core/error/failures.dart';
import 'profile_event.dart';
import 'profile_state.dart';

class ProfileBloc extends Bloc<ProfileEvent, ProfileState> {
  ProfileBloc({
    required GetUserProfileUseCase getUserProfileUseCase,
    required UpdateUserProfileUseCase updateUserProfileUseCase,
    required CheckDniExistsUseCase checkDniExistsUseCase,
  }) : _getUserProfileUseCase = getUserProfileUseCase,
       _updateUserProfileUseCase = updateUserProfileUseCase,
       _checkDniExistsUseCase = checkDniExistsUseCase,
       super(ProfileState.initial) {
    on<ProfileLoadRequested>(_onProfileLoadRequested);
    on<ProfileUpdateRequested>(_onProfileUpdateRequested);
    on<ProfileCheckDniRequested>(_onProfileCheckDniRequested);
  }

  final GetUserProfileUseCase _getUserProfileUseCase;
  final UpdateUserProfileUseCase _updateUserProfileUseCase;
  final CheckDniExistsUseCase _checkDniExistsUseCase;

  Future<void> _onProfileLoadRequested(
    ProfileLoadRequested event,
    Emitter<ProfileState> emit,
  ) async {
    emit(
      state.copyWith(
        status: ProfileStatus.loading,
        clearError: true,
        clearDniCheck: true,
      ),
    );

    final result = await _getUserProfileUseCase(
      GetUserProfileParams(uid: event.uid),
    );

    result.fold(
      (failure) => emit(
        state.copyWith(
          status: ProfileStatus.error,
          errorMessage: _getFailureMessage(failure),
        ),
      ),
      (profile) {
        if (profile != null) {
          emit(
            state.copyWith(
              status: ProfileStatus.loaded,
              profile: profile,
              clearError: true,
              clearDniCheck: true,
            ),
          );
        } else {
          emit(
            state.copyWith(
              status: ProfileStatus.error,
              errorMessage: 'No se pudo cargar el perfil',
            ),
          );
        }
      },
    );
  }

  Future<void> _onProfileUpdateRequested(
    ProfileUpdateRequested event,
    Emitter<ProfileState> emit,
  ) async {
    emit(
      state.copyWith(
        status: ProfileStatus.updating,
        clearError: true,
        clearDniCheck: true,
      ),
    );

    final updateResult = await _updateUserProfileUseCase(
      UpdateUserProfileParams(
        uid: event.uid,
        microfinancieraId: event.microfinancieraId,
        membershipId: event.membershipId,
        customerId: event.customerId,
        updates: event.updates,
      ),
    );

    await updateResult.fold(
      (failure) async => emit(
        state.copyWith(
          status: ProfileStatus.error,
          errorMessage: _getFailureMessage(failure),
        ),
      ),
      (_) async {
        // Recargar el perfil actualizado
        final profileResult = await _getUserProfileUseCase(
          GetUserProfileParams(uid: event.uid),
        );

        profileResult.fold(
          (failure) => emit(
            state.copyWith(
              status: ProfileStatus.error,
              errorMessage: 'Error al recargar perfil: ${_getFailureMessage(failure)}',
            ),
          ),
          (updatedProfile) {
            if (updatedProfile != null) {
              emit(
                state.copyWith(
                  status: ProfileStatus.success,
                  profile: updatedProfile,
                  clearError: true,
                  clearDniCheck: true,
                ),
              );
            } else {
              emit(
                state.copyWith(
                  status: ProfileStatus.error,
                  errorMessage: 'Error al recargar perfil actualizado',
                ),
              );
            }
          },
        );
      },
    );
  }

  Future<void> _onProfileCheckDniRequested(
    ProfileCheckDniRequested event,
    Emitter<ProfileState> emit,
  ) async {
    final result = await _checkDniExistsUseCase(
      CheckDniExistsParams(dni: event.dni),
    );

    result.fold(
      (failure) => emit(
        state.copyWith(
          status: ProfileStatus.error,
          errorMessage: _getFailureMessage(failure),
        ),
      ),
      (exists) => emit(
        state.copyWith(
          dniExists: exists,
          clearError: true,
        ),
      ),
    );
  }

  String _getFailureMessage(Failure failure) {
    return switch (failure) {
      ValidationFailure() => failure.message,
      NetworkFailure() => 'Error de conexión. Verifica tu internet.',
      AuthFailure() => failure.message,
      AuthorizationFailure() => failure.message,
      UnknownFailure() => failure.message,
      _ => 'Error inesperado',
    };
  }
}
