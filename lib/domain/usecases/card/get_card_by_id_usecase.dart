import 'package:fpdart/fpdart.dart';

import '../../core/error/failures.dart';
import '../../entities/card.dart';
import '../../repositories/card_repository.dart';
import '../core/usecase.dart';

class GetCardByIdParams {
  const GetCardByIdParams({required this.cardId, required this.microfinancieraId});

  final String cardId;
  final String microfinancieraId;
}

class GetCardByIdUseCase implements UseCase<Card?, GetCardByIdParams> {
  GetCardByIdUseCase(this.repository);

  final CardRepository repository;

  @override
  Future<Either<Failure, Card?>> call(GetCardByIdParams params) async {
    try {
      final card = await repository.getCardById(
        params.cardId,
        params.microfinancieraId,
      );
      return Right(card);
    } catch (e) {
      return Left(UnknownFailure(e.toString(), code: 'card_by_id'));
    }
  }
}
