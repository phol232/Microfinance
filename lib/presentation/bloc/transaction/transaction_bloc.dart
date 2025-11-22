import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../domain/entities/transaction.dart';
import '../../../data/models/transaction_dto.dart';
import 'package:mobile/infrastructure/services/transaction_service.dart';

// Events
abstract class TransactionEvent extends Equatable {
  const TransactionEvent();

  @override
  List<Object?> get props => [];
}

class ProcessPaymentEvent extends TransactionEvent {
  final String mfId;
  final String accountId;
  final String loanId;
  final String installmentId;
  final double amount;
  final String cardId;
  final String branchId;

  const ProcessPaymentEvent({
    required this.mfId,
    required this.accountId,
    required this.loanId,
    required this.installmentId,
    required this.amount,
    required this.cardId,
    required this.branchId,
  });

  @override
  List<Object?> get props => [mfId, accountId, loanId, installmentId, amount, cardId, branchId];
}

class GetAccountBalanceEvent extends TransactionEvent {
  final String mfId;
  final String accountId;

  const GetAccountBalanceEvent({
    required this.mfId,
    required this.accountId,
  });

  @override
  List<Object?> get props => [mfId, accountId];
}

class GetTransactionHistoryEvent extends TransactionEvent {
  final String mfId;
  final String accountId;
  final int? limit;
  final DateTime? startDate;
  final DateTime? endDate;

  const GetTransactionHistoryEvent({
    required this.mfId,
    required this.accountId,
    this.limit,
    this.startDate,
    this.endDate,
  });

  @override
  List<Object?> get props => [mfId, accountId, limit, startDate, endDate];
}

class CheckPaymentStatusEvent extends TransactionEvent {
  final String mfId;
  final String accountId;
  final String installmentId;

  const CheckPaymentStatusEvent({
    required this.mfId,
    required this.accountId,
    required this.installmentId,
  });

  @override
  List<Object?> get props => [mfId, accountId, installmentId];
}

class GetCardTransactionsEvent extends TransactionEvent {
  final String mfId;
  final String cardId;
  final int? limit;
  final DateTime? startDate;
  final DateTime? endDate;

  const GetCardTransactionsEvent({
    required this.mfId,
    required this.cardId,
    this.limit,
    this.startDate,
    this.endDate,
  });

  @override
  List<Object?> get props => [mfId, cardId, limit, startDate, endDate];
}

// States
abstract class TransactionState extends Equatable {
  const TransactionState();

  @override
  List<Object?> get props => [];
}

class TransactionInitial extends TransactionState {}

class TransactionLoading extends TransactionState {}

class PaymentProcessed extends TransactionState {
  final FinancialTransaction transaction;

  const PaymentProcessed(this.transaction);

  @override
  List<Object?> get props => [transaction];
}

class AccountBalanceLoaded extends TransactionState {
  final double balance;

  const AccountBalanceLoaded(this.balance);

  @override
  List<Object?> get props => [balance];
}

class TransactionHistoryLoaded extends TransactionState {
  final List<FinancialTransaction> transactions;

  const TransactionHistoryLoaded(this.transactions);

  @override
  List<Object?> get props => [transactions];
}

class CardTransactionsLoaded extends TransactionState {
  final List<FinancialTransaction> transactions;

  const CardTransactionsLoaded(this.transactions);

  @override
  List<Object?> get props => [transactions];
}

class PaymentStatusChecked extends TransactionState {
  final bool isPaid;

  const PaymentStatusChecked(this.isPaid);

  @override
  List<Object?> get props => [isPaid];
}

class TransactionError extends TransactionState {
  final String message;

  const TransactionError(this.message);

  @override
  List<Object?> get props => [message];
}

// Bloc
class TransactionBloc extends Bloc<TransactionEvent, TransactionState> {
  final TransactionService _transactionService;

  TransactionBloc({required TransactionService transactionService})
      : _transactionService = transactionService,
        super(TransactionInitial()) {
    on<ProcessPaymentEvent>(_onProcessPayment);
    on<GetAccountBalanceEvent>(_onGetAccountBalance);
    on<GetTransactionHistoryEvent>(_onGetTransactionHistory);
    on<CheckPaymentStatusEvent>(_onCheckPaymentStatus);
    on<GetCardTransactionsEvent>(_onGetCardTransactions);
  }

