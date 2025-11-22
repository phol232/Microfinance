import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:flutter/foundation.dart';
import 'package:fpdart/fpdart.dart';

import '../../../domain/entities/card.dart';
import '../../../domain/usecases/card/change_card_status_usecase.dart';
import '../../../domain/usecases/card/get_card_by_id_usecase.dart';
import '../../../domain/usecases/card/get_cards_by_account_usecase.dart';
import '../../../domain/usecases/card/get_cards_by_status_usecase.dart';
import '../../../domain/usecases/card/get_user_cards_usecase.dart';
import '../../../domain/usecases/card/request_card_usecase.dart';
import '../../../domain/usecases/card/update_card_limits_usecase.dart';
import '../../../domain/usecases/card/update_card_security_settings_usecase.dart';
import '../../../domain/usecases/card/update_card_usecase.dart';
import '../../../domain/core/error/failures.dart';
// TODO: Implementar notificaciones más adelante
// import '../../../services/notification_service.dart';
// import '../../../domain/entities/notification.dart';
import 'card_event.dart';
import 'card_state.dart';

class CardBloc extends Bloc<CardEvent, CardState> {
  final RequestCardUseCase _requestCardUseCase;
  final GetUserCardsUseCase _getUserCardsUseCase;
  final GetCardsByAccountUseCase _getCardsByAccountUseCase;
  final GetCardsByStatusUseCase _getCardsByStatusUseCase;
  final UpdateCardUseCase _updateCardUseCase;
  final BlockCardUseCase _blockCardUseCase;
  final UnblockCardUseCase _unblockCardUseCase;
  final CancelCardUseCase _cancelCardUseCase;
  final ActivateCardUseCase _activateCardUseCase;
  final GetCardByIdUseCase _getCardByIdUseCase;
  final UpdateCardLimitsUseCase _updateCardLimitsUseCase;
  final UpdateCardSecuritySettingsUseCase _updateCardSecuritySettingsUseCase;

  CardBloc({
    required RequestCardUseCase requestCardUseCase,
    required GetUserCardsUseCase getUserCardsUseCase,
    required GetCardsByAccountUseCase getCardsByAccountUseCase,
    required GetCardsByStatusUseCase getCardsByStatusUseCase,
    required UpdateCardUseCase updateCardUseCase,
    required BlockCardUseCase blockCardUseCase,
    required UnblockCardUseCase unblockCardUseCase,
    required CancelCardUseCase cancelCardUseCase,
    required ActivateCardUseCase activateCardUseCase,
    required GetCardByIdUseCase getCardByIdUseCase,
    required UpdateCardLimitsUseCase updateCardLimitsUseCase,
    required UpdateCardSecuritySettingsUseCase updateCardSecuritySettingsUseCase,
  })  : _requestCardUseCase = requestCardUseCase,
        _getUserCardsUseCase = getUserCardsUseCase,
        _getCardsByAccountUseCase = getCardsByAccountUseCase,
        _getCardsByStatusUseCase = getCardsByStatusUseCase,
        _updateCardUseCase = updateCardUseCase,
        _blockCardUseCase = blockCardUseCase,
        _unblockCardUseCase = unblockCardUseCase,
        _cancelCardUseCase = cancelCardUseCase,
        _activateCardUseCase = activateCardUseCase,
        _getCardByIdUseCase = getCardByIdUseCase,
        _updateCardLimitsUseCase = updateCardLimitsUseCase,
        _updateCardSecuritySettingsUseCase = updateCardSecuritySettingsUseCase,
        super(const CardInitial()) {
    on<CardLoadUserCards>(_onCardLoadUserCards);
    on<CardLoadByAccount>(_onCardLoadByAccount);
    on<CardRequest>(_onCardRequest);
    on<CardUpdate>(_onCardUpdate);
    on<CardBlock>(_onCardBlock);
    on<CardUnblock>(_onCardUnblock);
    on<CardCancel>(_onCardCancel);
    on<CardActivate>(_onCardActivate);
    on<CardLoadById>(_onCardLoadById);
    on<CardLoadByStatus>(_onCardLoadByStatus);
    on<CardUpdateLimits>(_onCardUpdateLimits);
    on<CardUpdateSecuritySettings>(_onCardUpdateSecuritySettings);
  }

