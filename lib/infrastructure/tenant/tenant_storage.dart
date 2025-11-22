import 'package:shared_preferences/shared_preferences.dart';

class TenantInfo {
  const TenantInfo({required this.id, this.name});

  final String id;
  final String? name;

  TenantInfo copyWith({String? id, String? name}) {
    return TenantInfo(
      id: id ?? this.id,
      name: name ?? this.name,
    );
  }
}

class TenantStorage {
  static const _tenantIdKey = 'tenant_id';
  static const _tenantNameKey = 'tenant_name';

  Future<TenantInfo?> read() async {
    final prefs = await SharedPreferences.getInstance();
    final tenantId = prefs.getString(_tenantIdKey);
    if (tenantId == null || tenantId.isEmpty) {
      return null;
    }
    final tenantName = prefs.getString(_tenantNameKey);
    return TenantInfo(id: tenantId, name: tenantName);
  }

  Future<void> save(TenantInfo info) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tenantIdKey, info.id);
    if (info.name?.isNotEmpty ?? false) {
      await prefs.setString(_tenantNameKey, info.name!);
    } else {
      await prefs.remove(_tenantNameKey);
    }
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tenantIdKey);
    await prefs.remove(_tenantNameKey);
  }
}
