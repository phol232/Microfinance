import '../entities/card.dart';

/// Repositorio abstracto para la gestión de tarjetas
abstract class CardRepository {
  /// Obtiene todas las tarjetas del usuario
  Stream<List<Card>> getUserCards(String userId, String microfinancieraId);
  
  /// Obtiene las tarjetas de una cuenta específica
  Stream<List<Card>> getCardsByAccount(String accountId, String microfinancieraId);
  
  /// Obtiene una tarjeta específica por ID
  Future<Card?> getCardById(String cardId, String microfinancieraId);
  
  /// Solicita una nueva tarjeta
  Future<String> requestCard(Card card, String microfinancieraId);
  
  /// Actualiza una tarjeta existente
  Future<void> updateCard(Card card, String microfinancieraId);
  
  /// Bloquea una tarjeta
  Future<void> blockCard(String cardId, String microfinancieraId);
  
  /// Desbloquea una tarjeta
  Future<void> unblockCard(String cardId, String microfinancieraId);
  
  /// Cancela una tarjeta
  Future<void> cancelCard(String cardId, String microfinancieraId);
  
  /// Activa una tarjeta
  Future<void> activateCard(String cardId, String microfinancieraId);
  
  /// Obtiene tarjetas por estado
  Stream<List<Card>> getCardsByStatus(String userId, CardStatus status, String microfinancieraId);
  
  Future<bool> canRequestCard(String accountId, String microfinancieraId);
  
  Future<bool> canRequestCardByType(String accountId, String microfinancieraId, CardType cardType, CardBrand cardBrand);
  
  /// Obtiene el número de tarjetas activas del usuario
  Future<int> getUserActiveCardCount(String userId, String microfinancieraId);
  
  /// Actualiza los límites de una tarjeta
  Future<void> updateCardLimits(String cardId, String microfinancieraId, {
    double? dailyLimit,
    double? monthlyLimit,
    double? atmLimit,
    double? onlineLimit,
  });
  
  /// Actualiza las configuraciones de seguridad de una tarjeta
  Future<void> updateCardSecuritySettings(String cardId, String microfinancieraId, {
    bool? isContactlessEnabled,
    bool? isOnlineEnabled,
    bool? isAtmEnabled,
    bool? isInternationalEnabled,
  });
}