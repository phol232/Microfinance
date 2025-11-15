import '../entities/account.dart';

/// Repositorio abstracto para la gestión de cuentas
abstract class AccountRepository {
  /// Obtiene todas las cuentas del usuario
  Stream<List<Account>> getUserAccounts(String userId);
  
  /// Obtiene una cuenta específica por ID
  Future<Account?> getAccountById(String accountId, String microfinancieraId);
  
  /// Crea una nueva cuenta
  Future<String> createAccount(Account account);
  
  /// Actualiza una cuenta existente
  Future<void> updateAccount(Account account);
  
  /// Elimina una cuenta
  Future<void> deleteAccount(String accountId, String microfinancieraId);
  
  /// Obtiene cuentas por microfinanciera
  Stream<List<Account>> getAccountsByMicrofinanciera(String microfinancieraId);
  
  /// Obtiene cuentas por estado
  Stream<List<Account>> getAccountsByStatus(String userId, AccountStatus status, String microfinancieraId);
  
  /// Verifica si el usuario puede crear una nueva cuenta
  Future<bool> canCreateAccount(String userId);
  
  /// Obtiene el número de cuentas del usuario
  Future<int> getUserAccountCount(String userId);
  
  /// Obtiene el balance total de todas las cuentas de un usuario
  Future<double> getTotalBalance(String userId, String microfinancieraId);
  
  /// Actualiza el balance de una cuenta
  Future<void> updateBalance(String accountId, double newBalance, String microfinancieraId);
}