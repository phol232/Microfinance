/// Provides access to the current tenant (microfinanciera) context.
abstract class TenantResolver {
  String? get tenantId;
  String? get tenantName;
}
