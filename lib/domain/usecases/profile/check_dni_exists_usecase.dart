import 'package:fpdart/fpdart.dart';
import '../../repositories/auth_repository.dart';
import '../../core/error/failures.dart';
import '../usecase.dart';

class CheckDniExistsParams {
  final String dni;

  const CheckDniExistsParams({required this.dni});
}

class CheckDniExistsUseCase implements UseCase<bool, CheckDniExistsParams> {
  final AuthRepository _authRepository;

  const CheckDniExistsUseCase(this._authRepository);

  @override
  Future<Either<Failure, bool>> call(CheckDniExistsParams params) async {
    try {
      // Validaciones de negocio
      if (params.dni.trim().isEmpty) {
        return left(const ValidationFailure('El DNI es requerido'));
      }

      final dni = params.dni.trim();
      
      // Validar formato de DNI peruano (8 dígitos)
      if (dni.length != 8) {
        return left(const ValidationFailure('El DNI debe tener 8 dígitos'));
      }

      if (!RegExp(r'^\d{8}$').hasMatch(dni)) {
        return left(const ValidationFailure('El DNI solo debe contener números'));
      }

      // Validar que no sea un DNI obviamente inválido
      if (dni == '00000000' || dni == '11111111' || dni == '12345678') {
        return left(const ValidationFailure('DNI inválido'));
      }

      final exists = await _authRepository.checkDniExists(dni);
      return right(exists);
    } catch (e) {
      if (e.toString().contains('network')) {
        return left(const NetworkFailure('Error de conexión'));
      }
      return left(UnknownFailure('Error inesperado: ${e.toString()}'));
    }
  }
}