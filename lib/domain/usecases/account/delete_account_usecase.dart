import '../../repositories/account_repository.dart';
import '../core/usecase.dart';
import 'package:fpdart/fpdart.dart';
import '../../core/error/failures.dart';

class DeleteAccountUseCase
    implements UseCase<void, DeleteAccountParams> {
  DeleteAccountUseCase(this.repository);

  final AccountRepository repository;

  @override
  Future<Either<Failure, void>> call(DeleteAccountParams params) async {
    try {
      await repository.deleteAccount(
        params.accountId,
        params.microfinancieraId,
      );
      return const Right(null);
    } catch (e) {
      return Left(UnknownFailure(e.toString(), code: 'delete_account'));
    }
  }
}

class DeleteAccountParams {
  const DeleteAccountParams({
    required this.accountId,
    required this.microfinancieraId,
  });

  final String accountId;
  final String microfinancieraId;
}
