import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:flutter/foundation.dart';

import '../../../domain/entities/app_user.dart';
import '../../../domain/entities/user_profile.dart';
import '../../../domain/repositories/auth_repository.dart';
import '../../../domain/usecases/auth/login_user_usecase.dart';
import '../../../domain/usecases/auth/register_user_usecase.dart';
import '../../../domain/usecases/auth/logout_user_usecase.dart';
import '../../../domain/usecases/auth/get_current_user_usecase.dart';
import '../../../domain/usecases/auth/get_microfinancieras_usecase.dart';
import '../../../domain/usecases/auth/google_signin_usecase.dart';
import '../../../domain/usecases/auth/anonymous_signin_usecase.dart';
import '../../../domain/usecases/auth/validate_user_access_usecase.dart';
import '../../../domain/core/error/failures.dart';
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  AuthBloc({
    required AuthRepository authRepository,
    required LoginUserUseCase loginUserUseCase,
    required RegisterUserUseCase registerUserUseCase,
    required LogoutUserUseCase logoutUserUseCase,
    required GetCurrentUserUseCase getCurrentUserUseCase,
    required GetMicrofinancierasUseCase getMicrofinancierasUseCase,
    required GoogleSignInUseCase googleSignInUseCase,
    required AnonymousSignInUseCase anonymousSignInUseCase,
    required ValidateUserAccessUseCase validateUserAccessUseCase,
  }) : _authRepository = authRepository,
       _loginUserUseCase = loginUserUseCase,
       _registerUserUseCase = registerUserUseCase,
       _logoutUserUseCase = logoutUserUseCase,
       _getCurrentUserUseCase = getCurrentUserUseCase,
       _getMicrofinancierasUseCase = getMicrofinancierasUseCase,
       _googleSignInUseCase = googleSignInUseCase,
       _anonymousSignInUseCase = anonymousSignInUseCase,
       _validateUserAccessUseCase = validateUserAccessUseCase,
       super(const AuthInitial()) {
    on<AuthCheckRequested>(_onAuthCheckRequested);
    on<AuthLoginRequested>(_onAuthLoginRequested);
    on<AuthRegisterRequested>(_onAuthRegisterRequested);
    on<AuthGoogleSignInRequested>(_onAuthGoogleSignInRequested);
    on<AuthFacebookSignInRequested>(_onAuthFacebookSignInRequested);
    on<AuthAnonymousSignInRequested>(_onAuthAnonymousSignInRequested);
    on<AuthLogoutRequested>(_onAuthLogoutRequested);
    on<AuthUserChanged>(_onAuthUserChanged);
    on<AuthLoadMicrofinancierasRequested>(_onAuthLoadMicrofinancierasRequested);

    _authStateSubscription = _authRepository.authStateChanges().listen(
      (user) => add(AuthUserChanged(user: user)),
    );
  }

  final AuthRepository _authRepository;
  final LoginUserUseCase _loginUserUseCase;
  final RegisterUserUseCase _registerUserUseCase;
  final LogoutUserUseCase _logoutUserUseCase;
  final GetCurrentUserUseCase _getCurrentUserUseCase;
  final GetMicrofinancierasUseCase _getMicrofinancierasUseCase;
  final GoogleSignInUseCase _googleSignInUseCase;
  final AnonymousSignInUseCase _anonymousSignInUseCase;
  final ValidateUserAccessUseCase _validateUserAccessUseCase;
  late final StreamSubscription<AppUser?> _authStateSubscription;

  Future<void> _onAuthCheckRequested(
    AuthCheckRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());

    final result = await _getCurrentUserUseCase();

    result.fold(
      (failure) => emit(
        AuthError(
          message: _getFailureMessage(failure),
          errorCode: 'auth_check_error',
        ),
      ),
      (user) async {
        if (user != null) {
          // Verificar el estado del usuario antes de emitir AuthAuthenticated
          await _checkUserStatusAndEmit(user, emit);
        } else {
          emit(const AuthUnauthenticated());
        }
      },
    );
  }

  Future<void> _onAuthLoginRequested(
    AuthLoginRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());

    final params = LoginParams(
      email: event.email,
      password: event.password,
      microfinancieraId: event.microfinancieraId,
    );

    final result = await _loginUserUseCase(params);

    result.fold(
      (failure) => emit(
        AuthError(
          message: _getFailureMessage(failure),
          errorCode: 'login_error',
        ),
      ),
      (loginResult) async {
        // ✅ OPTIMIZACIÓN: Usar perfil cacheado del LoginResult
        // Esto evita hacer otra consulta a Firestore
        final user = loginResult.user;
        if (user == null) {
          emit(
            const AuthError(
              message: 'Error al obtener usuario',
              errorCode: 'login_error',
            ),
          );
          return;
        }

        final appUser = AppUser(
          uid: user.uid,
          email: user.email,
          displayName: user.displayName,
          photoUrl: user.photoURL,
        );

        // Verificar el estado del usuario usando el perfil cacheado
        await _checkUserStatusAndEmit(
          appUser,
          emit,
          cachedProfile: loginResult.profile,
        );
      },
    );
  }

  Future<void> _onAuthRegisterRequested(
    AuthRegisterRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());

    final params = RegisterParams(
      email: event.email,
      password: event.password,
      firstName: event.firstName,
      lastName: event.lastName,
      dni: event.dni,
      phone: event.phone,
      microfinancieraId: event.microfinancieraId,
      roles: event.roles,
    );

    final result = await _registerUserUseCase(params);

    result.fold(
      (failure) => emit(
        AuthError(
          message: _getFailureMessage(failure),
          errorCode: 'registration_error',
        ),
      ),
      (user) async {
        // Verificar el estado del usuario después del registro
        await _checkUserStatusAndEmit(user, emit);
      },
    );
  }

  Future<void> _onAuthGoogleSignInRequested(
    AuthGoogleSignInRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());

    final params = GoogleSignInParams(
      microfinancieraId: event.microfinancieraId,
      roles: event.roles,
    );

    final result = await _googleSignInUseCase(params);

    result.fold(
      (failure) => emit(
        AuthError(
          message: _getFailureMessage(failure),
          errorCode: 'google_signin_error',
        ),
      ),
      (user) async {
        // Verificar el estado del usuario después del login con Google
        await _checkUserStatusAndEmit(user, emit);
      },
    );
  }

  /// Verifica el estado del usuario y emite el estado correspondiente
  /// ✅ OPTIMIZACIÓN: Acepta perfil cacheado opcional
  Future<void> _checkUserStatusAndEmit(
    AppUser user,
    Emitter<AuthState> emit, {
    UserProfile? cachedProfile,
  }) async {
    await _validateUserAccess(user, emit, cachedProfile: cachedProfile);
  }

  /// Valida el acceso del usuario basado en rol y status usando el UseCase
  /// ✅ OPTIMIZACIÓN: Acepta perfil cacheado opcional
  Future<void> _validateUserAccess(
    AppUser user,
    Emitter<AuthState> emit, {
    UserProfile? cachedProfile,
  }) async {
    final params = ValidateUserAccessParams(
      user: user,
      cachedProfile: cachedProfile,
    );
    final result = await _validateUserAccessUseCase(params);

    result.fold(
      // En caso de Failure (error técnico), denegar acceso por seguridad
      (failure) {
        debugPrint('❌ RBAC: Error al validar acceso: ${failure.message}');
        emit(
          AuthUnauthorized(
            user: user,
            reason: 'validation_error',
            message: 'Error al verificar permisos. Intenta nuevamente.',
          ),
        );
      },
      // En caso de éxito, procesar el resultado de la validación
      (validation) {
        if (validation.isAuthorized) {
          debugPrint(
            '✅ RBAC: Usuario ${user.uid} autorizado (analyst + approved)',
          );
          emit(AuthAuthenticated(user: user));
        } else if (validation.isPending) {
          debugPrint(
            '⏳ RBAC: Usuario ${user.uid} está pendiente de aprobación',
          );
          emit(AuthPending(user: user, message: validation.message ?? ''));
        } else if (validation.isRejected) {
          debugPrint('❌ RBAC: Usuario ${user.uid} fue rechazado');
          emit(
            AuthError(
              message: validation.message ?? 'Tu cuenta ha sido rechazada.',
              errorCode: 'account_rejected',
            ),
          );
        } else if (validation.isUnauthorized) {
          debugPrint(
            '❌ RBAC: Usuario ${user.uid} no autorizado - ${validation.reason}',
          );
          emit(
            AuthUnauthorized(
              user: user,
              reason: validation.reason ?? 'unknown',
              message: validation.message ?? 'Acceso no autorizado.',
            ),
          );
        }
      },
    );
  }

  Future<void> _onAuthFacebookSignInRequested(
    AuthFacebookSignInRequested event,
    Emitter<AuthState> emit,
  ) async {
    // Facebook login temporalmente deshabilitado
    emit(
      const AuthError(
        message: 'El inicio de sesión con Facebook no está disponible.',
        errorCode: 'facebook_disabled',
      ),
    );
  }

  Future<void> _onAuthAnonymousSignInRequested(
    AuthAnonymousSignInRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());

    final result = await _anonymousSignInUseCase();

    result.fold(
      (failure) => emit(
        AuthError(
          message: _getFailureMessage(failure),
          errorCode: 'anonymous_signin_error',
        ),
      ),
      (user) async {
        // Verificar el estado del usuario antes de emitir AuthAuthenticated
        await _checkUserStatusAndEmit(user, emit);
      },
    );
  }

  Future<void> _onAuthLogoutRequested(
    AuthLogoutRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());

    final result = await _logoutUserUseCase();

    result.fold(
      (failure) => emit(
        AuthError(
          message: _getFailureMessage(failure),
          errorCode: 'logout_error',
        ),
      ),
      (_) => emit(const AuthUnauthenticated()),
    );
  }

  Future<void> _onAuthUserChanged(
    AuthUserChanged event,
    Emitter<AuthState> emit,
  ) async {
    final user = event.user;
    if (user != null) {
      // Verificar el estado del usuario antes de emitir AuthAuthenticated
      await _checkUserStatusAndEmit(user, emit);
    } else {
      emit(const AuthUnauthenticated());
    }
  }

  String _getFailureMessage(Failure failure) {
    return switch (failure) {
      ValidationFailure _ => failure.message,
      NetworkFailure _ => failure.message,
      AuthFailure _ => failure.message,
      AuthorizationFailure _ => failure.message,
      ServerFailure _ => failure.message,
      NotFoundFailure _ => failure.message,
      CacheFailure _ => failure.message,
      UnknownFailure _ => failure.message,
      _ => 'Error inesperado',
    };
  }

  Future<void> _onAuthLoadMicrofinancierasRequested(
    AuthLoadMicrofinancierasRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthMicrofinancierasLoading());

    final result = await _getMicrofinancierasUseCase();

    result.fold(
      (failure) => emit(
        AuthError(
          message: _getFailureMessage(failure),
          errorCode: 'microfinancieras_load_error',
        ),
      ),
      (microfinancieras) =>
          emit(AuthMicrofinancierasLoaded(microfinancieras: microfinancieras)),
    );
  }

  @override
  Future<void> close() {
    _authStateSubscription.cancel();
    return super.close();
  }
}