  Future<void> _onCardLoadUserCards(
    CardLoadUserCards event,
    Emitter<CardState> emit,
  ) async {
    try {
      print('🔄 CardBloc: Loading user cards for userId: ${event.userId}, microfinancieraId: ${event.microfinancieraId}');
      emit(const CardLoading());
      
      print('🔄 CardBloc: Starting new subscription');
      
      await emit.forEach<Either<Failure, List<Card>>>(
        _getUserCardsUseCase(
          GetUserCardsParams(
            userId: event.userId,
            microfinancieraId: event.microfinancieraId,
          ),
        ),
        onData: (result) => result.match(
          (failure) {
            print('❌ CardBloc: Error loading cards: ${failure.message}');
            print('❌ CardBloc: Emitting CardError state');
            return CardError(failure.message);
          },
          (cards) {
            print('✅ CardBloc: Received ${cards.length} cards');
            print('✅ CardBloc: Emitting CardLoaded state');
            return CardLoaded(cards);
          },
        ),
        onError: (error, stackTrace) => CardError(error.toString()),
      );
    } catch (e) {
      print('❌ CardBloc: Exception in _onCardLoadUserCards: $e');
      emit(CardError(e.toString()));
    }
  }

  Future<void> _onCardLoadByAccount(
    CardLoadByAccount event,
    Emitter<CardState> emit,
  ) async {
    try {
      print('🔄 CardBloc: Loading cards by account for accountId: ${event.accountId}, microfinancieraId: ${event.microfinancieraId}');
      emit(const CardLoading());
      
      print('🔄 CardBloc: Starting new subscription for account');
      
      await emit.forEach<Either<Failure, List<Card>>>(
        _getCardsByAccountUseCase(
          GetCardsByAccountParams(
            accountId: event.accountId,
            microfinancieraId: event.microfinancieraId,
          ),
        ),
        onData: (result) => result.match(
          (failure) {
            print('❌ CardBloc: Error loading cards by account: ${failure.message}');
            print('❌ CardBloc: Emitting CardError state for account');
            return CardError(failure.message);
          },
          (cards) {
            print('✅ CardBloc: Received ${cards.length} cards for account');
            print('✅ CardBloc: Emitting CardLoaded state for account');
            return CardLoaded(cards);
          },
        ),
        onError: (error, stackTrace) => CardError(error.toString()),
      );
    } catch (e) {
      print('❌ CardBloc: Exception in _onCardLoadByAccount: $e');
      emit(CardError(e.toString()));
    }
  }

  Future<void> _onCardRequest(
    CardRequest event,
    Emitter<CardState> emit,
  ) async {
    try {
      emit(const CardRequesting());
      
      final result = await _requestCardUseCase(event.params);
      result.match(
        (failure) => emit(CardError(failure.message)),
        (cardId) => emit(CardRequested(cardId)),
      );
      
      // TODO: Implementar notificaciones más adelante
      // Enviar notificación de solicitud de tarjeta
      // await NotificationService.sendNotification(
      //   userId: event.params.userId,
      //   title: 'Solicitud de Tarjeta Recibida',
      //   message: 'Tu solicitud de tarjeta ha sido recibida y está siendo procesada',
      //   type: NotificationType.general,
      //   data: {
      //     'cardId': cardId,
      //     'cardType': event.params.cardType.name,
      //     'accountId': event.params.accountId,
      //   },
      // );
      
      // Recargar las tarjetas del usuario
      add(CardLoadUserCards(event.params.userId, event.params.microfinancieraId));
    } catch (e) {
      emit(CardError(e.toString()));
    }
  }

  Future<void> _onCardUpdate(
    CardUpdate event,
    Emitter<CardState> emit,
  ) async {
    try {
      emit(const CardUpdating());
      
      final result = await _updateCardUseCase(
        UpdateCardParams(card: event.card, microfinancieraId: event.microfinancieraId),
      );
      result.match(
        (failure) => emit(CardError(failure.message)),
        (_) => emit(const CardUpdated()),
      );
      
      // Recargar las tarjetas del usuario
      add(CardLoadUserCards(event.card.userId, event.microfinancieraId));
    } catch (e) {
      emit(CardError(e.toString()));
    }
  }

  Future<void> _onCardBlock(
    CardBlock event,
    Emitter<CardState> emit,
  ) async {
    try {
      emit(const CardBlocking());
      
      final result = await _blockCardUseCase(
        CardStatusParams(
          cardId: event.cardId,
          microfinancieraId: event.microfinancieraId,
        ),
      );
      result.match(
        (failure) => emit(CardError(failure.message)),
        (_) => emit(const CardBlocked()),
      );
    } catch (e) {
      emit(CardError(e.toString()));
    }
  }

  Future<void> _onCardUnblock(
    CardUnblock event,
    Emitter<CardState> emit,
  ) async {
    try {
      emit(const CardUnblocking());
      
      final result = await _unblockCardUseCase(
        CardStatusParams(
          cardId: event.cardId,
          microfinancieraId: event.microfinancieraId,
        ),
      );
      result.match(
        (failure) => emit(CardError(failure.message)),
        (_) => emit(const CardUnblocked()),
      );
    } catch (e) {
      emit(CardError(e.toString()));
    }
  }

