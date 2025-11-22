import '../../entities/account.dart';
import '../../repositories/account_repository.dart';
import '../core/usecase.dart';
import 'package:fpdart/fpdart.dart';
import '../../core/error/failures.dart';

class UpdateAccountUseCase implements UseCase<void, Account> {
  UpdateAccountUseCase(this.repository);

  final AccountRepository repository;

  @override
  Future<Either<Failure, void>> call(Account account) async {
    try {
      await repository.updateAccount(account);
      return const Right(null);
    } catch (e) {
      return Left(UnknownFailure(e.toString(), code: 'update_account'));
    }
  }
}
