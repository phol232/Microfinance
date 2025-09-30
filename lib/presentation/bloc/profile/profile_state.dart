import 'package:equatable/equatable.dart';

import '../../../domain/entities/user_profile.dart';

enum ProfileStatus {
  initial,
  loading,
  updating,
  loaded,
  success,
  error,
}

/// Estado único e inmutable del `ProfileBloc`.
class ProfileState extends Equatable {
  const ProfileState({
    this.status = ProfileStatus.initial,
    this.profile,
    this.dniExists,
    this.errorMessage,
  });

  final ProfileStatus status;
  final UserProfile? profile;
  final bool? dniExists;
  final String? errorMessage;

  bool get isLoading =>
      status == ProfileStatus.loading || status == ProfileStatus.updating;

  ProfileState copyWith({
    ProfileStatus? status,
    UserProfile? profile,
    bool keepProfile = true,
    bool? dniExists,
    bool clearDniCheck = false,
    String? errorMessage,
    bool clearError = false,
  }) {
    return ProfileState(
      status: status ?? this.status,
      profile: keepProfile ? (profile ?? this.profile) : profile,
      dniExists: clearDniCheck ? null : (dniExists ?? this.dniExists),
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  static const ProfileState initial = ProfileState();

  @override
  List<Object?> get props => [status, profile?.uid, dniExists, errorMessage];
}
