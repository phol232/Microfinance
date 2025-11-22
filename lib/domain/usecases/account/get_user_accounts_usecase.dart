import '../../entities/account.dart';
import '../../repositories/account_repository.dart';
import '../core/usecase.dart';
import '../../core/error/failures.dart';
import 'package:fpdart/fpdart.dart';
import 'dart:async';

class GetUserAccountsUseCase implements StreamUseCase<List<Account>, String> {
  final AccountRepository repository;

  GetUserAccountsUseCase(this.repository);

  @override
  Stream<Either<Failure, List<Account>>> call(String userId) {
    return repository.getUserAccounts(userId).transform(
          StreamTransformer.fromHandlers(
            handleData: (data, sink) => sink.add(Right(data)),
            handleError: (error, stackTrace, sink) => sink.add(
              Left(
                UnknownFailure(error.toString(), code: 'account_stream'),
              ),
            ),
          ),
        );
  }
}
