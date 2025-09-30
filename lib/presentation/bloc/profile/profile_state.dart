import 'package:equatable/equatable.dart';

import '../../../domain/entities/user_profile.dart';

/// Estados para el ProfileBloc
abstract class ProfileState extends Equatable {
  const ProfileState();

  @override
  List<Object?> get props => [];
}

/// Estado inicial
class ProfileInitial extends ProfileState {
  const ProfileInitial();
}

/// Estado de carga
class ProfileLoading extends ProfileState {
  const ProfileLoading();
}

/// Estado con perfil cargado
class ProfileLoaded extends ProfileState {
  final UserProfile profile;

  const ProfileLoaded({required this.profile});

  @override
  List<Object?> get props => [profile.uid];
}

/// Estado de error
class ProfileError extends ProfileState {
  final String message;

  const ProfileError({required this.message});

  @override
  List<Object?> get props => [message];
}

/// Estado de actualización exitosa
class ProfileUpdateSuccess extends ProfileState {
  final UserProfile profile;

  const ProfileUpdateSuccess({required this.profile});

  @override
  List<Object?> get props => [profile.uid];
}

/// Estado de verificación de DNI
class ProfileDniCheckResult extends ProfileState {
  final bool exists;

  const ProfileDniCheckResult({required this.exists});

  @override
  List<Object?> get props => [exists];
}
