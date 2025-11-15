import 'package:fpdart/fpdart.dart';
import '../../core/error/failures.dart';
import '../../entities/app_user.dart';
import '../../entities/user_profile.dart';
import '../../repositories/auth_repository.dart';
import '../usecase.dart';

class ValidateUserAccessUseCase
    implements UseCase<UserAccessValidation, ValidateUserAccessParams> {
  final AuthRepository _repository;

  const ValidateUserAccessUseCase(this._repository);

  @override
  Future<Either<Failure, UserAccessValidation>> call(
    ValidateUserAccessParams params,
  ) async {
    try {
      // ✅ OPTIMIZACIÓN: Usar perfil cacheado si está disponible
      // Esto evita hacer otra consulta a Firestore
      final profile =
          params.cachedProfile ??
          await _repository.fetchUserProfile(params.user.uid);

      // Si no se puede obtener el perfil, denegar acceso
      if (profile == null) {
        return Right(
          UserAccessValidation.unauthorized(
            user: params.user,
            reason: 'missing_profile',
            message:
                'No se pudo verificar tu perfil. Contacta al administrador.',
          ),
        );
      }

      // Validar rol
      final primaryRole = profile.primaryRoleId;
      if (primaryRole == null || primaryRole.isEmpty) {
        return Right(
          UserAccessValidation.unauthorized(
            user: params.user,
            reason: 'missing_role',
            message:
                'Tu cuenta no tiene un rol asignado. Contacta al administrador.',
          ),
        );
      }

      // Permitir acceso tanto a 'analyst' como a 'customer'
      if (primaryRole != 'analyst' && primaryRole != 'customer') {
        return Right(
          UserAccessValidation.unauthorized(
            user: params.user,
            reason: 'invalid_role',
            message: 'Tu rol no tiene acceso a esta app móvil.',
          ),
        );
      }

      // Validar status
      final status = profile.status ?? 'pending';
      if (status == 'pending') {
        return Right(
          UserAccessValidation.pending(
            user: params.user,
            message:
                'Tu cuenta está pendiente de aprobación. Te notificaremos cuando sea aprobada.',
          ),
        );
      }

      if (status == 'rejected') {
        return Right(
          UserAccessValidation.rejected(
            user: params.user,
            message: 'Tu cuenta ha sido rechazada. Contacta al administrador.',
          ),
        );
      }

      if (status != 'approved') {
        return Right(
          UserAccessValidation.unauthorized(
            user: params.user,
            reason: 'invalid_status',
            message: 'Tu cuenta no está aprobada. Contacta al administrador.',
          ),
        );
      }

      // Usuario válido: analyst + approved
      return Right(UserAccessValidation.authorized(user: params.user));
    } catch (e) {
      // En caso de error, denegar acceso por seguridad
      return Right(
        UserAccessValidation.unauthorized(
          user: params.user,
          reason: 'validation_error',
          message: 'Error al verificar permisos. Intenta nuevamente.',
        ),
      );
    }
  }
}

class ValidateUserAccessParams {
  final AppUser user;

  /// ✅ OPTIMIZACIÓN: Perfil cacheado opcional para evitar consultas duplicadas
  final UserProfile? cachedProfile;

  const ValidateUserAccessParams({required this.user, this.cachedProfile});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ValidateUserAccessParams &&
          runtimeType == other.runtimeType &&
          user == other.user &&
          cachedProfile == other.cachedProfile;

  @override
  int get hashCode => user.hashCode ^ cachedProfile.hashCode;
}

/// Resultado de la validación de acceso
class UserAccessValidation {
  final AppUser user;
  final AccessStatus status;
  final String? reason;
  final String? message;

  const UserAccessValidation._({
    required this.user,
    required this.status,
    this.reason,
    this.message,
  });

  factory UserAccessValidation.authorized({required AppUser user}) {
    return UserAccessValidation._(user: user, status: AccessStatus.authorized);
  }

  factory UserAccessValidation.unauthorized({
    required AppUser user,
    required String reason,
    required String message,
  }) {
    return UserAccessValidation._(
      user: user,
      status: AccessStatus.unauthorized,
      reason: reason,
      message: message,
    );
  }

  factory UserAccessValidation.pending({
    required AppUser user,
    required String message,
  }) {
    return UserAccessValidation._(
      user: user,
      status: AccessStatus.pending,
      message: message,
    );
  }

  factory UserAccessValidation.rejected({
    required AppUser user,
    required String message,
  }) {
    return UserAccessValidation._(
      user: user,
      status: AccessStatus.rejected,
      message: message,
    );
  }

  bool get isAuthorized => status == AccessStatus.authorized;
  bool get isUnauthorized => status == AccessStatus.unauthorized;
  bool get isPending => status == AccessStatus.pending;
  bool get isRejected => status == AccessStatus.rejected;
}

enum AccessStatus { authorized, unauthorized, pending, rejected }
