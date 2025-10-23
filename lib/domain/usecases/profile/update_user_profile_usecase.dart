import 'package:fpdart/fpdart.dart';
import '../../repositories/auth_repository.dart';
import '../../core/error/failures.dart';
import '../usecase.dart';

class UpdateUserProfileParams {
  final String uid;
  final String microfinancieraId;
  final String membershipId;
  final String? customerId;
  final Map<String, dynamic> updates;

  const UpdateUserProfileParams({
    required this.uid,
    required this.microfinancieraId,
    required this.membershipId,
    this.customerId,
    required this.updates,
  });
}

class UpdateUserProfileUseCase implements UseCase<void, UpdateUserProfileParams> {
  final AuthRepository _authRepository;

  const UpdateUserProfileUseCase(this._authRepository);

  @override
  Future<Either<Failure, void>> call(UpdateUserProfileParams params) async {
    try {
      // Validaciones de negocio
      if (params.uid.trim().isEmpty) {
        return left(const ValidationFailure('El ID de usuario es requerido'));
      }

      if (params.microfinancieraId.trim().isEmpty) {
        return left(const ValidationFailure('La microfinanciera es requerida'));
      }

      if (params.membershipId.trim().isEmpty) {
        return left(const ValidationFailure('El ID de membresía es requerido'));
      }

      if (params.updates.isEmpty) {
        return left(const ValidationFailure('No hay datos para actualizar'));
      }

      // Validar campos específicos si están presentes
      if (params.updates.containsKey('firstName')) {
        final firstName = params.updates['firstName'] as String?;
        if (firstName == null || firstName.trim().isEmpty) {
          return left(const ValidationFailure('El nombre es requerido'));
        }
        if (firstName.trim().length < 2) {
          return left(const ValidationFailure('El nombre debe tener al menos 2 caracteres'));
        }
      }

      if (params.updates.containsKey('lastName')) {
        final lastName = params.updates['lastName'] as String?;
        if (lastName == null || lastName.trim().isEmpty) {
          return left(const ValidationFailure('El apellido es requerido'));
        }
        if (lastName.trim().length < 2) {
          return left(const ValidationFailure('El apellido debe tener al menos 2 caracteres'));
        }
      }

      if (params.updates.containsKey('dni')) {
        final dni = params.updates['dni'] as String?;
        if (dni != null && dni.isNotEmpty) {
          if (dni.length != 8 || !RegExp(r'^\d{8}$').hasMatch(dni)) {
            return left(const ValidationFailure('El DNI debe tener 8 dígitos'));
          }
        }
      }

      if (params.updates.containsKey('phone')) {
        final phone = params.updates['phone'] as String?;
        if (phone != null && phone.isNotEmpty) {
          if (phone.length != 9 || !RegExp(r'^9\d{8}$').hasMatch(phone)) {
            return left(const ValidationFailure('El teléfono debe tener 9 dígitos y empezar con 9'));
          }
        }
      }

      await _authRepository.updateUserProfile(
        uid: params.uid,
        microfinancieraId: params.microfinancieraId,
        membershipId: params.membershipId,
        customerId: params.customerId,
        updates: params.updates,
      );

      return right(null);
    } catch (e) {
      if (e.toString().contains('network')) {
        return left(const NetworkFailure('Error de conexión'));
      }
      if (e.toString().contains('permission')) {
        return left(const AuthorizationFailure('No tienes permisos para actualizar este perfil'));
      }
      return left(UnknownFailure('Error inesperado: ${e.toString()}'));
    }
  }
}