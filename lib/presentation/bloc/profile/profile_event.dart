import 'package:equatable/equatable.dart';

abstract class ProfileEvent extends Equatable {
  const ProfileEvent();

  @override
  List<Object?> get props => [];
}

class ProfileLoadRequested extends ProfileEvent {
  final String uid;

  const ProfileLoadRequested({required this.uid});

  @override
  List<Object?> get props => [uid];
}

class ProfileUpdateRequested extends ProfileEvent {
  final String uid;
  final String microfinancieraId;
  final String membershipId;
  final String? customerId;
  final Map<String, dynamic> updates;

  const ProfileUpdateRequested({
    required this.uid,
    required this.microfinancieraId,
    required this.membershipId,
    this.customerId,
    required this.updates,
  });

  @override
  List<Object?> get props => [
    uid,
    microfinancieraId,
    membershipId,
    customerId,
    updates,
  ];
}

class ProfileCheckDniRequested extends ProfileEvent {
  final String dni;

  const ProfileCheckDniRequested({required this.dni});

  @override
  List<Object?> get props => [dni];
}
