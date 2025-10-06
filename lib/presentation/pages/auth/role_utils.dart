import '../../../domain/entities/microfinanciera.dart';

List<String> resolveDefaultRolesForMicrofinanciera(
  Microfinanciera? microfinanciera,
) {
  if (microfinanciera == null) {
    return const ['analyst'];
  }

  final settings = microfinanciera.settings;

  if (settings != null) {
    final rawRoles = settings['defaultRoles'];
    if (rawRoles is Iterable) {
      final resolvedRoles = rawRoles
          .map((role) => role?.toString().trim() ?? '')
          .where((role) => role.isNotEmpty)
          .toList();
      if (resolvedRoles.isNotEmpty) {
        return resolvedRoles;
      }
    }

    final defaultRoleId = settings['defaultRoleId'];
    if (defaultRoleId is String && defaultRoleId.trim().isNotEmpty) {
      return [defaultRoleId.trim()];
    }
  }

  final normalizedName = microfinanciera.name.toLowerCase();
  if (normalizedName.contains('microfinanzas del perú') ||
      normalizedName.contains('microfinanzas del peru')) {
    return const ['analyst'];
  }

  return const ['customer'];
}
