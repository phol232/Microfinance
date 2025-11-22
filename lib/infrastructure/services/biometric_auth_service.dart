import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';

class BiometricAuthService {
  static final BiometricAuthService _instance =
      BiometricAuthService._internal();
  factory BiometricAuthService() => _instance;
  BiometricAuthService._internal();

  final LocalAuthentication _localAuth = LocalAuthentication();
  bool _isAuthenticating = false;

  Future<bool> isDeviceSupported() async {
    try {
      return await _localAuth.isDeviceSupported();
    } catch (e) {
      return false;
    }
  }

  Future<bool> isBiometricAvailable() async {
    try {
      final bool isAvailable = await _localAuth.canCheckBiometrics;
      final bool isDeviceSupported = await _localAuth.isDeviceSupported();
      return isAvailable && isDeviceSupported;
    } catch (e) {
      return false;
    }
  }

  Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      return await _localAuth.getAvailableBiometrics();
    } catch (e) {
      return [];
    }
  }

  Future<BiometricAuthResult> authenticate({
    required String localizedReason,
  }) async {
    if (_isAuthenticating) {
      print('DEBUG: Autenticación ya en progreso, cancelando nueva solicitud');
      return BiometricAuthResult.error;
    }

    try {
      _isAuthenticating = true;
      print('DEBUG: Iniciando proceso de autenticación biométrica');

      final bool isDeviceSupported = await _localAuth.isDeviceSupported();
      print('DEBUG: Dispositivo soportado: $isDeviceSupported');
      if (!isDeviceSupported) {
        return BiometricAuthResult.notAvailable;
      }

      final bool canCheckBiometrics = await _localAuth.canCheckBiometrics;
      print('DEBUG: Puede verificar biometría: $canCheckBiometrics');
      if (!canCheckBiometrics) {
        return BiometricAuthResult.notAvailable;
      }

      final List<BiometricType> availableBiometrics = await _localAuth
          .getAvailableBiometrics();
      print('DEBUG: Biometrías disponibles: $availableBiometrics');

      if (availableBiometrics.isEmpty) {
        print('DEBUG: No hay biometrías configuradas');
        return BiometricAuthResult.notEnrolled;
      }

      final hasStrongBiometrics = availableBiometrics.any(
        (type) =>
            type == BiometricType.strong ||
            type == BiometricType.face ||
            type == BiometricType.fingerprint,
      );

      print('DEBUG: Tiene biometrías fuertes: $hasStrongBiometrics');
      print('DEBUG: Iniciando autenticación...');

      final authFuture = _localAuth.authenticate(
        localizedReason: localizedReason,
        options: AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: false,
          useErrorDialogs: false,
          sensitiveTransaction: false,
        ),
      );

      final timeoutFuture = Future.delayed(Duration(seconds: 15), () => false);

      final bool didAuthenticate = await Future.any([
        authFuture,
        timeoutFuture,
      ]);

      if (!didAuthenticate && _isAuthenticating) {
        print(
          'DEBUG: Timeout detectado - usuario no interactuó, limpiando estado',
        );
        _isAuthenticating = false;
        return BiometricAuthResult.cancelled;
      }

      print('DEBUG: Resultado de autenticación: $didAuthenticate');
      _isAuthenticating = false;
      return didAuthenticate
          ? BiometricAuthResult.success
          : BiometricAuthResult.failed;
    } on PlatformException catch (e) {
      _isAuthenticating = false;
      print('DEBUG: PlatformException: ${e.code} - ${e.message}');

      switch (e.code) {
        case 'NotAvailable':
        case 'BiometricNotAvailable':
          return BiometricAuthResult.notAvailable;
        case 'NotEnrolled':
        case 'BiometricNotEnrolled':
          return BiometricAuthResult.notEnrolled;
        case 'LockedOut':
        case 'PermanentlyLockedOut':
          return BiometricAuthResult.lockedOut;
        case 'UserCancel':
        case 'UserFallback':
        case 'SystemCancel':
          print(
            'DEBUG: Usuario canceló la autenticación, limpiando estado inmediatamente',
          );
          _isAuthenticating = false;
          return BiometricAuthResult.cancelled;
        case 'auth_in_progress':
          print(
            'DEBUG: Autenticación ya en progreso detectada, forzando limpieza',
          );
          await Future.delayed(const Duration(milliseconds: 100));
          if (!_isAuthenticating) {
            print(
              'DEBUG: Reintentando autenticación después de limpiar estado',
            );
            return authenticate(localizedReason: localizedReason);
          }
          return BiometricAuthResult.error;
        default:
          return BiometricAuthResult.error;
      }
    } catch (e) {
      print('DEBUG: Error general en autenticación: $e');

      final errorString = e.toString().toLowerCase();

      if (errorString.contains('not available') ||
          errorString.contains('notavailable')) {
        return BiometricAuthResult.notAvailable;
      } else if (errorString.contains('not enrolled') ||
          errorString.contains('notenrolled')) {
        return BiometricAuthResult.notEnrolled;
      } else if (errorString.contains('locked') ||
          errorString.contains('too many attempts')) {
        return BiometricAuthResult.lockedOut;
      } else if (errorString.contains('user cancel') ||
          errorString.contains('cancelled')) {
        return BiometricAuthResult.cancelled;
      } else {
        return BiometricAuthResult.error;
      }
    }
  }

  String getResultMessage(BiometricAuthResult result) {
    switch (result) {
      case BiometricAuthResult.success:
        return 'Autenticación exitosa';
      case BiometricAuthResult.failed:
        return 'Autenticación fallida. Puedes intentar de nuevo.';
      case BiometricAuthResult.cancelled:
        return 'Autenticación cancelada por el usuario.';
      case BiometricAuthResult.notAvailable:
        return 'La autenticación biométrica no está disponible en este dispositivo. Verifica que tengas huella dactilar o Face ID configurado.';
      case BiometricAuthResult.notEnrolled:
        return 'No tienes huella dactilar o Face ID configurado. Ve a Configuración de tu dispositivo para configurarlo.';
      case BiometricAuthResult.lockedOut:
        return 'Autenticación biométrica bloqueada por demasiados intentos fallidos. Espera un momento e inténtalo de nuevo.';
      case BiometricAuthResult.error:
        return 'Error inesperado durante la autenticación. Verifica que tu dispositivo tenga autenticación biométrica habilitada.';
    }
  }

  Future<bool> hasBiometricEnrolled() async {
    try {
      final availableBiometrics = await getAvailableBiometrics();
      return availableBiometrics.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  Future<Map<String, dynamic>> getDiagnosticInfo() async {
    try {
      final isDeviceSupported = await _localAuth.isDeviceSupported();
      final canCheckBiometrics = await _localAuth.canCheckBiometrics;
      final availableBiometrics = await _localAuth.getAvailableBiometrics();

      return {
        'isDeviceSupported': isDeviceSupported,
        'canCheckBiometrics': canCheckBiometrics,
        'availableBiometrics': availableBiometrics
            .map((e) => e.toString())
            .toList(),
        'hasBiometricsEnrolled': availableBiometrics.isNotEmpty,
      };
    } catch (e) {
      return {
        'error': e.toString(),
        'isDeviceSupported': false,
        'canCheckBiometrics': false,
        'availableBiometrics': [],
        'hasBiometricsEnrolled': false,
      };
    }
  }

  Future<void> forceResetAuthState() async {
    try {
      _isAuthenticating = false;
      await _localAuth.isDeviceSupported();
      print('DEBUG: Plugin local_auth reiniciado exitosamente');
    } catch (e) {
      print('DEBUG: Error al reiniciar plugin local_auth: $e');
    }
  }

  void clearAuthenticationState() {
    _isAuthenticating = false;
    print('DEBUG: Estado de autenticación limpiado manualmente');
  }

  bool get isAuthenticating => _isAuthenticating;
}

enum BiometricAuthResult {
  success,
  failed,
  cancelled,
  notAvailable,
  notEnrolled,
  lockedOut,
  error,
}