  Future<void> _onProcessPayment(
    ProcessPaymentEvent event,
    Emitter<TransactionState> emit,
  ) async {
    print('💳 TransactionBloc: Starting payment processing');
    print('💳 TransactionBloc: mfId: ${event.mfId}');
    print('💳 TransactionBloc: accountId: ${event.accountId}');
    print('💳 TransactionBloc: loanId: ${event.loanId}');
    print('💳 TransactionBloc: installmentId: ${event.installmentId}');
    print('💳 TransactionBloc: amount: ${event.amount}');
    print('💳 TransactionBloc: cardId: ${event.cardId}');
    print('💳 TransactionBloc: branchId: ${event.branchId}');
    
    emit(TransactionLoading());

    final result = await _transactionService.processInstallmentPayment(
      mfId: event.mfId,
      accountId: event.accountId,
      loanId: event.loanId,
      installmentId: event.installmentId,
      amount: event.amount,
      cardId: event.cardId,
      branchId: event.branchId,
    );

    result.fold(
      (failure) {
        print('❌ TransactionBloc: Payment failed: ${failure.message}');
        emit(TransactionError(failure.message));
      },
      (transaction) {
        print('✅ TransactionBloc: Payment processed successfully');
        print('✅ TransactionBloc: Transaction ID: ${transaction.id}');
        emit(PaymentProcessed(transaction));
      },
    );
  }

  Future<void> _onGetAccountBalance(
    GetAccountBalanceEvent event,
    Emitter<TransactionState> emit,
  ) async {
    emit(TransactionLoading());

    final result = await _transactionService.getAccountBalance(
      mfId: event.mfId,
      accountId: event.accountId,
    );

    result.fold(
      (failure) => emit(TransactionError(failure.message)),
      (balance) => emit(AccountBalanceLoaded(balance)),
    );
  }

  Future<void> _onGetTransactionHistory(
    GetTransactionHistoryEvent event,
    Emitter<TransactionState> emit,
  ) async {
    emit(TransactionLoading());

    final result = await _transactionService.getAccountTransactionHistory(
      mfId: event.mfId,
      accountId: event.accountId,
      limit: event.limit,
      startDate: event.startDate,
      endDate: event.endDate,
    );

    result.fold(
      (failure) => emit(TransactionError(failure.message)),
      (transactions) => emit(TransactionHistoryLoaded(transactions)),
    );
  }

  Future<void> _onCheckPaymentStatus(
    CheckPaymentStatusEvent event,
    Emitter<TransactionState> emit,
  ) async {
    print('🔍 TransactionBloc: Checking payment status for installment: ${event.installmentId}');
    print('🔍 TransactionBloc: mfId: ${event.mfId}, accountId: ${event.accountId}');
    
    // Verificar si existe una transacción de pago para esta cuota
    final result = await _transactionService.getAccountTransactionHistory(
      mfId: event.mfId,
      accountId: event.accountId,
    );

    result.fold(
      (failure) {
        print('❌ TransactionBloc: Failed to get transaction history: ${failure.message}');
        emit(TransactionError(failure.message));
      },
      (transactions) {
        print('🔍 TransactionBloc: Found ${transactions.length} transactions');
        
        final isPaid = transactions.any((transaction) {
          final metadata = FinancialTransactionDto.fromDomain(transaction)
                  .toFirestore()['metadata'] as Map<String, dynamic>?;
          final isPaymentForInstallment = transaction.type == 'PAYMENT' && 
                 metadata?['installmentId'] == event.installmentId;
          
          if (isPaymentForInstallment) {
            print('✅ TransactionBloc: Found payment for installment ${event.installmentId}');
          }
          
          return isPaymentForInstallment;
        });
        
        print('🔍 TransactionBloc: Payment status for installment ${event.installmentId}: $isPaid');
        emit(PaymentStatusChecked(isPaid));
      },
    );
  }

  Future<void> _onGetCardTransactions(
    GetCardTransactionsEvent event,
    Emitter<TransactionState> emit,
  ) async {
    emit(TransactionLoading());

    final result = await _transactionService.getCardTransactionHistory(
      mfId: event.mfId,
      cardId: event.cardId,
      limit: event.limit,
      startDate: event.startDate,
      endDate: event.endDate,
    );

    result.fold(
      (failure) => emit(TransactionError(failure.message)),
      (transactions) => emit(CardTransactionsLoaded(transactions)),
    );
  }
}
