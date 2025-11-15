import 'package:equatable/equatable.dart';
import '../../../domain/entities/card.dart';
import '../../../domain/usecases/card/request_card_usecase.dart';

abstract class CardEvent extends Equatable {
  const CardEvent();

  @override
  List<Object?> get props => [];
}

class CardLoadUserCards extends CardEvent {
  final String userId;
  final String microfinancieraId;

  const CardLoadUserCards(this.userId, this.microfinancieraId);

  @override
  List<Object?> get props => [userId, microfinancieraId];
}

class CardLoadByAccount extends CardEvent {
  final String accountId;
  final String microfinancieraId;

  const CardLoadByAccount(this.accountId, this.microfinancieraId);

  @override
  List<Object?> get props => [accountId, microfinancieraId];
}

class CardRequest extends CardEvent {
  final RequestCardParams params;

  const CardRequest(this.params);

  @override
  List<Object?> get props => [params];
}

class CardUpdate extends CardEvent {
  final Card card;
  final String microfinancieraId;

  const CardUpdate(this.card, this.microfinancieraId);

  @override
  List<Object?> get props => [card, microfinancieraId];
}

class CardBlock extends CardEvent {
  final String cardId;
  final String microfinancieraId;

  const CardBlock(this.cardId, this.microfinancieraId);

  @override
  List<Object?> get props => [cardId, microfinancieraId];
}

class CardUnblock extends CardEvent {
  final String cardId;
  final String microfinancieraId;

  const CardUnblock(this.cardId, this.microfinancieraId);

  @override
  List<Object?> get props => [cardId, microfinancieraId];
}

class CardCancel extends CardEvent {
  final String cardId;
  final String microfinancieraId;

  const CardCancel(this.cardId, this.microfinancieraId);

  @override
  List<Object?> get props => [cardId, microfinancieraId];
}

class CardActivate extends CardEvent {
  final String cardId;
  final String microfinancieraId;

  const CardActivate(this.cardId, this.microfinancieraId);

  @override
  List<Object?> get props => [cardId, microfinancieraId];
}

class CardLoadById extends CardEvent {
  final String cardId;
  final String microfinancieraId;

  const CardLoadById(this.cardId, this.microfinancieraId);

  @override
  List<Object?> get props => [cardId, microfinancieraId];
}

class CardLoadByStatus extends CardEvent {
  final String userId;
  final CardStatus status;
  final String microfinancieraId;

  const CardLoadByStatus(this.userId, this.status, this.microfinancieraId);

  @override
  List<Object?> get props => [userId, status, microfinancieraId];
}

class CardUpdateLimits extends CardEvent {
  final String cardId;
  final String microfinancieraId;
  final double? dailyLimit;
  final double? monthlyLimit;
  final double? atmLimit;
  final double? onlineLimit;

  const CardUpdateLimits(
    this.cardId,
    this.microfinancieraId, {
    this.dailyLimit,
    this.monthlyLimit,
    this.atmLimit,
    this.onlineLimit,
  });

  @override
  List<Object?> get props => [cardId, microfinancieraId, dailyLimit, monthlyLimit, atmLimit, onlineLimit];
}

class CardUpdateSecuritySettings extends CardEvent {
  final String cardId;
  final String microfinancieraId;
  final bool? isContactlessEnabled;
  final bool? isOnlineEnabled;
  final bool? isAtmEnabled;
  final bool? isInternationalEnabled;

  const CardUpdateSecuritySettings(
    this.cardId,
    this.microfinancieraId, {
    this.isContactlessEnabled,
    this.isOnlineEnabled,
    this.isAtmEnabled,
    this.isInternationalEnabled,
  });

  @override
  List<Object?> get props => [
    cardId,
    microfinancieraId,
    isContactlessEnabled,
    isOnlineEnabled,
    isAtmEnabled,
    isInternationalEnabled,
  ];
}