import 'package:equatable/equatable.dart';
import '../../../domain/entities/card.dart';

abstract class CardState extends Equatable {
  const CardState();

  @override
  List<Object?> get props => [];
}

class CardInitial extends CardState {
  const CardInitial();
}

class CardLoading extends CardState {
  const CardLoading();
}

class CardLoaded extends CardState {
  final List<Card> cards;

  const CardLoaded(this.cards);

  @override
  List<Object?> get props => [cards];
}

class CardSingleLoaded extends CardState {
  final Card card;

  const CardSingleLoaded(this.card);

  @override
  List<Object?> get props => [card];
}

class CardRequested extends CardState {
  final String cardId;

  const CardRequested(this.cardId);

  @override
  List<Object?> get props => [cardId];
}

class CardUpdated extends CardState {
  const CardUpdated();
}

class CardBlocked extends CardState {
  const CardBlocked();
}

class CardUnblocked extends CardState {
  const CardUnblocked();
}

class CardCancelled extends CardState {
  const CardCancelled();
}

class CardActivated extends CardState {
  const CardActivated();
}

class CardLimitsUpdated extends CardState {
  const CardLimitsUpdated();
}

class CardSecuritySettingsUpdated extends CardState {
  const CardSecuritySettingsUpdated();
}

class CardError extends CardState {
  final String message;

  const CardError(this.message);

  @override
  List<Object?> get props => [message];
}

class CardRequesting extends CardState {
  const CardRequesting();
}

class CardUpdating extends CardState {
  const CardUpdating();
}

class CardBlocking extends CardState {
  const CardBlocking();
}

class CardUnblocking extends CardState {
  const CardUnblocking();
}

class CardCancelling extends CardState {
  const CardCancelling();
}

class CardActivating extends CardState {
  const CardActivating();
}

class CardUpdatingLimits extends CardState {
  const CardUpdatingLimits();
}

class CardUpdatingSecuritySettings extends CardState {
  const CardUpdatingSecuritySettings();
}