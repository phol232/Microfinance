import 'package:fpdart/fpdart.dart';
import '../../core/error/failures.dart';
import '../../entities/user_profile.dart';
import '../../repositories/auth_repository.dart';
import '../usecase.dart';

class GetUserProfileUseCase
    implements UseCase<UserProfile?, GetUserProfileParams> {
  final AuthRepository _repository;

  const GetUserProfileUseCase(this._repository);

  @override
  Future<Either<Failure, UserProfile?>> call(
    GetUserProfileParams params,
  ) async {
    if (params.uid.isEmpty) {
      return const Left(ValidationFailure('El UID del usuario es requerido'));
    }

    try {
      final profile = await _repository.fetchUserProfile(params.uid);
      return Right(profile);
    } catch (e) {
      return Left(_mapExceptionToFailure(e));
    }
  }

  Failure _mapExceptionToFailure(dynamic exception) {
    final message = exception.toString().toLowerCase();

    if (message.contains('network') || message.contains('connection')) {
      return const NetworkFailure('Error de conexión al obtener perfil');
    }

    if (message.contains('permission') || message.contains('unauthorized')) {
      return const AuthorizationFailure(
        'No tienes permisos para acceder a este perfil',
      );
    }

    if (message.contains('not-found') ||
        message.contains('document does not exist')) {
      return const NotFoundFailure('Perfil de usuario no encontrado');
    }

    return UnknownFailure('Error inesperado: ${exception.toString()}');
  }
}

class GetUserProfileParams {
  final String uid;

  const GetUserProfileParams({required this.uid});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GetUserProfileParams &&
          runtimeType == other.runtimeType &&
          uid == other.uid;

  @override
  int get hashCode => uid.hashCode;

  @override
  String toString() => 'GetUserProfileParams(uid: $uid)';
}
