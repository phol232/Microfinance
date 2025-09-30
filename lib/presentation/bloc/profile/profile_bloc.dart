import 'package:bloc/bloc.dart';

import '../../../domain/repositories/auth_repository.dart';
import 'profile_event.dart';
import 'profile_state.dart';

/// BLoC responsable de orquestar los flujos relacionados con el perfil de usuario.
class ProfileBloc extends Bloc<ProfileEvent, ProfileState> {
  ProfileBloc({required AuthRepository authRepository})
      : _authRepository = authRepository,
        super(const ProfileInitial()) {
    on<ProfileLoadRequested>(_onProfileLoadRequested);
    on<ProfileUpdateRequested>(_onProfileUpdateRequested);
    on<ProfileCheckDniRequested>(_onProfileCheckDniRequested);
  }

  final AuthRepository _authRepository;

  Future<void> _onProfileLoadRequested(
    ProfileLoadRequested event,
    Emitter<ProfileState> emit,
  ) async {
    emit(const ProfileLoading());

    try {
      final profile = await _authRepository.fetchUserProfile(event.uid);
      if (profile != null) {
        emit(ProfileLoaded(profile: profile));
      } else {
        emit(const ProfileError(message: 'No se pudo cargar el perfil'));
      }
    } catch (error) {
      emit(ProfileError(message: 'Error al cargar perfil: $error'));
    }
  }

  Future<void> _onProfileUpdateRequested(
    ProfileUpdateRequested event,
    Emitter<ProfileState> emit,
  ) async {
    emit(const ProfileLoading());

    try {
      await _authRepository.updateUserProfile(event.uid, event.updates);
      final updatedProfile = await _authRepository.fetchUserProfile(event.uid);

      if (updatedProfile != null) {
        emit(ProfileUpdateSuccess(profile: updatedProfile));
      } else {
        emit(
          const ProfileError(message: 'Error al recargar perfil actualizado'),
        );
      }
    } catch (error) {
      emit(ProfileError(message: 'Error al actualizar perfil: $error'));
    }
  }

  Future<void> _onProfileCheckDniRequested(
    ProfileCheckDniRequested event,
    Emitter<ProfileState> emit,
  ) async {
    try {
      final exists = await _authRepository.checkDniExists(event.dni);
      emit(ProfileDniCheckResult(exists: exists));
    } catch (error) {
      emit(ProfileError(message: 'Error al verificar DNI: $error'));
    }
  }
}
