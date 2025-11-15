import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:flutter/foundation.dart';

import '../../../domain/entities/card.dart';
import '../../../domain/repositories/card_repository.dart';
import '../../../domain/usecases/card/request_card_usecase.dart';
import '../../../domain/usecases/card/get_user_cards_usecase.dart';
import '../../../domain/usecases/card/get_cards_by_account_usecase.dart';
// TODO: Implementar notificaciones más adelante
// import '../../../services/notification_service.dart';
// import '../../../domain/entities/notification.dart';
import 'card_event.dart';
import 'card_state.dart';

class CardBloc extends Bloc<CardEvent, CardState> {
  final CardRepository _cardRepository;
  final RequestCardUseCase _requestCardUseCase;
  final GetUserCardsUseCase _getUserCardsUseCase;
  final GetCardsByAccountUseCase _getCardsByAccountUseCase;



  CardBloc({
    required CardRepository cardRepository,
    required RequestCardUseCase requestCardUseCase,
    required GetUserCardsUseCase getUserCardsUseCase,
    required GetCardsByAccountUseCase getCardsByAccountUseCase,
  }) : _cardRepository = cardRepository,
       _requestCardUseCase = requestCardUseCase,
       _getUserCardsUseCase = getUserCardsUseCase,
       _getCardsByAccountUseCase = getCardsByAccountUseCase,
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
      
      await emit.forEach<List<Card>>(
        _getUserCardsUseCase(
          GetUserCardsParams(
            userId: event.userId,
            microfinancieraId: event.microfinancieraId,
          ),
        ),
        onData: (cards) {
          print('✅ CardBloc: Received ${cards.length} cards');
          print('✅ CardBloc: Emitting CardLoaded state');
          return CardLoaded(cards);
        },
        onError: (error, stackTrace) {
          print('❌ CardBloc: Error loading cards: $error');
          print('❌ CardBloc: Emitting CardError state');
          return CardError(error.toString());
        },
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
      
      await emit.forEach<List<Card>>(
        _getCardsByAccountUseCase(
          GetCardsByAccountParams(
            accountId: event.accountId,
            microfinancieraId: event.microfinancieraId,
          ),
        ),
        onData: (cards) {
          print('✅ CardBloc: Received ${cards.length} cards for account');
          print('✅ CardBloc: Emitting CardLoaded state for account');
          return CardLoaded(cards);
        },
        onError: (error, stackTrace) {
          print('❌ CardBloc: Error loading cards by account: $error');
          print('❌ CardBloc: Emitting CardError state for account');
          return CardError(error.toString());
        },
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
      
      final cardId = await _requestCardUseCase(event.params);
      emit(CardRequested(cardId));
      
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
      
      await _cardRepository.updateCard(event.card, event.microfinancieraId);
      emit(const CardUpdated());
      
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
      
      await _cardRepository.blockCard(event.cardId, event.microfinancieraId);
      emit(const CardBlocked());
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
      
      await _cardRepository.unblockCard(event.cardId, event.microfinancieraId);
      emit(const CardUnblocked());
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
      
      await _cardRepository.cancelCard(event.cardId, event.microfinancieraId);
      emit(const CardCancelled());
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
      
      await _cardRepository.activateCard(event.cardId, event.microfinancieraId);
      emit(const CardActivated());
      
      // Obtener información de la tarjeta para la notificación
      final card = await _cardRepository.getCardById(event.cardId, event.microfinancieraId);
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
      
      final card = await _cardRepository.getCardById(event.cardId, event.microfinancieraId);
      if (card != null) {
        emit(CardSingleLoaded(card));
      } else {
        emit(const CardError('Tarjeta no encontrada'));
      }
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
      
      await emit.forEach<List<Card>>(
        _cardRepository.getCardsByStatus(event.userId, event.status, event.microfinancieraId),
        onData: (cards) => CardLoaded(cards),
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
      
      await _cardRepository.updateCardLimits(
        event.cardId,
        event.microfinancieraId,
        dailyLimit: event.dailyLimit,
        monthlyLimit: event.monthlyLimit,
        atmLimit: event.atmLimit,
        onlineLimit: event.onlineLimit,
      );
      emit(const CardLimitsUpdated());
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
      
      await _cardRepository.updateCardSecuritySettings(
        event.cardId,
        event.microfinancieraId,
        isContactlessEnabled: event.isContactlessEnabled,
        isOnlineEnabled: event.isOnlineEnabled,
        isAtmEnabled: event.isAtmEnabled,
        isInternationalEnabled: event.isInternationalEnabled,
      );
      emit(const CardSecuritySettingsUpdated());
    } catch (e) {
      emit(CardError(e.toString()));
    }
  }

  @override
  Future<void> close() {
    return super.close();
  }
}