import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../../domain/services/tenant_resolver.dart';
import '../../domain/entities/account.dart';
import '../models/account_dto.dart';

class AccountDataSource {
  AccountDataSource({
    FirebaseFirestore? firestore,
    required TenantResolver tenantResolver,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _tenantResolver = tenantResolver;

  final FirebaseFirestore _firestore;
  final TenantResolver _tenantResolver;

  Stream<List<Account>> getUserAccounts(String userId) {
    try {
      final microfinancieraId = _requireTenantId();

      return _firestore
          .collection('microfinancieras')
          .doc(microfinancieraId)
          .collection('accounts')
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .snapshots()
          .map(
            (snapshot) => snapshot.docs
                .map((doc) => AccountDto.fromFirestore(doc).toDomain())
                .toList(),
          );
    } catch (error, stackTrace) {
      _logError('getUserAccounts', error, stackTrace);
      return Stream.value([]);
    }
  }

  Future<Account?> getAccountById(
    String accountId,
    String microfinancieraId,
  ) async {
    try {
      final doc = await _firestore
          .collection('microfinancieras')
          .doc(microfinancieraId)
          .collection('accounts')
          .doc(accountId)
          .get();
      if (doc.exists && doc.data() != null) {
        return AccountDto.fromFirestore(doc).toDomain();
      }
      return null;
    } catch (error, stackTrace) {
      _logError('getAccountById', error, stackTrace);
      return null;
    }
  }

  Future<String> createAccount(Account account) async {
    try {
      final accountNumber = await _generateAccountNumber(
        account.microfinancieraId,
      );

      final cci = await _generateCCI(account.microfinancieraId);

      final interestRate = _getInterestRateByAccountType(account.accountType);

      final accountData = AccountDto.fromDomain(
        account.copyWith(
          accountNumber: accountNumber,
          cci: cci,
          interestRate: interestRate,
          createdAt: DateTime.now(),
        ),
      ).toFirestore();

      final docRef = await _firestore
          .collection('microfinancieras')
          .doc(account.microfinancieraId)
          .collection('accounts')
          .add(accountData);
      return docRef.id;
    } catch (error, stackTrace) {
      _logError('createAccount', error, stackTrace);
      rethrow;
    }
  }

  Future<void> updateAccount(Account account) async {
    try {
      await _firestore
          .collection('microfinancieras')
          .doc(account.microfinancieraId)
          .collection('accounts')
          .doc(account.id)
          .update(AccountDto.fromDomain(account).toFirestore());
    } catch (error, stackTrace) {
      _logError('updateAccount', error, stackTrace);
      rethrow;
    }
  }

  Future<void> deleteAccount(String accountId, String microfinancieraId) async {
    try {
      await _firestore
          .collection('microfinancieras')
          .doc(microfinancieraId)
          .collection('accounts')
          .doc(accountId)
          .delete();
    } catch (error, stackTrace) {
      _logError('deleteAccount', error, stackTrace);
      rethrow;
    }
  }

  Stream<List<Account>> getAccountsByMicrofinanciera(String microfinancieraId) {
    try {
      return _firestore
          .collection('microfinancieras')
          .doc(microfinancieraId)
          .collection('accounts')
          .orderBy('createdAt', descending: true)
          .snapshots()
          .map(
            (snapshot) => snapshot.docs
                .map((doc) => AccountDto.fromFirestore(doc).toDomain())
                .toList(),
          );
    } catch (error, stackTrace) {
      _logError('getAccountsByMicrofinanciera', error, stackTrace);
      return Stream.value([]);
    }
  }

  Stream<List<Account>> getAccountsByStatus(
    String userId,
    AccountStatus status,
    String microfinancieraId,
  ) {
    try {
      return _firestore
          .collection('microfinancieras')
          .doc(microfinancieraId)
          .collection('accounts')
          .where('userId', isEqualTo: userId)
          .where('status', isEqualTo: status.name)
          .orderBy('createdAt', descending: true)
          .snapshots()
          .map(
            (snapshot) => snapshot.docs
                .map((doc) => AccountDto.fromFirestore(doc).toDomain())
                .toList(),
          );
    } catch (error, stackTrace) {
      _logError('getAccountsByStatus', error, stackTrace);
      return Stream.value([]);
    }
  }

  Future<bool> canCreateAccount(String userId) async {
    try {
      final count = await getUserAccountCount(userId);
      return count < 5;
    } catch (error, stackTrace) {
      _logError('canCreateAccount', error, stackTrace);
      return false;
    }
  }

  Future<int> getUserAccountCount(String userId) async {
    try {
      final microfinancieraId = _requireTenantId();
      final snapshot = await _firestore
          .collection('microfinancieras')
          .doc(microfinancieraId)
          .collection('accounts')
          .where('userId', isEqualTo: userId)
          .get();
      return snapshot.docs.length;
    } catch (error, stackTrace) {
      _logError('getUserAccountCount', error, stackTrace);
      return 0;
    }
  }

  String _requireTenantId() {
    final tenantId = _tenantResolver.tenantId;
    if (tenantId == null || tenantId.isEmpty) {
      throw StateError(
        'Tenant no configurado. Selecciona una microfinanciera para continuar.',
      );
    }
    return tenantId;
  }

  Future<String> _generateAccountNumber(String microfinancieraId) async {
    String accountNumber = '';
    bool exists = true;
    int attempts = 0;
    const maxAttempts = 10;

    while (exists && attempts < maxAttempts) {
      attempts++;

      final now = DateTime.now();
      final monthYear =
          '${now.month.toString().padLeft(2, '0')}${now.year.toString().substring(2)}';

      final random = DateTime.now().microsecondsSinceEpoch;
      final randomPart = (random % 1000000000000).toString().padLeft(12, '0');

      accountNumber = monthYear + randomPart;

      final snapshot = await _firestore
          .collection('microfinancieras')
          .doc(microfinancieraId)
          .collection('accounts')
          .where('accountNumber', isEqualTo: accountNumber)
          .get();

      exists = snapshot.docs.isNotEmpty;
    }

    if (attempts >= maxAttempts) {
      throw Exception(
        'No se pudo generar un número de cuenta único después de $maxAttempts intentos',
      );
    }

    return accountNumber;
  }

  Future<String> _generateCCI(String microfinancieraId) async {
    String cci = '';
    bool exists = true;
    int attempts = 0;
    const maxAttempts = 10;

    while (exists && attempts < maxAttempts) {
      attempts++;

      final bankCode = '999';

      final random = DateTime.now().microsecondsSinceEpoch;
      final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      final randomPart = (timestamp + random.toString())
          .substring(0, 17)
          .padLeft(17, '0');

      cci = bankCode + randomPart;

      final snapshot = await _firestore
          .collection('microfinancieras')
          .doc(microfinancieraId)
          .collection('accounts')
          .where('cci', isEqualTo: cci)
          .get();

      exists = snapshot.docs.isNotEmpty;
    }

    if (attempts >= maxAttempts) {
      throw Exception(
        'No se pudo generar un CCI único después de $maxAttempts intentos',
      );
    }

    return cci;
  }

  double _getInterestRateByAccountType(AccountType accountType) {
    switch (accountType) {
      case AccountType.savings:
        return 2.50;
      case AccountType.checking:
        return 0.25;
      case AccountType.fixedDeposit:
        return 4.75;
      case AccountType.microCredit:
        return 3.25;
    }
  }

  Future<double> getTotalBalance(
    String userId,
    String microfinancieraId,
  ) async {
    try {
      final snapshot = await _firestore
          .collection('microfinancieras')
          .doc(microfinancieraId)
          .collection('accounts')
          .where('userId', isEqualTo: userId)
          .where('status', isEqualTo: AccountStatus.active.name)
          .get();

      double total = 0.0;
      for (final doc in snapshot.docs) {
        final account = AccountDto.fromFirestore(doc).toDomain();
        total += account.balance;
      }
      return total;
    } catch (error, stackTrace) {
      _logError('getTotalBalance', error, stackTrace);
      return 0.0;
    }
  }

  Future<void> updateBalance(
    String accountId,
    double newBalance,
    String microfinancieraId,
  ) async {
    try {
      await _firestore
          .collection('microfinancieras')
          .doc(microfinancieraId)
          .collection('accounts')
          .doc(accountId)
          .update({
            'balance': newBalance,
            'updatedAt': FieldValue.serverTimestamp(),
          });
    } catch (error, stackTrace) {
      _logError('updateBalance', error, stackTrace);
      rethrow;
    }
  }

  void _logError(String method, Object error, StackTrace stackTrace) {
    if (kDebugMode) {
      print('❌ AccountDataSource.$method: $error');
      print('Stack trace: $stackTrace');
    }
  }
}
