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

/// Estado pendiente - usuario registrado pero pendiente de aprobación
class AuthPending extends AuthState {
  final AppUser user;
  final String message;

  const AuthPending({
    required this.user,
    this.message =
        'Tu cuenta está pendiente de aprobación. Te notificaremos cuando sea aprobada.',
  });

  @override
  List<Object?> get props => [user.uid, message];
}

/// Estado cuando se han cargado las microfinancieras
class AuthMicrofinancierasLoaded extends AuthState {
  final List<Microfinanciera> microfinancieras;

  const AuthMicrofinancierasLoaded({required this.microfinancieras});

  @override
  List<Object?> get props => [microfinancieras];
}

/// Estado de acceso no autorizado - usuario no tiene permisos para acceder a la app
///
/// Razones de rechazo:
/// - `invalid_role`: Usuario no tiene rol "analyst"
/// - `missing_role`: Usuario no tiene primaryRoleId definido
/// - `invalid_status`: Usuario no tiene status "approved"
/// - `missing_profile`: No se pudo obtener el perfil del usuario
/// - `validation_error`: Error al validar permisos
class AuthUnauthorized extends AuthState {
  final AppUser user;
  final String reason;
  final String message;

  const AuthUnauthorized({
    required this.user,
    required this.reason,
    required this.message,
  });

  @override
  List<Object?> get props => [user.uid, reason, message];
}
