import 'package:fpdart/fpdart.dart';
import '../../entities/transaction.dart';
import '../../repositories/transaction_repository.dart';
import '../../core/error/failures.dart';
import '../usecase.dart';

class GetTransactionHistoryParams {
  final String mfId;
  final String accountId;
  final int? limit;
  final DateTime? startDate;
  final DateTime? endDate;

  GetTransactionHistoryParams({
    required this.mfId,
    required this.accountId,
    this.limit,
    this.startDate,
    this.endDate,
  });
}

class GetTransactionHistoryUseCase implements UseCase<List<FinancialTransaction>, GetTransactionHistoryParams> {
  final TransactionRepository repository;

  GetTransactionHistoryUseCase(this.repository);

  @override
  Future<Either<Failure, List<FinancialTransaction>>> call(GetTransactionHistoryParams params) async {
    try {
      // Validar fechas si se proporcionan
      if (params.startDate != null && params.endDate != null) {
        if (params.startDate!.isAfter(params.endDate!)) {
          return left(const ValidationFailure('La fecha de inicio no puede ser posterior a la fecha de fin'));
        }
      }

      // Obtener historial de transacciones
      final transactions = await repository.getTransactionHistory(
        mfId: params.mfId,
        accountId: params.accountId,
        limit: params.limit,
        startDate: params.startDate,
        endDate: params.endDate,
      );

      return right(transactions);
    } catch (e) {
      return left(ServerFailure('Error al obtener el historial de transacciones: ${e.toString()}'));
    }
  }
}