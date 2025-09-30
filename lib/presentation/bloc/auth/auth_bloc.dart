import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../domain/entities/app_user.dart';
import '../../../domain/repositories/auth_repository.dart';
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  AuthBloc({required AuthRepository authRepository})
    : _authRepository = authRepository,
      super(const AuthInitial()) {
    on<AuthCheckRequested>(_onAuthCheckRequested);
    on<AuthLoginRequested>(_onAuthLoginRequested);
    on<AuthRegisterRequested>(_onAuthRegisterRequested);
    on<AuthGoogleSignInRequested>(_onAuthGoogleSignInRequested);
    on<AuthFacebookSignInRequested>(_onAuthFacebookSignInRequested);
    on<AuthAnonymousSignInRequested>(_onAuthAnonymousSignInRequested);
    on<AuthLogoutRequested>(_onAuthLogoutRequested);
    on<AuthUserChanged>(_onAuthUserChanged);

    _authStateSubscription = _authRepository.authStateChanges().listen(
      (user) => add(AuthUserChanged(user: user)),
    );
  }

  final AuthRepository _authRepository;
  late final StreamSubscription<AppUser?> _authStateSubscription;

  Future<void> _onAuthCheckRequested(
    AuthCheckRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());

    final user = _authRepository.currentUser;
    if (user != null) {
      emit(AuthAuthenticated(user: user));
    } else {
      emit(const AuthUnauthenticated());
    }
  }

  Future<void> _onAuthLoginRequested(
    AuthLoginRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());

    try {
      final user = await _authRepository.signInWithEmailAndPassword(
        event.email,
        event.password,
      );

      if (user != null) {
        emit(AuthAuthenticated(user: user));
      } else {
        emit(
          const AuthError(
            message: 'Error al iniciar sesión. Verifica tus credenciales.',
            errorCode: 'login_failed',
          ),
        );
      }
    } catch (error) {
      emit(
        AuthError(message: _getErrorMessage(error), errorCode: 'login_error'),
      );
    }
  }

  Future<void> _onAuthRegisterRequested(
    AuthRegisterRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());

    try {
      final user = await _authRepository.registerWithEmailAndPassword(
        email: event.email,
        password: event.password,
        firstName: event.firstName,
        lastName: event.lastName,
        dni: event.dni,
        phone: event.phone,
      );

      if (user != null) {
        emit(AuthRegistrationSuccess(user: user));
      } else {
        emit(
          const AuthError(
            message: 'Error al registrar usuario.',
            errorCode: 'registration_failed',
          ),
        );
      }
    } catch (error) {
      emit(
        AuthError(
          message: _getErrorMessage(error),
          errorCode: 'registration_error',
        ),
      );
    }
  }

  Future<void> _onAuthGoogleSignInRequested(
    AuthGoogleSignInRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());

    try {
      final user = await _authRepository.signInWithGoogle();
      if (user != null) {
        emit(AuthAuthenticated(user: user));
      } else {
        emit(
          const AuthError(
            message: 'Error al iniciar sesión con Google.',
            errorCode: 'google_signin_failed',
          ),
        );
      }
    } catch (error) {
      emit(
        AuthError(
          message: _getErrorMessage(error),
          errorCode: 'google_signin_error',
        ),
      );
    }
  }

  Future<void> _onAuthFacebookSignInRequested(
    AuthFacebookSignInRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());

    try {
      final user = await _authRepository.signInWithFacebook();
      if (user != null) {
        emit(AuthAuthenticated(user: user));
      } else {
        emit(
          const AuthError(
            message: 'Error al iniciar sesión con Facebook.',
            errorCode: 'facebook_signin_failed',
          ),
        );
      }
    } catch (error) {
      emit(
        AuthError(
          message: _getErrorMessage(error),
          errorCode: 'facebook_signin_error',
        ),
      );
    }
  }

  Future<void> _onAuthAnonymousSignInRequested(
    AuthAnonymousSignInRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());

    try {
      final user = await _authRepository.signInAnonymously();
      if (user != null) {
        emit(AuthAuthenticated(user: user));
      } else {
        emit(
          const AuthError(
            message: 'Error al iniciar sesión anónima.',
            errorCode: 'anonymous_signin_failed',
          ),
        );
      }
    } catch (error) {
      emit(
        AuthError(
          message: _getErrorMessage(error),
          errorCode: 'anonymous_signin_error',
        ),
      );
    }
  }

  Future<void> _onAuthLogoutRequested(
    AuthLogoutRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());

    try {
      await _authRepository.signOut();
      emit(const AuthUnauthenticated());
    } catch (error) {
      emit(
        AuthError(message: _getErrorMessage(error), errorCode: 'logout_error'),
      );
    }
  }

  void _onAuthUserChanged(AuthUserChanged event, Emitter<AuthState> emit) {
    final user = event.user;
    if (user != null) {
      emit(AuthAuthenticated(user: user));
    } else {
      emit(const AuthUnauthenticated());
    }
  }

  String _getErrorMessage(Object error) {
    if (error is FirebaseAuthException) {
      switch (error.code) {
        case 'user-not-found':
          return 'No se encontró una cuenta con este email.';
        case 'wrong-password':
          return 'Contraseña incorrecta.';
        case 'email-already-in-use':
          return 'Este email ya está registrado.';
        case 'weak-password':
          return 'La contraseña es muy débil.';
        case 'invalid-email':
          return 'El formato del email es inválido.';
        case 'too-many-requests':
          return 'Demasiados intentos. Intenta más tarde.';
        default:
          return error.message ?? 'Error desconocido.';
      }
    }

    if (error is Exception) {
      return error.toString().replaceFirst('Exception: ', '');
    }

    return error.toString();
  }

  @override
  Future<void> close() {
    _authStateSubscription.cancel();
    return super.close();
  }
}