  Future<void> _onCardCancel(
    CardCancel event,
    Emitter<CardState> emit,
  ) async {
    try {
      emit(const CardCancelling());
      
      final result = await _cancelCardUseCase(
        CardStatusParams(
          cardId: event.cardId,
          microfinancieraId: event.microfinancieraId,
        ),
      );
      result.match(
        (failure) => emit(CardError(failure.message)),
        (_) => emit(const CardCancelled()),
      );
    } catch (e) {
      emit(CardError(e.toString()));
    }
  }

  Future<void> _onCardActivate(
    CardActivate event,
    Emitter<CardState> emit,
  ) async {
    try {
      emit(const CardActivating());
      
      final result = await _activateCardUseCase(
        CardStatusParams(
          cardId: event.cardId,
          microfinancieraId: event.microfinancieraId,
        ),
      );
      result.match(
        (failure) => emit(CardError(failure.message)),
        (_) => emit(const CardActivated()),
      );
      
      // Obtener información de la tarjeta para la notificación
      final cardResult = await _getCardByIdUseCase(
        GetCardByIdParams(
          cardId: event.cardId,
          microfinancieraId: event.microfinancieraId,
        ),
      );
      cardResult.map((card) {
        if (card != null) {
        // TODO: Implementar notificaciones más adelante
        // Enviar notificación de tarjeta activada
        // await NotificationService.sendNotification(
        //   userId: card.userId,
        //   title: '¡Tarjeta Activada!',
        //   message: 'Tu tarjeta ha sido activada exitosamente y está lista para usar',
        //   type: NotificationType.cardActivated,
        //   data: {
        //     'cardId': event.cardId,
        //     'cardType': card.cardType.name,
        //     'lastFourDigits': card.cardNumber.substring(card.cardNumber.length - 4),
        //   },
        // );
        }
        return null;
      });
    } catch (e) {
      emit(CardError(e.toString()));
    }
  }

  Future<void> _onCardLoadById(
    CardLoadById event,
    Emitter<CardState> emit,
  ) async {
    try {
      emit(const CardLoading());
      
      final result = await _getCardByIdUseCase(
        GetCardByIdParams(
          cardId: event.cardId,
          microfinancieraId: event.microfinancieraId,
        ),
      );
      result.match(
        (failure) => emit(CardError(failure.message)),
        (card) {
          if (card != null) {
            emit(CardSingleLoaded(card));
          } else {
            emit(const CardError('Tarjeta no encontrada'));
          }
        },
      );
    } catch (e) {
      emit(CardError(e.toString()));
    }
  }

  Future<void> _onCardLoadByStatus(
    CardLoadByStatus event,
    Emitter<CardState> emit,
  ) async {
    try {
      emit(const CardLoading());
      
      await emit.forEach<Either<Failure, List<Card>>>(
        _getCardsByStatusUseCase(
          GetCardsByStatusParams(
            userId: event.userId,
            status: event.status,
            microfinancieraId: event.microfinancieraId,
          ),
        ),
        onData: (result) => result.match(
          (failure) => CardError(failure.message),
          (cards) => CardLoaded(cards),
        ),
        onError: (error, stackTrace) => CardError(error.toString()),
      );
    } catch (e) {
      emit(CardError(e.toString()));
    }
  }

  Future<void> _onCardUpdateLimits(
    CardUpdateLimits event,
    Emitter<CardState> emit,
  ) async {
    try {
      emit(const CardUpdatingLimits());
      
      final result = await _updateCardLimitsUseCase(
        UpdateCardLimitsParams(
          cardId: event.cardId,
          microfinancieraId: event.microfinancieraId,
          dailyLimit: event.dailyLimit,
          monthlyLimit: event.monthlyLimit,
          atmLimit: event.atmLimit,
          onlineLimit: event.onlineLimit,
        ),
      );
      result.match(
        (failure) => emit(CardError(failure.message)),
        (_) => emit(const CardLimitsUpdated()),
      );
    } catch (e) {
      emit(CardError(e.toString()));
    }
  }

  Future<void> _onCardUpdateSecuritySettings(
    CardUpdateSecuritySettings event,
    Emitter<CardState> emit,
  ) async {
    try {
      emit(const CardUpdatingSecuritySettings());
      
      final result = await _updateCardSecuritySettingsUseCase(
        UpdateCardSecuritySettingsParams(
          cardId: event.cardId,
          microfinancieraId: event.microfinancieraId,
          isContactlessEnabled: event.isContactlessEnabled,
          isOnlineEnabled: event.isOnlineEnabled,
          isAtmEnabled: event.isAtmEnabled,
          isInternationalEnabled: event.isInternationalEnabled,
        ),
      );
      result.match(
        (failure) => emit(CardError(failure.message)),
        (_) => emit(const CardSecuritySettingsUpdated()),
      );
    } catch (e) {
      emit(CardError(e.toString()));
    }
  }

  @override
  Future<void> close() {
    return super.close();
  }
}
