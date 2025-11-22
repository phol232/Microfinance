import 'package:fpdart/fpdart.dart';

import '../../core/error/failures.dart';
import '../../entities/card.dart';
import '../../repositories/card_repository.dart';
import '../core/usecase.dart';

class UpdateCardUseCase implements UseCase<void, UpdateCardParams> {
  UpdateCardUseCase(this.repository);

  final CardRepository repository;

  @override
  Future<Either<Failure, void>> call(UpdateCardParams params) async {
    try {
      await repository.updateCard(params.card, params.microfinancieraId);
      return const Right(null);
    } catch (e) {
      return Left(UnknownFailure(e.toString(), code: 'update_card'));
    }
  }
}

class UpdateCardParams {
  const UpdateCardParams({required this.card, required this.microfinancieraId});

  final Card card;
  final String microfinancieraId;
}
