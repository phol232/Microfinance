import '../../entities/account.dart';
import '../../repositories/account_repository.dart';
import '../core/usecase.dart';
import '../../core/error/failures.dart';
import 'package:fpdart/fpdart.dart';

class GetAccountByIdParams {
  final String accountId;
  final String microfinancieraId;

  GetAccountByIdParams({
    required this.accountId,
    required this.microfinancieraId,
  });
}

class GetAccountByIdUseCase implements UseCase<Account?, GetAccountByIdParams> {
  final AccountRepository repository;

  GetAccountByIdUseCase(this.repository);

  @override
  Future<Either<Failure, Account?>> call(GetAccountByIdParams params) async {
    try {
      final account =
          await repository.getAccountById(params.accountId, params.microfinancieraId);
      return Right(account);
    } catch (e) {
      return Left(UnknownFailure(e.toString(), code: 'account_by_id'));
    }
  }
}
