import '../../../domain/entities/microfinanciera.dart';

List<String> resolveDefaultRolesForMicrofinanciera(
  Microfinanciera? microfinanciera,
) {
  // Por seguridad, todos los usuarios creados desde la app móvil deben ser clientes.
  return const ['customer'];
}
