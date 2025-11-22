import '../../entities/card.dart';
import '../../repositories/card_repository.dart';
import '../core/usecase.dart';
import '../../core/error/failures.dart';
import 'package:fpdart/fpdart.dart';
import 'dart:async';

class GetUserCardsUseCase implements StreamUseCase<List<Card>, GetUserCardsParams> {
  final CardRepository repository;

  GetUserCardsUseCase(this.repository);

  @override
  Stream<Either<Failure, List<Card>>> call(GetUserCardsParams params) {
    return repository
        .getUserCards(params.userId, params.microfinancieraId)
        .transform(
          StreamTransformer.fromHandlers(
            handleData: (data, sink) => sink.add(Right(data)),
            handleError: (error, stackTrace, sink) => sink.add(
              Left(UnknownFailure(error.toString(), code: 'cards_user')),
            ),
          ),
        );
  }
}

class GetUserCardsParams {
  final String userId;
  final String microfinancieraId;

  GetUserCardsParams({
    required this.userId,
    required this.microfinancieraId,
  });
}
