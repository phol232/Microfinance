import 'package:flutter/foundation.dart';

import '../../domain/services/tenant_resolver.dart';
import 'tenant_storage.dart';

class TenantController extends ChangeNotifier implements TenantResolver {
  TenantController({TenantStorage? storage})
      : _storage = storage ?? TenantStorage();

  final TenantStorage _storage;
  TenantInfo? _currentTenant;
  bool _isInitialized = false;

  bool get isInitialized => _isInitialized;

  TenantInfo? get currentTenant => _currentTenant;

  @override
  String? get tenantId => _currentTenant?.id;

  @override
  String? get tenantName => _currentTenant?.name;

  Future<void> initialize() async {
    if (_isInitialized) return;
    _currentTenant = await _storage.read();
    _isInitialized = true;
    notifyListeners();
  }

  Future<void> setTenant(TenantInfo info) async {
    _currentTenant = info;
    await _storage.save(info);
    notifyListeners();
  }

  Future<void> setTenantById(String id, {String? name}) async {
    await setTenant(TenantInfo(id: id, name: name));
  }

  Future<void> clearTenant() async {
    _currentTenant = null;
    await _storage.clear();
    notifyListeners();
  }
}
