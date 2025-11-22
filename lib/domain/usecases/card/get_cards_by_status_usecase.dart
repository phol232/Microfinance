import 'package:fpdart/fpdart.dart';

import '../../core/error/failures.dart';
import '../../entities/card.dart';
import '../../repositories/card_repository.dart';
import '../core/usecase.dart';
import 'dart:async';

class GetCardsByStatusParams {
  const GetCardsByStatusParams({
    required this.userId,
    required this.status,
    required this.microfinancieraId,
  });

  final String userId;
  final CardStatus status;
  final String microfinancieraId;
}

class GetCardsByStatusUseCase
    implements StreamUseCase<List<Card>, GetCardsByStatusParams> {
  GetCardsByStatusUseCase(this.repository);

  final CardRepository repository;

  @override
  Stream<Either<Failure, List<Card>>> call(GetCardsByStatusParams params) {
    return repository
        .getCardsByStatus(params.userId, params.status, params.microfinancieraId)
        .transform(
          StreamTransformer.fromHandlers(
            handleData: (data, sink) => sink.add(Right(data)),
            handleError: (error, stackTrace, sink) => sink.add(
              Left(UnknownFailure(error.toString(), code: 'cards_by_status')),
            ),
          ),
        );
  }
}
