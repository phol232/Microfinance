import 'package:fpdart/fpdart.dart';

import '../../core/error/failures.dart';
import '../../repositories/card_repository.dart';
import '../core/usecase.dart';

class UpdateCardLimitsParams {
  const UpdateCardLimitsParams({
    required this.cardId,
    required this.microfinancieraId,
    this.dailyLimit,
    this.monthlyLimit,
    this.atmLimit,
    this.onlineLimit,
  });

  final String cardId;
  final String microfinancieraId;
  final double? dailyLimit;
  final double? monthlyLimit;
  final double? atmLimit;
  final double? onlineLimit;
}

class UpdateCardLimitsUseCase
    implements UseCase<void, UpdateCardLimitsParams> {
  UpdateCardLimitsUseCase(this.repository);

  final CardRepository repository;

  @override
  Future<Either<Failure, void>> call(UpdateCardLimitsParams params) async {
    try {
      await repository.updateCardLimits(
        params.cardId,
        params.microfinancieraId,
        dailyLimit: params.dailyLimit,
        monthlyLimit: params.monthlyLimit,
        atmLimit: params.atmLimit,
        onlineLimit: params.onlineLimit,
      );
      return const Right(null);
    } catch (e) {
      return Left(UnknownFailure(e.toString(), code: 'card_limits'));
    }
  }
}
