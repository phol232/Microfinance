import 'package:equatable/equatable.dart';

import '../../../domain/entities/app_user.dart';
import '../../../domain/entities/microfinanciera.dart';

/// Estados base para el AuthBloc
/// Representan todos los posibles estados de la autenticación
abstract class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => [];
}

/// Estado inicial - verificando autenticación
class AuthInitial extends AuthState {
  const AuthInitial();
}

/// Estado de carga - procesando una acción de autenticación
class AuthLoading extends AuthState {
  const AuthLoading();
}

/// Estado de carga específico para microfinancieras
class AuthMicrofinancierasLoading extends AuthState {
  const AuthMicrofinancierasLoading();
}

/// Estado autenticado - usuario logueado exitosamente
class AuthAuthenticated extends AuthState {
  final AppUser user;

  const AuthAuthenticated({required this.user});

  @override
  List<Object?> get props => [user.uid];
}

/// Estado no autenticado - usuario no logueado
class AuthUnauthenticated extends AuthState {
  const AuthUnauthenticated();
}

/// Estado de error - ocurrió un error durante la autenticación
class AuthError extends AuthState {
  final String message;
  final String? errorCode;

  const AuthError({required this.message, this.errorCode});

  @override
  List<Object?> get props => [message, errorCode];
}

/// Estado de éxito específico para registro
class AuthRegistrationSuccess extends AuthState {
  final AppUser user;

  const AuthRegistrationSuccess({required this.user});

  @override
  List<Object?> get props => [user.uid];
}

/// Estado cuando se han cargado las microfinancieras
class AuthMicrofinancierasLoaded extends AuthState {
  final List<Microfinanciera> microfinancieras;

  const AuthMicrofinancierasLoaded({required this.microfinancieras});

  @override
  List<Object?> get props => [microfinancieras];
}
