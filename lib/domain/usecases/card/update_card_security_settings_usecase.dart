import 'package:fpdart/fpdart.dart';

import '../../core/error/failures.dart';
import '../../repositories/card_repository.dart';
import '../core/usecase.dart';

class UpdateCardSecuritySettingsParams {
  const UpdateCardSecuritySettingsParams({
    required this.cardId,
    required this.microfinancieraId,
    this.isContactlessEnabled,
    this.isOnlineEnabled,
    this.isAtmEnabled,
    this.isInternationalEnabled,
  });

  final String cardId;
  final String microfinancieraId;
  final bool? isContactlessEnabled;
  final bool? isOnlineEnabled;
  final bool? isAtmEnabled;
  final bool? isInternationalEnabled;
}

class UpdateCardSecuritySettingsUseCase
    implements UseCase<void, UpdateCardSecuritySettingsParams> {
  UpdateCardSecuritySettingsUseCase(this.repository);

  final CardRepository repository;

  @override
  Future<Either<Failure, void>> call(
    UpdateCardSecuritySettingsParams params,
  ) async {
    try {
      await repository.updateCardSecuritySettings(
        params.cardId,
        params.microfinancieraId,
        isContactlessEnabled: params.isContactlessEnabled,
        isOnlineEnabled: params.isOnlineEnabled,
        isAtmEnabled: params.isAtmEnabled,
        isInternationalEnabled: params.isInternationalEnabled,
      );
      return const Right(null);
    } catch (e) {
      return Left(
        UnknownFailure(e.toString(), code: 'card_security_settings'),
      );
    }
  }
}
