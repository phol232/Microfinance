import '../../domain/entities/transaction.dart';
import '../../domain/repositories/transaction_repository.dart';
import '../datasources/transaction_datasource.dart';

class TransactionRepositoryImpl implements TransactionRepository {
  final TransactionDatasource _datasource;

  TransactionRepositoryImpl({required TransactionDatasource datasource})
    : _datasource = datasource;

  @override
  Future<FinancialTransaction> processPayment({
    required String mfId,
    required String accountId,
    required String loanId,
    required String installmentId,
    required double amount,
    required String cardId,
    required String branchId,
  }) async {
    // Verificar saldo suficiente
    final currentBalance = await getAccountBalance(
      mfId: mfId,
      accountId: accountId,
    );
    if (currentBalance < amount) {
      throw Exception('Saldo insuficiente para realizar el pago');
    }

    // Crear transacciones atómicas: débito de cuenta y registro de pago
    final transactionData = [
      {
        'mfId': mfId,
        'type': 'PAYMENT',
        'refType': 'installment',
        'refId': installmentId,
        'debit': amount,
        'credit': 0.0,
        'currency': 'PEN',
        'branchId': branchId,
        'metadata': {
          'accountId': accountId,
          'loanId': loanId,
          'cardId': cardId,
          'paymentType': 'installment',
        },
      },
      {
        'mfId': mfId,
        'type': 'ACCOUNT_DEBIT',
        'refType': 'account',
        'refId': accountId,
        'debit': amount,
        'credit': 0.0,
        'currency': 'PEN',
        'branchId': branchId,
        'metadata': {
          'loanId': loanId,
          'installmentId': installmentId,
          'cardId': cardId,
        },
      },
    ];

    final newBalance = currentBalance - amount;
    final transactions = await _datasource.executeAtomicTransaction(
      mfId: mfId,
      transactionData: transactionData,
      accountId: accountId,
      newBalance: newBalance,
    );

    // Actualizar el status de la cuota a 'paid'
    await _datasource.updateInstallmentStatus(
      mfId: mfId,
      loanId: loanId,
      installmentId: installmentId,
      status: 'paid',
    );

    // Retornar la transacción de pago (primera en la lista)
    return transactions.first;
  }

  @override
  Future<FinancialTransaction> processDisbursement({
    required String mfId,
    required String accountId,
    required String loanId,
    required double amount,
    required String branchId,
  }) async {
    final currentBalance = await getAccountBalance(
      mfId: mfId,
      accountId: accountId,
    );

    // Crear transacciones atómicas: crédito a cuenta y registro de desembolso
    final transactionData = [
      {
        'mfId': mfId,
        'type': 'DISBURSEMENT',
        'refType': 'loan',
        'refId': loanId,
        'debit': 0.0,
        'credit': amount,
        'currency': 'PEN',
        'branchId': branchId,
        'metadata': {'accountId': accountId, 'disbursementType': 'loan'},
      },
      {
        'mfId': mfId,
        'type': 'ACCOUNT_CREDIT',
        'refType': 'account',
        'refId': accountId,
        'debit': 0.0,
        'credit': amount,
        'currency': 'PEN',
        'branchId': branchId,
        'metadata': {'loanId': loanId, 'disbursementType': 'loan'},
      },
    ];

    final newBalance = currentBalance + amount;
    final transactions = await _datasource.executeAtomicTransaction(
      mfId: mfId,
      transactionData: transactionData,
      accountId: accountId,
      newBalance: newBalance,
    );

    // Retornar la transacción de desembolso (primera en la lista)
    return transactions.first;
  }

  @override
  Future<List<FinancialTransaction>> getTransactionHistory({
    required String mfId,
    required String accountId,
    int? limit,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    return await _datasource.getTransactions(
      mfId: mfId,
      refType: 'account',
      refId: accountId,
      startDate: startDate,
      endDate: endDate,
      limit: limit,
    );
  }

  @override
  Future<List<FinancialTransaction>> getCardTransactions({
    required String mfId,
    required String cardId,
    int? limit,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    print('💳 TransactionRepository: Getting transactions for cardId: $cardId');

    // Obtener todas las transacciones y filtrar por cardId en metadata
    final allTransactions = await _datasource.getTransactions(
      mfId: mfId,
      startDate: startDate,
      endDate: endDate,
      limit: limit != null ? limit * 2 : null, // Obtener más para filtrar
    );

    print(
      '💳 TransactionRepository: Found ${allTransactions.length} total transactions',
    );

    // Filtrar transacciones que contengan el cardId en metadata
    // Solo mostrar transacciones de tipo PAYMENT (no ACCOUNT_DEBIT)
    final cardTransactions = allTransactions.where((transaction) {
      final metadata = transaction.metadata;
      final transactionCardId = metadata?['cardId'];

      // Solo incluir transacciones de tipo PAYMENT, PURCHASE, WITHDRAWAL, etc.
      // Excluir ACCOUNT_DEBIT y ACCOUNT_CREDIT (esas son para la cuenta)
      final isCardTransaction =
          transaction.type != 'ACCOUNT_DEBIT' &&
          transaction.type != 'ACCOUNT_CREDIT';

      final matches = transactionCardId == cardId && isCardTransaction;

      print(
        '💳 TransactionRepository: Transaction ${transaction.id} - type: ${transaction.type}, cardId: $transactionCardId, matches: $matches',
      );

      return matches;
    }).toList();

    print(
      '💳 TransactionRepository: Filtered to ${cardTransactions.length} card transactions',
    );

    // Aplicar límite después del filtrado
    if (limit != null && cardTransactions.length > limit) {
      return cardTransactions.take(limit).toList();
    }

    return cardTransactions;
  }

  @override
  Future<double> getAccountBalance({
    required String mfId,
    required String accountId,
  }) async {
    return await _datasource.calculateAccountBalance(
      mfId: mfId,
      accountId: accountId,
    );
  }

  @override
  Future<bool> hasSufficientBalance({
    required String mfId,
    required String accountId,
    required double amount,
  }) async {
    final balance = await getAccountBalance(mfId: mfId, accountId: accountId);
    return balance >= amount;
  }

  @override
  Future<FinancialTransaction?> getTransactionById({
    required String mfId,
    required String transactionId,
  }) async {
    return await _datasource.getTransactionById(
      mfId: mfId,
      transactionId: transactionId,
    );
  }

  @override
  Future<List<FinancialTransaction>> getTransactionsByReference({
    required String mfId,
    required String refType,
    required String refId,
  }) async {
    return await _datasource.getTransactions(
      mfId: mfId,
      refType: refType,
      refId: refId,
    );
  }

  @override
  Future<void> updateInstallmentStatus({
    required String mfId,
    required String loanId,
    required String installmentId,
    required String status,
  }) async {
    await _datasource.updateInstallmentStatus(
      mfId: mfId,
      loanId: loanId,
      installmentId: installmentId,
      status: status,
    );
  }
}
