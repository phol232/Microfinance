import '../../entities/account.dart';
import '../../repositories/account_repository.dart';
import '../core/usecase.dart';
import '../../core/error/failures.dart';
import 'package:fpdart/fpdart.dart';
import 'dart:async';

class GetAccountsByStatusUseCase
    implements StreamUseCase<List<Account>, GetAccountsByStatusParams> {
  GetAccountsByStatusUseCase(this.repository);

  final AccountRepository repository;

  @override
  Stream<Either<Failure, List<Account>>> call(GetAccountsByStatusParams params) {
    return repository
        .getAccountsByStatus(
          params.userId,
          params.status,
          params.microfinancieraId,
        )
        .transform(
          StreamTransformer.fromHandlers(
            handleData: (data, sink) => sink.add(Right(data)),
            handleError: (error, stackTrace, sink) => sink.add(
              Left(
                UnknownFailure(error.toString(), code: 'accounts_by_status'),
              ),
            ),
          ),
        );
  }
}

class GetAccountsByStatusParams {
  const GetAccountsByStatusParams({
    required this.userId,
    required this.status,
    required this.microfinancieraId,
  });

  final String userId;
  final AccountStatus status;
  final String microfinancieraId;
}
