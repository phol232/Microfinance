import 'package:fpdart/fpdart.dart';
import '../../repositories/transaction_repository.dart';
import '../../core/error/failures.dart';
import '../usecase.dart';

class GetAccountBalanceParams {
  final String mfId;
  final String accountId;

  GetAccountBalanceParams({
    required this.mfId,
    required this.accountId,
  });
}

class GetAccountBalanceUseCase implements UseCase<double, GetAccountBalanceParams> {
  final TransactionRepository repository;

  GetAccountBalanceUseCase(this.repository);

  @override
  Future<Either<Failure, double>> call(GetAccountBalanceParams params) async {
    try {
      final balance = await repository.getAccountBalance(
        mfId: params.mfId,
        accountId: params.accountId,
      );

      return right(balance);
    } catch (e) {
      return left(ServerFailure('Error al obtener el saldo de la cuenta: ${e.toString()}'));
    }
  }
}