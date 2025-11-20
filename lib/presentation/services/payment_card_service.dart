import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mobile/domain/entities/card.dart' as domain;
import 'package:mobile/presentation/models/payment_card.dart';

class PaymentCardService extends ChangeNotifier {
  static const String _cardsKey = 'payment_cards';
  static const String _defaultCardKey = 'default_payment_card';
  List<PaymentCard> _cards = [];
  List<domain.Card> _realCards = [];
  String? _defaultCardId;

  List<PaymentCard> get cards => List.unmodifiable(_cards);
  
  PaymentCard? get defaultCard {
    if (_defaultCardId != null) {
      try {
        return _cards.firstWhere((card) => card.id == _defaultCardId);
      } catch (e) {
        // If default card not found, return first card
        return _cards.isNotEmpty ? _cards.first : null;
      }
    }
    return _cards.isNotEmpty ? _cards.first : null;
  }

  bool get hasCards => _cards.isNotEmpty;

  PaymentCardService() {
    _loadCards();
  }

  // Method to update cards from CardBloc
  void updateFromRealCards(List<domain.Card> realCards) {
    _realCards = realCards;
    _convertRealCardsToPaymentCards();
    notifyListeners();
  }

  void _convertRealCardsToPaymentCards() {
    _cards = _realCards
        .where((card) => card.status == domain.CardStatus.active)
        .map((card) => PaymentCard(
              id: card.id,
              cardNumber: card.cardNumber,
              cardHolderName: card.holderName,
              expiryDate: _formatExpiryDate(card.expiryDate),
              cardType: _mapCardBrandToType(card.cardBrand),
              isDefault: card.id == _defaultCardId,
            ))
        .toList();

    // If no default card is set and we have cards, set the first one as default
    if (_defaultCardId == null && _cards.isNotEmpty) {
      _defaultCardId = _cards.first.id;
      _saveDefaultCard();
    }
  }

  String _formatExpiryDate(DateTime expiryDate) {
    return '${expiryDate.month.toString().padLeft(2, '0')}/${expiryDate.year.toString().substring(2)}';
  }

  String _mapCardBrandToType(domain.CardBrand brand) {
    switch (brand) {
      case domain.CardBrand.visa:
        return 'visa';
      case domain.CardBrand.mastercard:
        return 'mastercard';
      case domain.CardBrand.amex:
        return 'amex';
      default:
        return 'visa';
    }
  }

  Future<void> _loadCards() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _defaultCardId = prefs.getString(_defaultCardKey);
      
      // If we have real cards, use them; otherwise, load from preferences or add demo cards
      if (_realCards.isNotEmpty) {
        _convertRealCardsToPaymentCards();
      } else {
        final cardsJson = prefs.getString(_cardsKey);
        
        if (cardsJson != null) {
          final List<dynamic> cardsList = json.decode(cardsJson);
          _cards = cardsList.map((json) => PaymentCard.fromJson(json)).toList();
          
          // Add some default cards for demo purposes if no cards exist
          if (_cards.isEmpty) {
            _addDemoCards();
          }
        } else {
          // Add demo cards for first time
          _addDemoCards();
        }
      }
      
      notifyListeners();
    } catch (e) {
      print('Error loading payment cards: $e');
      _addDemoCards();
    }
  }

  void _addDemoCards() {
    _cards = [
      PaymentCard(
        id: '1',
        cardNumber: '4532123456781234',
        cardHolderName: 'Juan Pérez',
        expiryDate: '12/25',
        cardType: 'visa',
        isDefault: true,
      ),
      PaymentCard(
        id: '2',
        cardNumber: '5555123456789012',
        cardHolderName: 'Juan Pérez',
        expiryDate: '08/26',
        cardType: 'mastercard',
        isDefault: false,
      ),
    ];
    _saveCards();
  }

  Future<void> _saveCards() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cardsJson = json.encode(_cards.map((card) => card.toJson()).toList());
      await prefs.setString(_cardsKey, cardsJson);
    } catch (e) {
      print('Error saving payment cards: $e');
    }
  }

  Future<void> addCard(PaymentCard card) async {
    // If this is the first card or marked as default, make it default
    if (_cards.isEmpty || card.isDefault) {
      // Remove default from other cards
      _cards = _cards.map((c) => c.copyWith(isDefault: false)).toList();
    }
    
    _cards.add(card);
    await _saveCards();
    notifyListeners();
  }

  Future<void> removeCard(String cardId) async {
    final cardIndex = _cards.indexWhere((card) => card.id == cardId);
    if (cardIndex != -1) {
      final removedCard = _cards[cardIndex];
      _cards.removeAt(cardIndex);
      
      // If removed card was default and there are other cards, make first one default
      if (removedCard.isDefault && _cards.isNotEmpty) {
        _cards[0] = _cards[0].copyWith(isDefault: true);
      }
      
      await _saveCards();
      notifyListeners();
    }
  }

  Future<void> _saveDefaultCard() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (_defaultCardId != null) {
        await prefs.setString(_defaultCardKey, _defaultCardId!);
      } else {
        await prefs.remove(_defaultCardKey);
      }
    } catch (e) {
      print('Error saving default card: $e');
    }
  }

  Future<void> setDefaultCard(String cardId) async {
    _defaultCardId = cardId;
    
    // Update the isDefault property in the cards list
    _cards = _cards.map((card) => 
      card.copyWith(isDefault: card.id == cardId)
    ).toList();
    
    await _saveDefaultCard();
    await _saveCards();
    notifyListeners();
  }

  PaymentCard? getCardById(String cardId) {
    try {
      return _cards.firstWhere((card) => card.id == cardId);
    } catch (e) {
      return null;
    }
  }
}
