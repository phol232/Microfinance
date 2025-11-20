import 'package:fpdart/fpdart.dart';

import 'package:mobile/domain/core/error/failures.dart';
import 'package:mobile/domain/entities/transaction.dart';
import 'package:mobile/domain/usecases/transaction/get_account_balance_usecase.dart';
import 'package:mobile/domain/usecases/transaction/get_card_transactions_usecase.dart';
import 'package:mobile/domain/usecases/transaction/get_transaction_history_usecase.dart';
import 'package:mobile/domain/usecases/transaction/process_disbursement_usecase.dart';
import 'package:mobile/domain/usecases/transaction/process_payment_usecase.dart';

class TransactionService {
  final ProcessPaymentUseCase _processPaymentUseCase;
  final ProcessDisbursementUseCase _processDisbursementUseCase;
  final GetTransactionHistoryUseCase _getTransactionHistoryUseCase;
  final GetCardTransactionsUseCase _getCardTransactionsUseCase;
  final GetAccountBalanceUseCase _getAccountBalanceUseCase;

  TransactionService({
    required ProcessPaymentUseCase processPaymentUseCase,
    required ProcessDisbursementUseCase processDisbursementUseCase,
    required GetTransactionHistoryUseCase getTransactionHistoryUseCase,
    required GetCardTransactionsUseCase getCardTransactionsUseCase,
    required GetAccountBalanceUseCase getAccountBalanceUseCase,
  })  : _processPaymentUseCase = processPaymentUseCase,
        _processDisbursementUseCase = processDisbursementUseCase,
        _getTransactionHistoryUseCase = getTransactionHistoryUseCase,
        _getCardTransactionsUseCase = getCardTransactionsUseCase,
        _getAccountBalanceUseCase = getAccountBalanceUseCase;

  /// Procesa el pago de una cuota
  Future<Either<Failure, FinancialTransaction>> processInstallmentPayment({
    required String mfId,
    required String accountId,
    required String loanId,
    required String installmentId,
    required double amount,
    required String cardId,
    required String branchId,
  }) async {
    print('🏦 TransactionService: Starting installment payment processing');
    print('🏦 TransactionService: mfId: $mfId, accountId: $accountId');
    print('🏦 TransactionService: loanId: $loanId, installmentId: $installmentId');
    print('🏦 TransactionService: amount: $amount, cardId: $cardId, branchId: $branchId');
    
    final result = await _processPaymentUseCase(ProcessPaymentParams(
      mfId: mfId,
      accountId: accountId,
      loanId: loanId,
      installmentId: installmentId,
      amount: amount,
      cardId: cardId,
      branchId: branchId,
    ));
    
    result.fold(
      (failure) => print('❌ TransactionService: Payment failed: ${failure.message}'),
      (transaction) => print('✅ TransactionService: Payment processed successfully, transaction ID: ${transaction.id}'),
    );
    
    return result;
  }

  /// Procesa el desembolso de un crédito
  Future<Either<Failure, FinancialTransaction>> processLoanDisbursement({
    required String mfId,
    required String accountId,
    required String loanId,
    required double amount,
    required String branchId,
  }) async {
    return await _processDisbursementUseCase(ProcessDisbursementParams(
      mfId: mfId,
      accountId: accountId,
      loanId: loanId,
      amount: amount,
      branchId: branchId,
    ));
  }

  /// Obtiene el historial de transacciones de una cuenta
  Future<Either<Failure, List<FinancialTransaction>>> getAccountTransactionHistory({
    required String mfId,
    required String accountId,
    int? limit,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    return await _getTransactionHistoryUseCase(GetTransactionHistoryParams(
      mfId: mfId,
      accountId: accountId,
      limit: limit,
      startDate: startDate,
      endDate: endDate,
    ));
  }

  /// Obtiene el saldo actual de una cuenta
  Future<Either<Failure, double>> getAccountBalance({
    required String mfId,
    required String accountId,
  }) async {
    return await _getAccountBalanceUseCase(GetAccountBalanceParams(
      mfId: mfId,
      accountId: accountId,
    ));
  }

  /// Valida si se puede realizar un pago
  Future<Either<Failure, bool>> canProcessPayment({
    required String mfId,
    required String accountId,
    required double amount,
  }) async {
    print('🔍 TransactionService: Validating payment capability');
    print('🔍 TransactionService: mfId: $mfId, accountId: $accountId, amount: $amount');
    
    if (amount <= 0) {
      print('❌ TransactionService: Invalid amount: $amount');
      return left(const ValidationFailure('El monto debe ser mayor a cero'));
    }

    final balanceResult = await getAccountBalance(
      mfId: mfId,
      accountId: accountId,
    );

    return balanceResult.fold(
      (failure) {
        print('❌ TransactionService: Failed to get balance: ${failure.message}');
        return left(failure);
      },
      (balance) {
        final canPay = balance >= amount;
        print('💰 TransactionService: Current balance: $balance, required: $amount, can pay: $canPay');
        return right(canPay);
      },
    );
  }

  /// Formatea el monto para mostrar en la UI
  String formatAmount(double amount, {String currency = 'PEN'}) {
    switch (currency) {
      case 'PEN':
        return 'S/ ${amount.toStringAsFixed(2)}';
      case 'USD':
        return '\$ ${amount.toStringAsFixed(2)}';
      default:
        return '${amount.toStringAsFixed(2)} $currency';
    }
  }

  /// Obtiene el tipo de transacción en español
  String getTransactionTypeLabel(String type) {
    switch (type) {
      case 'PAYMENT':
        return 'Pago de Cuota';
      case 'DISBURSEMENT':
        return 'Desembolso';
      case 'ACCOUNT_DEBIT':
        return 'Débito de Cuenta';
      case 'ACCOUNT_CREDIT':
        return 'Crédito a Cuenta';
      case 'TRANSFER':
        return 'Transferencia';
      default:
        return type;
    }
  }

  /// Determina si una transacción es un ingreso o egreso
  bool isIncome(FinancialTransaction transaction) {
    return transaction.credit > 0;
  }

  /// Obtiene el monto neto de una transacción (positivo para ingresos, negativo para egresos)
  double getNetAmount(FinancialTransaction transaction) {
    return transaction.credit - transaction.debit;
  }

  /// Calcula el saldo después de aplicar una lista de transacciones
  double calculateBalanceAfterTransactions(
    double initialBalance,
    List<FinancialTransaction> transactions,
  ) {
    double balance = initialBalance;
    for (final transaction in transactions) {
      balance += getNetAmount(transaction);
    }
    return balance;
  }

  /// Agrupa transacciones por fecha
  Map<DateTime, List<FinancialTransaction>> groupTransactionsByDate(
    List<FinancialTransaction> transactions,
  ) {
    final Map<DateTime, List<FinancialTransaction>> grouped = {};
    
    for (final transaction in transactions) {
      final date = DateTime(
        transaction.createdAt.year,
        transaction.createdAt.month,
        transaction.createdAt.day,
      );
      
      if (grouped[date] == null) {
        grouped[date] = [];
      }
      grouped[date]!.add(transaction);
    }
    
    return grouped;
  }

  /// Obtiene el historial de transacciones de una tarjeta
  Future<Either<Failure, List<FinancialTransaction>>> getCardTransactionHistory({
    required String mfId,
    required String cardId,
    int? limit,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    return await _getCardTransactionsUseCase(GetCardTransactionsParams(
      mfId: mfId,
      cardId: cardId,
      limit: limit,
      startDate: startDate,
      endDate: endDate,
    ));
  }
}
