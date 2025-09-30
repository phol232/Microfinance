import 'package:equatable/equatable.dart';

import '../../../domain/entities/app_user.dart';

/// Eventos base para el AuthBloc
/// Representan todas las acciones que puede realizar el usuario relacionadas con autenticación
abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

/// Evento para verificar el estado de autenticación actual
class AuthCheckRequested extends AuthEvent {
  const AuthCheckRequested();
}

/// Evento para iniciar sesión con email y contraseña
class AuthLoginRequested extends AuthEvent {
  final String email;
  final String password;

  const AuthLoginRequested({required this.email, required this.password});

  @override
  List<Object?> get props => [email, password];
}

/// Evento para registro con datos completos
class AuthRegisterRequested extends AuthEvent {
  final String email;
  final String password;
  final String firstName;
  final String lastName;
  final String dni;
  final String phone;

  const AuthRegisterRequested({
    required this.email,
    required this.password,
    required this.firstName,
    required this.lastName,
    required this.dni,
    required this.phone,
  });

  @override
  List<Object?> get props => [email, password, firstName, lastName, dni, phone];
}

/// Evento para iniciar sesión con Google
class AuthGoogleSignInRequested extends AuthEvent {
  const AuthGoogleSignInRequested();
}

/// Evento para iniciar sesión con Facebook
class AuthFacebookSignInRequested extends AuthEvent {
  const AuthFacebookSignInRequested();
}

/// Evento para iniciar sesión anónima
class AuthAnonymousSignInRequested extends AuthEvent {
  const AuthAnonymousSignInRequested();
}

/// Evento para cerrar sesión
class AuthLogoutRequested extends AuthEvent {
  const AuthLogoutRequested();
}

/// Evento cuando cambia el estado de autenticación (Firebase listener)
class AuthUserChanged extends AuthEvent {
  final AppUser? user;

  const AuthUserChanged({required this.user});

  @override
  List<Object?> get props => [user?.uid];
}
