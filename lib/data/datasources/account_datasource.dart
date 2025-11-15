import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../../domain/entities/account.dart';

class AccountDataSource {
  AccountDataSource({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  Stream<List<Account>> getUserAccounts(String userId) {
    try {
      const microfinancieraId = 'mf_demo_001';

      return _firestore
          .collection('microfinancieras')
          .doc(microfinancieraId)
          .collection('accounts')
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .snapshots()
          .map(
            (snapshot) =>
                snapshot.docs.map((doc) => Account.fromFirestore(doc)).toList(),
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
        return Account.fromFirestore(doc);
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

      final accountData = account
          .copyWith(
            accountNumber: accountNumber,
            cci: cci,
            interestRate: interestRate,
            createdAt: DateTime.now(),
          )
          .toFirestore();

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
          .update(account.toFirestore());
    } catch (error, stackTrace) {
      _logError('updateAccount', error, stackTrace);
      rethrow;
    }
  }

  /// Elimina una cuenta
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

  /// Obtiene cuentas por microfinanciera
  Stream<List<Account>> getAccountsByMicrofinanciera(String microfinancieraId) {
    try {
      return _firestore
          .collection('microfinancieras')
          .doc(microfinancieraId)
          .collection('accounts')
          .orderBy('createdAt', descending: true)
          .snapshots()
          .map(
            (snapshot) =>
                snapshot.docs.map((doc) => Account.fromFirestore(doc)).toList(),
          );
    } catch (error, stackTrace) {
      _logError('getAccountsByMicrofinanciera', error, stackTrace);
      return Stream.value([]);
    }
  }

  /// Obtiene cuentas por estado
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
            (snapshot) =>
                snapshot.docs.map((doc) => Account.fromFirestore(doc)).toList(),
          );
    } catch (error, stackTrace) {
      _logError('getAccountsByStatus', error, stackTrace);
      return Stream.value([]);
    }
  }

  /// Verifica si el usuario puede crear una nueva cuenta
  Future<bool> canCreateAccount(String userId) async {
    try {
      final count = await getUserAccountCount(userId);
      return count < 5; // Límite máximo de 5 cuentas por usuario
    } catch (error, stackTrace) {
      _logError('canCreateAccount', error, stackTrace);
      return false;
    }
  }

  /// Obtiene el número de cuentas del usuario
  Future<int> getUserAccountCount(String userId) async {
    try {
      const microfinancieraId = 'mf_demo_001';
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

  /// Genera un número de cuenta único de 14-16 dígitos según estándar peruano
  Future<String> _generateAccountNumber(String microfinancieraId) async {
    String accountNumber = '';
    bool exists = true;
    int attempts = 0;
    const maxAttempts = 10;

    while (exists && attempts < maxAttempts) {
      attempts++;

      // Generar número de cuenta de 16 dígitos para microfinanciera
      // Formato: MMYY + 12 dígitos aleatorios
      final now = DateTime.now();
      final monthYear =
          '${now.month.toString().padLeft(2, '0')}${now.year.toString().substring(2)}';

      // Generar 12 dígitos aleatorios
      final random = DateTime.now().microsecondsSinceEpoch;
      final randomPart = (random % 1000000000000).toString().padLeft(12, '0');

      accountNumber = monthYear + randomPart;

      // Verificar si ya existe
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

  /// Genera un Código de Cuenta Interbancario (CCI) único de 20 dígitos
  Future<String> _generateCCI(String microfinancieraId) async {
    String cci = '';
    bool exists = true;
    int attempts = 0;
    const maxAttempts = 10;

    while (exists && attempts < maxAttempts) {
      attempts++;

      final bankCode = '999';

      // Generar 17 dígitos aleatorios
      final random = DateTime.now().microsecondsSinceEpoch;
      final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      final randomPart = (timestamp + random.toString())
          .substring(0, 17)
          .padLeft(17, '0');

      cci = bankCode + randomPart;

      // Verificar si ya existe
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

  /// Obtiene la tasa de interés según el tipo de cuenta
  double _getInterestRateByAccountType(AccountType accountType) {
    switch (accountType) {
      case AccountType.savings:
        return 2.50; // 2.50% anual para cuentas de ahorro
      case AccountType.checking:
        return 0.25; // 0.25% anual para cuentas corrientes
      case AccountType.fixedDeposit:
        return 4.75; // 4.75% anual para depósitos a plazo fijo
      case AccountType.microCredit:
        return 3.25; // 3.25% anual para cuentas de microcrédito
    }
  }

  /// Obtiene el balance total de todas las cuentas de un usuario
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
        final account = Account.fromFirestore(doc);
        total += account.balance;
      }
      return total;
    } catch (error, stackTrace) {
      _logError('getTotalBalance', error, stackTrace);
      return 0.0;
    }
  }

  /// Actualiza el balance de una cuenta
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
