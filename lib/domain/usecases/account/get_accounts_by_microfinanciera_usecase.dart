import '../../entities/account.dart';
import '../../repositories/account_repository.dart';
import '../core/usecase.dart';
import '../../core/error/failures.dart';
import 'package:fpdart/fpdart.dart';
import 'dart:async';

class GetAccountsByMicrofinancieraUseCase
    implements StreamUseCase<List<Account>, String> {
  GetAccountsByMicrofinancieraUseCase(this.repository);

  final AccountRepository repository;

  @override
  Stream<Either<Failure, List<Account>>> call(String microfinancieraId) {
    return repository
        .getAccountsByMicrofinanciera(microfinancieraId)
        .transform(
          StreamTransformer.fromHandlers(
            handleData: (data, sink) => sink.add(Right(data)),
            handleError: (error, stackTrace, sink) => sink.add(
              Left(
                UnknownFailure(error.toString(), code: 'accounts_by_mf'),
              ),
            ),
          ),
        );
  }
}
