import 'dart:async';

import '../../domain/entities/account.dart';
import '../../domain/repositories/account_repository.dart';
import '../datasources/account_datasource.dart';

class AccountRepositoryImpl implements AccountRepository {
  AccountRepositoryImpl({
    required AccountDataSource accountDataSource,
  }) : _accountDataSource = accountDataSource;

  final AccountDataSource _accountDataSource;

  @override
  Stream<List<Account>> getUserAccounts(String userId) {
    return _accountDataSource.getUserAccounts(userId);
  }

  @override
  Future<Account?> getAccountById(String accountId, String microfinancieraId) {
    return _accountDataSource.getAccountById(accountId, microfinancieraId);
  }

  @override
  Future<String> createAccount(Account account) {
    return _accountDataSource.createAccount(account);
  }

  @override
  Future<void> updateAccount(Account account) {
    return _accountDataSource.updateAccount(account);
  }

  @override
  Future<void> deleteAccount(String accountId, String microfinancieraId) {
    return _accountDataSource.deleteAccount(accountId, microfinancieraId);
  }

  @override
  Stream<List<Account>> getAccountsByMicrofinanciera(String microfinancieraId) {
    return _accountDataSource.getAccountsByMicrofinanciera(microfinancieraId);
  }

  @override
  Stream<List<Account>> getAccountsByStatus(String userId, AccountStatus status, String microfinancieraId) {
    return _accountDataSource.getAccountsByStatus(userId, status, microfinancieraId);
  }

  @override
  Future<bool> canCreateAccount(String userId) {
    return _accountDataSource.canCreateAccount(userId);
  }

  @override
  Future<int> getUserAccountCount(String userId) {
    return _accountDataSource.getUserAccountCount(userId);
  }

  @override
  Future<double> getTotalBalance(String userId, String microfinancieraId) {
    return _accountDataSource.getTotalBalance(userId, microfinancieraId);
  }

  @override
  Future<void> updateBalance(String accountId, double newBalance, String microfinancieraId) {
    return _accountDataSource.updateBalance(accountId, newBalance, microfinancieraId);
  }
}