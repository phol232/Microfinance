import 'package:equatable/equatable.dart';

/// Eventos para el ProfileBloc
abstract class ProfileEvent extends Equatable {
  const ProfileEvent();

  @override
  List<Object?> get props => [];
}

/// Evento para cargar el perfil del usuario
class ProfileLoadRequested extends ProfileEvent {
  final String uid;

  const ProfileLoadRequested({required this.uid});

  @override
  List<Object?> get props => [uid];
}

/// Evento para actualizar el perfil del usuario
class ProfileUpdateRequested extends ProfileEvent {
  final String uid;
  final Map<String, dynamic> updates;

  const ProfileUpdateRequested({required this.uid, required this.updates});

  @override
  List<Object?> get props => [uid, updates];
}

/// Evento para verificar si un DNI existe
class ProfileCheckDniRequested extends ProfileEvent {
  final String dni;

  const ProfileCheckDniRequested({required this.dni});

  @override
  List<Object?> get props => [dni];
}
