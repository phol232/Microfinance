import '../../entities/account.dart';
import '../../repositories/account_repository.dart';
import '../core/usecase.dart';

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
  Future<Account?> call(GetAccountByIdParams params) {
    return repository.getAccountById(params.accountId, params.microfinancieraId);
  }
}