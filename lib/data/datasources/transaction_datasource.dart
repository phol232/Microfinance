import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/transaction.dart';

class TransactionDatasource {
  final FirebaseFirestore _firestore;

  TransactionDatasource({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  Future<FinancialTransaction> createTransaction({
    required String mfId,
    required String type,
    required String refType,
    required String refId,
    required double debit,
    required double credit,
    required String currency,
    required String branchId,
    Map<String, dynamic>? metadata,
  }) async {
    final transactionData = {
      'mfId': mfId,
      'type': type,
      'refType': refType,
      'refId': refId,
      'debit': debit,
      'credit': credit,
      'currency': currency,
      'branchId': branchId,
      'createdAt': FieldValue.serverTimestamp(),
      if (metadata != null) 'metadata': metadata,
    };

    final docRef = await _firestore
        .collection('microfinancieras')
        .doc(mfId)
        .collection('transactions')
        .add(transactionData);

    final doc = await docRef.get();
    return FinancialTransaction.fromFirestore(doc);
  }

  Future<List<FinancialTransaction>> getTransactions({
    required String mfId,
    String? refType,
    String? refId,
    DateTime? startDate,
    DateTime? endDate,
    int? limit,
  }) async {
    Query<Map<String, dynamic>> query = _firestore
        .collection('microfinancieras')
        .doc(mfId)
        .collection('transactions')
        .orderBy('createdAt', descending: true);

    if (refType != null) {
      query = query.where('refType', isEqualTo: refType);
    }

    if (refId != null) {
      query = query.where('refId', isEqualTo: refId);
    }

    if (startDate != null) {
      query = query.where(
        'createdAt',
        isGreaterThanOrEqualTo: Timestamp.fromDate(startDate),
      );
    }

    if (endDate != null) {
      query = query.where(
        'createdAt',
        isLessThanOrEqualTo: Timestamp.fromDate(endDate),
      );
    }

    if (limit != null) {
      query = query.limit(limit);
    }

    final snapshot = await query.get();
    return snapshot.docs
        .map((doc) => FinancialTransaction.fromFirestore(doc))
        .toList();
  }

  Future<FinancialTransaction?> getTransactionById({
    required String mfId,
    required String transactionId,
  }) async {
    final doc = await _firestore
        .collection('microfinancieras')
        .doc(mfId)
        .collection('transactions')
        .doc(transactionId)
        .get();

    if (!doc.exists) return null;
    return FinancialTransaction.fromFirestore(doc);
  }

  /// Calcula el saldo de una cuenta basado en las transacciones
  Future<double> calculateAccountBalance({
    required String mfId,
    required String accountId,
  }) async {
    print(
      '💰 TransactionDatasource: Calculating balance for account: $accountId',
    );
    print('💰 TransactionDatasource: Looking for account in mfId: $mfId');

    // Obtener el saldo actual de la cuenta
    final accountDoc = await _firestore
        .collection('microfinancieras')
        .doc(mfId)
        .collection('accounts')
        .doc(accountId)
        .get();

    print(
      '💰 TransactionDatasource: Account document exists: ${accountDoc.exists}',
    );

    if (!accountDoc.exists) {
      print('❌ TransactionDatasource: Account document not found!');
      return 0.0;
    }

    final data = accountDoc.data()!;

    // El balance en Firestore ya está actualizado con todas las transacciones
    // No necesitamos recalcular sumando las transacciones de nuevo
    final balance = (data['balance'] as num?)?.toDouble();
    final initialDeposit = (data['initialDeposit'] as num?)?.toDouble();

    print('💰 TransactionDatasource: balance field: $balance');
    print('💰 TransactionDatasource: initialDeposit field: $initialDeposit');

    final currentBalance = balance ?? initialDeposit ?? 0.0;
    print('💰 TransactionDatasource: Current account balance: $currentBalance');

    return currentBalance;
  }

  /// Actualiza el saldo de una cuenta en tiempo real
  Future<void> updateAccountBalance({
    required String mfId,
    required String accountId,
    required double newBalance,
  }) async {
    await _firestore
        .collection('microfinancieras')
        .doc(mfId)
        .collection('accounts')
        .doc(accountId)
        .update({
          'balance': newBalance,
          'lastUpdated': FieldValue.serverTimestamp(),
        });
  }

  /// Ejecuta una transacción atómica (para pagos que requieren múltiples operaciones)
  Future<List<FinancialTransaction>> executeAtomicTransaction({
    required String mfId,
    required List<Map<String, dynamic>> transactionData,
    required String accountId,
    required double newBalance,
  }) async {
    final batch = _firestore.batch();
    final List<DocumentReference> transactionRefs = [];

    // Crear las transacciones
    for (final data in transactionData) {
      final ref = _firestore
          .collection('microfinancieras')
          .doc(mfId)
          .collection('transactions')
          .doc();

      batch.set(ref, {...data, 'createdAt': FieldValue.serverTimestamp()});

      transactionRefs.add(ref);
    }

    // Actualizar el saldo de la cuenta
    final accountRef = _firestore
        .collection('microfinancieras')
        .doc(mfId)
        .collection('accounts')
        .doc(accountId);

    batch.update(accountRef, {
      'balance': newBalance,
      'lastUpdated': FieldValue.serverTimestamp(),
    });

    // Ejecutar la transacción atómica
    await batch.commit();

    // Obtener las transacciones creadas
    final List<FinancialTransaction> createdTransactions = [];
    for (final ref in transactionRefs) {
      final doc = await ref.get();
      createdTransactions.add(
        FinancialTransaction.fromFirestore(
          doc as DocumentSnapshot<Map<String, dynamic>>,
        ),
      );
    }

    return createdTransactions;
  }

  /// Actualiza el status de una cuota después de un pago exitoso
  Future<void> updateInstallmentStatus({
    required String mfId,
    required String loanId,
    required String installmentId,
    required String status,
  }) async {
    await _firestore
        .collection('microfinancieras')
        .doc(mfId)
        .collection('loanApplications')
        .doc(loanId)
        .collection('repaymentSchedule')
        .doc(installmentId)
        .update({
          'status': status,
          'paidAt': status.toLowerCase() == 'paid'
              ? FieldValue.serverTimestamp()
              : null,
          'lastUpdated': FieldValue.serverTimestamp(),
        });
  }
}
