import '../../entities/account.dart';
import '../../repositories/account_repository.dart';
import '../core/usecase.dart';

class GetUserAccountsUseCase implements StreamUseCase<List<Account>, String> {
  final AccountRepository repository;

  GetUserAccountsUseCase(this.repository);

  @override
  Stream<List<Account>> call(String userId) {
    return repository.getUserAccounts(userId);
  }
}