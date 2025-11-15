import 'dart:async';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../../domain/entities/card.dart';

class CardDataSource {
  CardDataSource({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  String _getCardsCollection(String microfinancieraId) {
    return 'microfinancieras/$microfinancieraId/cards';
  }

  Stream<List<Card>> getUserCards(String userId, String microfinancieraId) {
    try {
      return _firestore
          .collection(_getCardsCollection(microfinancieraId))
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .snapshots()
          .map(
            (snapshot) =>
                snapshot.docs.map((doc) => Card.fromFirestore(doc)).toList(),
          );
    } catch (error, stackTrace) {
      _logError('getUserCards', error, stackTrace);
      return Stream.value([]);
    }
  }

  Stream<List<Card>> getCardsByAccount(String accountId, String microfinancieraId) {
    try {
      return _firestore
          .collection(_getCardsCollection(microfinancieraId))
          .where('accountId', isEqualTo: accountId)
          .orderBy('createdAt', descending: true)
          .snapshots()
          .map(
            (snapshot) =>
                snapshot.docs.map((doc) => Card.fromFirestore(doc)).toList(),
          );
    } catch (error, stackTrace) {
      _logError('getCardsByAccount', error, stackTrace);
      return Stream.value([]);
    }
  }

  Future<Card?> getCardById(String cardId, String microfinancieraId) async {
    try {
      final doc = await _firestore.collection(_getCardsCollection(microfinancieraId)).doc(cardId).get();
      if (doc.exists && doc.data() != null) {
        return Card.fromFirestore(doc);
      }
      return null;
    } catch (error, stackTrace) {
      _logError('getCardById', error, stackTrace);
      return null;
    }
  }

  Future<String> requestCard(Card card, String microfinancieraId) async {
    try {
      final cardNumber = await _generateCardNumber(microfinancieraId);

      final cardData = card
          .copyWith(cardNumber: cardNumber, createdAt: DateTime.now())
          .toFirestore();

      final docRef = await _firestore.collection(_getCardsCollection(microfinancieraId)).add(cardData);
      return docRef.id;
    } catch (error, stackTrace) {
      _logError('requestCard', error, stackTrace);
      rethrow;
    }
  }

  Future<void> updateCard(Card card, String microfinancieraId) async {
    try {
      await _firestore
          .collection(_getCardsCollection(microfinancieraId))
          .doc(card.id)
          .update(card.toFirestore());
    } catch (error, stackTrace) {
      _logError('updateCard', error, stackTrace);
      rethrow;
    }
  }

  Future<void> blockCard(String cardId, String microfinancieraId) async {
    try {
      await _firestore.collection(_getCardsCollection(microfinancieraId)).doc(cardId).update({
        'status': CardStatus.blocked.name,
        'blockedAt': Timestamp.fromDate(DateTime.now()),
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });
    } catch (error, stackTrace) {
      _logError('blockCard', error, stackTrace);
      rethrow;
    }
  }

  Future<void> unblockCard(String cardId, String microfinancieraId) async {
    try {
      await _firestore.collection(_getCardsCollection(microfinancieraId)).doc(cardId).update({
        'status': CardStatus.active.name,
        'blockedAt': null,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });
    } catch (error, stackTrace) {
      _logError('unblockCard', error, stackTrace);
      rethrow;
    }
  }

  Future<void> cancelCard(String cardId, String microfinancieraId) async {
    try {
      await _firestore.collection(_getCardsCollection(microfinancieraId)).doc(cardId).update({
        'status': CardStatus.cancelled.name,
        'cancelledAt': Timestamp.fromDate(DateTime.now()),
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });
    } catch (error, stackTrace) {
      _logError('cancelCard', error, stackTrace);
      rethrow;
    }
  }

  Future<void> activateCard(String cardId, String microfinancieraId) async {
    try {
      await _firestore.collection(_getCardsCollection(microfinancieraId)).doc(cardId).update({
        'status': CardStatus.active.name,
        'activatedAt': Timestamp.fromDate(DateTime.now()),
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });
    } catch (error, stackTrace) {
      _logError('activateCard', error, stackTrace);
      rethrow;
    }
  }

  Stream<List<Card>> getCardsByStatus(String userId, CardStatus status, String microfinancieraId) {
    try {
      return _firestore
          .collection(_getCardsCollection(microfinancieraId))
          .where('userId', isEqualTo: userId)
          .where('status', isEqualTo: status.name)
          .orderBy('createdAt', descending: true)
          .snapshots()
          .map(
            (snapshot) =>
                snapshot.docs.map((doc) => Card.fromFirestore(doc)).toList(),
          );
    } catch (error, stackTrace) {
      _logError('getCardsByStatus', error, stackTrace);
      return Stream.value([]);
    }
  }

  Future<bool> canRequestCard(String accountId, String microfinancieraId) async {
    try {
      final snapshot = await _firestore
          .collection(_getCardsCollection(microfinancieraId))
          .where('accountId', isEqualTo: accountId)
          .where(
            'status',
            whereIn: [
              CardStatus.requested.name,
              CardStatus.approved.name,
              CardStatus.inProduction.name,
              CardStatus.delivered.name,
              CardStatus.active.name,
            ],
          )
          .get();

      return snapshot.docs.isEmpty;
    } catch (error, stackTrace) {
      _logError('canRequestCard', error, stackTrace);
      return false;
    }
  }

  Future<bool> canRequestCardByType(String accountId, String microfinancieraId, CardType cardType, CardBrand cardBrand) async {
    try {
      // Reglas de negocio de la microfinanciera:
      // - Máximo 2 tarjetas de débito por cuenta (1 Visa + 1 Mastercard)
      // - Tarjetas de crédito ilimitadas
      
      if (cardType == CardType.debit) {
        // Para débito, verificar que no tenga ya una tarjeta de la misma marca
        final existingDebitSnapshot = await _firestore
            .collection(_getCardsCollection(microfinancieraId))
            .where('accountId', isEqualTo: accountId)
            .where('cardType', isEqualTo: CardType.debit.name)
            .where('cardBrand', isEqualTo: cardBrand.name)
            .where(
              'status',
              whereIn: [
                CardStatus.requested.name,
                CardStatus.approved.name,
                CardStatus.inProduction.name,
                CardStatus.delivered.name,
                CardStatus.active.name,
              ],
            )
            .get();

        // Si ya tiene una tarjeta de débito de esta marca, no puede solicitar otra
        if (existingDebitSnapshot.docs.isNotEmpty) {
          return false;
        }

        // Verificar que no tenga más de 2 tarjetas de débito en total
        final allDebitSnapshot = await _firestore
            .collection(_getCardsCollection(microfinancieraId))
            .where('accountId', isEqualTo: accountId)
            .where('cardType', isEqualTo: CardType.debit.name)
            .where(
              'status',
              whereIn: [
                CardStatus.requested.name,
                CardStatus.approved.name,
                CardStatus.inProduction.name,
                CardStatus.delivered.name,
                CardStatus.active.name,
              ],
            )
            .get();

        return allDebitSnapshot.docs.length < 2;
      } else if (cardType == CardType.credit) {
        // Para crédito, no hay límites
        return true;
      }

      return false;
    } catch (error, stackTrace) {
      _logError('canRequestCardByType', error, stackTrace);
      return false;
    }
  }

  Future<int> getUserActiveCardCount(String userId, String microfinancieraId) async {
    try {
      final snapshot = await _firestore
          .collection(_getCardsCollection(microfinancieraId))
          .where('userId', isEqualTo: userId)
          .where('status', isEqualTo: CardStatus.active.name)
          .get();
      return snapshot.docs.length;
    } catch (error, stackTrace) {
      _logError('getUserActiveCardCount', error, stackTrace);
      return 0;
    }
  }

  Future<void> updateCardLimits(
    String cardId,
    String microfinancieraId, {
    double? dailyLimit,
    double? monthlyLimit,
    double? atmLimit,
    double? onlineLimit,
  }) async {
    try {
      final updates = <String, dynamic>{
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      };

      if (dailyLimit != null) updates['dailyLimit'] = dailyLimit;
      if (monthlyLimit != null) updates['monthlyLimit'] = monthlyLimit;
      if (atmLimit != null) updates['atmLimit'] = atmLimit;
      if (onlineLimit != null) updates['onlineLimit'] = onlineLimit;

      await _firestore.collection(_getCardsCollection(microfinancieraId)).doc(cardId).update(updates);
    } catch (error, stackTrace) {
      _logError('updateCardLimits', error, stackTrace);
      rethrow;
    }
  }

  Future<void> updateCardSecuritySettings(
    String cardId,
    String microfinancieraId, {
    bool? isContactlessEnabled,
    bool? isOnlineEnabled,
    bool? isAtmEnabled,
    bool? isInternationalEnabled,
  }) async {
    try {
      final updates = <String, dynamic>{
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      };

      if (isContactlessEnabled != null)
        updates['isContactlessEnabled'] = isContactlessEnabled;
      if (isOnlineEnabled != null) updates['isOnlineEnabled'] = isOnlineEnabled;
      if (isAtmEnabled != null) updates['isAtmEnabled'] = isAtmEnabled;
      if (isInternationalEnabled != null)
        updates['isInternationalEnabled'] = isInternationalEnabled;

      await _firestore.collection(_getCardsCollection(microfinancieraId)).doc(cardId).update(updates);
    } catch (error, stackTrace) {
      _logError('updateCardSecuritySettings', error, stackTrace);
      rethrow;
    }
  }

  Future<String> _generateCardNumber(String microfinancieraId) async {
    String cardNumber = '';
    bool exists = true;
    int attempts = 0;
    const maxAttempts = 10;

    while (exists && attempts < maxAttempts) {

      final random = Random();
      final part1 = '4${random.nextInt(999).toString().padLeft(3, '0')}'; 
      final part2 = random.nextInt(10000).toString().padLeft(4, '0');     
      final part3 = random.nextInt(10000).toString().padLeft(4, '0');     
      final part4 = random.nextInt(10000).toString().padLeft(4, '0');     
      
      cardNumber = '$part1$part2$part3$part4';

      // Verificar que el número no exista en la base de datos
      final snapshot = await _firestore
          .collection(_getCardsCollection(microfinancieraId))
          .where('cardNumber', isEqualTo: cardNumber)
          .get();

      exists = snapshot.docs.isNotEmpty;
      attempts++;
    }

    if (attempts >= maxAttempts) {
      throw Exception('No se pudo generar un número de tarjeta único después de $maxAttempts intentos');
    }

    return cardNumber;
  }

  void _logError(String method, dynamic error, StackTrace stackTrace) {
    print('Error in CardDataSource.$method: $error');
    print('StackTrace: $stackTrace');
  }
}
