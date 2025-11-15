import 'package:fpdart/fpdart.dart';
import '../../entities/transaction.dart';
import '../../repositories/transaction_repository.dart';
import '../../core/error/failures.dart';
import '../usecase.dart';

class ProcessPaymentParams {
  final String mfId;
  final String accountId;
  final String loanId;
  final String installmentId;
  final double amount;
  final String cardId;
  final String branchId;

  ProcessPaymentParams({
    required this.mfId,
    required this.accountId,
    required this.loanId,
    required this.installmentId,
    required this.amount,
    required this.cardId,
    required this.branchId,
  });
}

class ProcessPaymentUseCase implements UseCase<FinancialTransaction, ProcessPaymentParams> {
  final TransactionRepository repository;

  ProcessPaymentUseCase(this.repository);

  @override
  Future<Either<Failure, FinancialTransaction>> call(ProcessPaymentParams params) async {
    print('🎯 ProcessPaymentUseCase: Starting payment processing');
    print('🎯 ProcessPaymentUseCase: Params - mfId: ${params.mfId}, accountId: ${params.accountId}');
    print('🎯 ProcessPaymentUseCase: Params - loanId: ${params.loanId}, installmentId: ${params.installmentId}');
    print('🎯 ProcessPaymentUseCase: Params - amount: ${params.amount}, cardId: ${params.cardId}');
    
    try {
      // Validar que el monto sea positivo
      if (params.amount <= 0) {
        print('❌ ProcessPaymentUseCase: Invalid amount: ${params.amount}');
        return left(const ValidationFailure('El monto del pago debe ser mayor a cero'));
      }

      print('🔍 ProcessPaymentUseCase: Checking sufficient balance...');
      // Verificar saldo suficiente antes de procesar
      final hasSufficientBalance = await repository.hasSufficientBalance(
        mfId: params.mfId,
        accountId: params.accountId,
        amount: params.amount,
      );

      if (!hasSufficientBalance) {
        print('❌ ProcessPaymentUseCase: Insufficient balance for amount: ${params.amount}');
        return left(const ValidationFailure('Saldo insuficiente para realizar el pago'));
      }

      print('✅ ProcessPaymentUseCase: Sufficient balance confirmed, processing payment...');
      // Procesar el pago
      final transaction = await repository.processPayment(
        mfId: params.mfId,
        accountId: params.accountId,
        loanId: params.loanId,
        installmentId: params.installmentId,
        amount: params.amount,
        cardId: params.cardId,
        branchId: params.branchId,
      );

      print('✅ ProcessPaymentUseCase: Payment processed successfully, transaction ID: ${transaction.id}');
      return right(transaction);
    } catch (e) {
      print('❌ ProcessPaymentUseCase: Exception occurred: ${e.toString()}');
      return left(ServerFailure('Error al procesar el pago: ${e.toString()}'));
    }
  }
}