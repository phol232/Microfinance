import '../../entities/card.dart';
import '../../repositories/card_repository.dart';
import '../core/usecase.dart';

class GetUserCardsUseCase implements StreamUseCase<List<Card>, GetUserCardsParams> {
  final CardRepository repository;

  GetUserCardsUseCase(this.repository);

  @override
  Stream<List<Card>> call(GetUserCardsParams params) {
    return repository.getUserCards(params.userId, params.microfinancieraId);
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