import '../../entities/card.dart';
import '../../repositories/card_repository.dart';
import '../core/usecase.dart';

class GetCardsByAccountUseCase implements StreamUseCase<List<Card>, GetCardsByAccountParams> {
  final CardRepository repository;

  GetCardsByAccountUseCase(this.repository);

  @override
  Stream<List<Card>> call(GetCardsByAccountParams params) {
    return repository.getCardsByAccount(params.accountId, params.microfinancieraId);
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