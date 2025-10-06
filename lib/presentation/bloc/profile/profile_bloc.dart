import 'package:bloc/bloc.dart';

import '../../../domain/repositories/auth_repository.dart';
import 'profile_event.dart';
import 'profile_state.dart';

class ProfileBloc extends Bloc<ProfileEvent, ProfileState> {
  ProfileBloc({required AuthRepository authRepository})
    : _authRepository = authRepository,
      super(ProfileState.initial) {
    on<ProfileLoadRequested>(_onProfileLoadRequested);
    on<ProfileUpdateRequested>(_onProfileUpdateRequested);
    on<ProfileCheckDniRequested>(_onProfileCheckDniRequested);
  }

  final AuthRepository _authRepository;

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

    try {
      final profile = await _authRepository.fetchUserProfile(event.uid);
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
    } catch (error) {
      emit(
        state.copyWith(
          status: ProfileStatus.error,
          errorMessage: 'Error al cargar perfil: $error',
        ),
      );
    }
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

    try {
      await _authRepository.updateUserProfile(
        uid: event.uid,
        microfinancieraId: event.microfinancieraId,
        membershipId: event.membershipId,
        customerId: event.customerId,
        updates: event.updates,
      );
      final updatedProfile = await _authRepository.fetchUserProfile(event.uid);

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
    } catch (error) {
      emit(
        state.copyWith(
          status: ProfileStatus.error,
          errorMessage: 'Error al actualizar perfil: $error',
        ),
      );
    }
  }

  Future<void> _onProfileCheckDniRequested(
    ProfileCheckDniRequested event,
    Emitter<ProfileState> emit,
  ) async {
    try {
      final exists = await _authRepository.checkDniExists(event.dni);
      emit(state.copyWith(dniExists: exists, clearError: true));
    } catch (error) {
      emit(
        state.copyWith(
          status: ProfileStatus.error,
          errorMessage: 'Error al verificar DNI: $error',
        ),
      );
    }
  }
}
