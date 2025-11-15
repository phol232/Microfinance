import 'package:fpdart/fpdart.dart';
import '../../entities/transaction.dart';
import '../../repositories/transaction_repository.dart';
import '../../core/error/failures.dart';
import '../usecase.dart';

class ProcessDisbursementParams {
  final String mfId;
  final String accountId;
  final String loanId;
  final double amount;
  final String branchId;

  ProcessDisbursementParams({
    required this.mfId,
    required this.accountId,
    required this.loanId,
    required this.amount,
    required this.branchId,
  });
}

class ProcessDisbursementUseCase implements UseCase<FinancialTransaction, ProcessDisbursementParams> {
  final TransactionRepository repository;

  ProcessDisbursementUseCase(this.repository);

  @override
  Future<Either<Failure, FinancialTransaction>> call(ProcessDisbursementParams params) async {
    try {
      // Validar que el monto sea positivo
      if (params.amount <= 0) {
        return left(const ValidationFailure('El monto del desembolso debe ser mayor a cero'));
      }

      // Procesar el desembolso
      final transaction = await repository.processDisbursement(
        mfId: params.mfId,
        accountId: params.accountId,
        loanId: params.loanId,
        amount: params.amount,
        branchId: params.branchId,
      );

      return right(transaction);
    } catch (e) {
      return left(ServerFailure('Error al procesar el desembolso: ${e.toString()}'));
    }
  }
}