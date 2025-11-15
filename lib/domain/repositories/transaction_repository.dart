import '../entities/transaction.dart';

abstract class TransactionRepository {
  Future<FinancialTransaction> processPayment({
    required String mfId,
    required String accountId,
    required String loanId,
    required String installmentId,
    required double amount,
    required String cardId,
    required String branchId,
  });

  Future<FinancialTransaction> processDisbursement({
    required String mfId,
    required String accountId,
    required String loanId,
    required double amount,
    required String branchId,
  });

  Future<List<FinancialTransaction>> getTransactionHistory({
    required String mfId,
    required String accountId,
    int? limit,
    DateTime? startDate,
    DateTime? endDate,
  });

  Future<List<FinancialTransaction>> getCardTransactions({
    required String mfId,
    required String cardId,
    int? limit,
    DateTime? startDate,
    DateTime? endDate,
  });

  Future<double> getAccountBalance({
    required String mfId,
    required String accountId,
  });

  Future<bool> hasSufficientBalance({
    required String mfId,
    required String accountId,
    required double amount,
  });

  Future<FinancialTransaction?> getTransactionById({
    required String mfId,
    required String transactionId,
  });

  Future<List<FinancialTransaction>> getTransactionsByReference({
    required String mfId,
    required String refType,
    required String refId,
  });

  Future<void> updateInstallmentStatus({
    required String mfId,
    required String loanId,
    required String installmentId,
    required String status,
  });
}