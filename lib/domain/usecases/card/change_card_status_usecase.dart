import 'package:fpdart/fpdart.dart';

import '../../core/error/failures.dart';
import '../../repositories/card_repository.dart';
import '../core/usecase.dart';

class CardStatusParams {
  const CardStatusParams({
    required this.cardId,
    required this.microfinancieraId,
  });

  final String cardId;
  final String microfinancieraId;
}

class BlockCardUseCase implements UseCase<void, CardStatusParams> {
  BlockCardUseCase(this.repository);

  final CardRepository repository;

  @override
  Future<Either<Failure, void>> call(CardStatusParams params) async {
    try {
      await repository.blockCard(params.cardId, params.microfinancieraId);
      return const Right(null);
    } catch (e) {
      return Left(UnknownFailure(e.toString(), code: 'block_card'));
    }
  }
}

class UnblockCardUseCase implements UseCase<void, CardStatusParams> {
  UnblockCardUseCase(this.repository);

  final CardRepository repository;

  @override
  Future<Either<Failure, void>> call(CardStatusParams params) async {
    try {
      await repository.unblockCard(params.cardId, params.microfinancieraId);
      return const Right(null);
    } catch (e) {
      return Left(UnknownFailure(e.toString(), code: 'unblock_card'));
    }
  }
}

class CancelCardUseCase implements UseCase<void, CardStatusParams> {
  CancelCardUseCase(this.repository);

  final CardRepository repository;

  @override
  Future<Either<Failure, void>> call(CardStatusParams params) async {
    try {
      await repository.cancelCard(params.cardId, params.microfinancieraId);
      return const Right(null);
    } catch (e) {
      return Left(UnknownFailure(e.toString(), code: 'cancel_card'));
    }
  }
}

class ActivateCardUseCase implements UseCase<void, CardStatusParams> {
  ActivateCardUseCase(this.repository);

  final CardRepository repository;

  @override
  Future<Either<Failure, void>> call(CardStatusParams params) async {
    try {
      await repository.activateCard(params.cardId, params.microfinancieraId);
      return const Right(null);
    } catch (e) {
      return Left(UnknownFailure(e.toString(), code: 'activate_card'));
    }
  }
}
