import 'package:fpdart/fpdart.dart';
import '../../entities/transaction.dart';
import '../../repositories/transaction_repository.dart';
import '../../core/error/failures.dart';
import '../usecase.dart';

class GetCardTransactionsParams {
  final String mfId;
  final String cardId;
  final int? limit;
  final DateTime? startDate;
  final DateTime? endDate;

  GetCardTransactionsParams({
    required this.mfId,
    required this.cardId,
    this.limit,
    this.startDate,
    this.endDate,
  });
}

class GetCardTransactionsUseCase implements UseCase<List<FinancialTransaction>, GetCardTransactionsParams> {
  final TransactionRepository repository;

  GetCardTransactionsUseCase(this.repository);

  @override
  Future<Either<Failure, List<FinancialTransaction>>> call(GetCardTransactionsParams params) async {
    try {
      // Validar fechas si se proporcionan
      if (params.startDate != null && params.endDate != null) {
        if (params.startDate!.isAfter(params.endDate!)) {
          return left(const ValidationFailure('La fecha de inicio no puede ser posterior a la fecha de fin'));
        }
      }

      // Obtener transacciones de la tarjeta
      final transactions = await repository.getCardTransactions(
        mfId: params.mfId,
        cardId: params.cardId,
        limit: params.limit,
        startDate: params.startDate,
        endDate: params.endDate,
      );

      return right(transactions);
    } catch (e) {
      return left(ServerFailure('Error al obtener las transacciones de la tarjeta: ${e.toString()}'));
    }
  }
}