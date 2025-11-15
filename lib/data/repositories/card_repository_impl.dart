import 'dart:async';

import '../../domain/entities/card.dart';
import '../../domain/repositories/card_repository.dart';
import '../datasources/card_datasource.dart';

class CardRepositoryImpl implements CardRepository {
  CardRepositoryImpl({
    required CardDataSource cardDataSource,
  }) : _cardDataSource = cardDataSource;

  final CardDataSource _cardDataSource;

  @override
  Stream<List<Card>> getUserCards(String userId, String microfinancieraId) {
    return _cardDataSource.getUserCards(userId, microfinancieraId);
  }

  @override
  Stream<List<Card>> getCardsByAccount(String accountId, String microfinancieraId) {
    return _cardDataSource.getCardsByAccount(accountId, microfinancieraId);
  }

  @override
  Future<Card?> getCardById(String cardId, String microfinancieraId) {
    return _cardDataSource.getCardById(cardId, microfinancieraId);
  }

  @override
  Future<String> requestCard(Card card, String microfinancieraId) {
    return _cardDataSource.requestCard(card, microfinancieraId);
  }

  @override
  Future<void> updateCard(Card card, String microfinancieraId) {
    return _cardDataSource.updateCard(card, microfinancieraId);
  }

  @override
  Future<void> blockCard(String cardId, String microfinancieraId) {
    return _cardDataSource.blockCard(cardId, microfinancieraId);
  }

  @override
  Future<void> unblockCard(String cardId, String microfinancieraId) {
    return _cardDataSource.unblockCard(cardId, microfinancieraId);
  }

  @override
  Future<void> cancelCard(String cardId, String microfinancieraId) {
    return _cardDataSource.cancelCard(cardId, microfinancieraId);
  }

  @override
  Future<void> activateCard(String cardId, String microfinancieraId) {
    return _cardDataSource.activateCard(cardId, microfinancieraId);
  }

  @override
  Stream<List<Card>> getCardsByStatus(String userId, CardStatus status, String microfinancieraId) {
    return _cardDataSource.getCardsByStatus(userId, status, microfinancieraId);
  }

  @override
  Future<bool> canRequestCard(String accountId, String microfinancieraId) {
    return _cardDataSource.canRequestCard(accountId, microfinancieraId);
  }

  @override
  Future<bool> canRequestCardByType(String accountId, String microfinancieraId, CardType cardType, CardBrand cardBrand) {
    return _cardDataSource.canRequestCardByType(accountId, microfinancieraId, cardType, cardBrand);
  }

  @override
  Future<int> getUserActiveCardCount(String userId, String microfinancieraId) {
    return _cardDataSource.getUserActiveCardCount(userId, microfinancieraId);
  }

  @override
  Future<void> updateCardLimits(String cardId, String microfinancieraId, {
    double? dailyLimit,
    double? monthlyLimit,
    double? atmLimit,
    double? onlineLimit,
  }) {
    return _cardDataSource.updateCardLimits(
      cardId,
      microfinancieraId,
      dailyLimit: dailyLimit,
      monthlyLimit: monthlyLimit,
      atmLimit: atmLimit,
      onlineLimit: onlineLimit,
    );
  }

  @override
  Future<void> updateCardSecuritySettings(String cardId, String microfinancieraId, {
    bool? isContactlessEnabled,
    bool? isOnlineEnabled,
    bool? isAtmEnabled,
    bool? isInternationalEnabled,
  }) {
    return _cardDataSource.updateCardSecuritySettings(
      cardId,
      microfinancieraId,
      isContactlessEnabled: isContactlessEnabled,
      isOnlineEnabled: isOnlineEnabled,
      isAtmEnabled: isAtmEnabled,
      isInternationalEnabled: isInternationalEnabled,
    );
  }
}