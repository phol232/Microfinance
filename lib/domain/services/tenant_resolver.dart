/// Contrato simple para resolver el tenant (microfinanciera) activo.
abstract class TenantResolver {
  String? get tenantId;
  String? get tenantName;
}
