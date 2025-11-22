import '../../entities/card.dart';
import '../../repositories/card_repository.dart';
import '../core/usecase.dart';
import '../../core/error/failures.dart';
import 'package:fpdart/fpdart.dart';
import 'dart:async';

class GetCardsByAccountUseCase implements StreamUseCase<List<Card>, GetCardsByAccountParams> {
  final CardRepository repository;

  GetCardsByAccountUseCase(this.repository);

  @override
  Stream<Either<Failure, List<Card>>> call(GetCardsByAccountParams params) {
    return repository
        .getCardsByAccount(params.accountId, params.microfinancieraId)
        .transform(
          StreamTransformer.fromHandlers(
            handleData: (data, sink) => sink.add(Right(data)),
            handleError: (error, stackTrace, sink) => sink.add(
              Left(UnknownFailure(error.toString(), code: 'cards_by_account')),
            ),
          ),
        );
  }
}

class GetCardsByAccountParams {
  final String accountId;
  final String microfinancieraId;

  GetCardsByAccountParams({
    required this.accountId,
    required this.microfinancieraId,
  });
}
