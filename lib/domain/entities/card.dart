import 'package:cloud_firestore/cloud_firestore.dart';

/// Entidad de dominio para representar una tarjeta de débito/crédito
class Card {
  const Card({
    required this.id,
    required this.userId,
    required this.accountId,
    required this.microfinancieraId,
    required this.cardNumber,
    required this.cardType,
    required this.cardBrand,
    required this.holderName,
    required this.expiryDate,
    required this.status,
    required this.createdAt,
    this.updatedAt,
    this.activatedAt,
    this.blockedAt,
    this.cancelledAt,
    // Límites y configuración
    this.dailyLimit,
    this.monthlyLimit,
    this.atmLimit,
    this.onlineLimit,
    // Información de solicitud
    required this.requestReason,
    this.deliveryAddress,
    this.deliveryDistrict,
    this.deliveryProvince,
    this.deliveryDepartment,
    this.deliveryPhone,
    this.additionalComments,
    // Configuraciones de seguridad
    this.isContactlessEnabled,
    this.isOnlineEnabled,
    this.isAtmEnabled,
    this.isInternationalEnabled,
  });

  // Identificadores
  final String id;
  final String userId;
  final String accountId; // Cuenta asociada
  final String microfinancieraId;
  
  // Información de la tarjeta
  final String cardNumber; // Últimos 4 dígitos para mostrar
  final CardType cardType;
  final CardBrand cardBrand;
  final String holderName;
  final DateTime expiryDate;
  final CardStatus status;
  
  // Fechas
  final DateTime createdAt;
  final DateTime? updatedAt;
  final DateTime? activatedAt;
  final DateTime? blockedAt;
  final DateTime? cancelledAt;
  
  // Límites y configuración
  final double? dailyLimit;
  final double? monthlyLimit;
  final double? atmLimit;
  final double? onlineLimit;
  
  // Información de solicitud
  final String requestReason;
  final String? deliveryAddress;
  final String? deliveryDistrict;
  final String? deliveryProvince;
  final String? deliveryDepartment;
  final String? deliveryPhone;
  final String? additionalComments;
  
  // Configuraciones de seguridad
  final bool? isContactlessEnabled;
  final bool? isOnlineEnabled;
  final bool? isAtmEnabled;
  final bool? isInternationalEnabled;

  factory Card.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? <String, dynamic>{};
    return Card(
      id: doc.id,
      userId: data['userId'] ?? '',
      accountId: data['accountId'] ?? '',
      microfinancieraId: data['microfinancieraId'] ?? '',
      cardNumber: data['cardNumber'] ?? '',
      cardType: CardType.values.firstWhere(
        (type) => type.name == data['cardType'],
        orElse: () => CardType.debit,
      ),
      cardBrand: CardBrand.values.firstWhere(
        (brand) => brand.name == data['cardBrand'],
        orElse: () => CardBrand.visa,
      ),
      holderName: data['holderName'] ?? '',
      expiryDate: _parseTimestamp(data['expiryDate']),
      status: CardStatus.values.firstWhere(
        (status) => status.name == data['status'],
        orElse: () => CardStatus.requested,
      ),
      createdAt: _parseTimestamp(data['createdAt']),
      updatedAt: data['updatedAt'] != null ? _parseTimestamp(data['updatedAt']) : null,
      activatedAt: data['activatedAt'] != null ? _parseTimestamp(data['activatedAt']) : null,
      blockedAt: data['blockedAt'] != null ? _parseTimestamp(data['blockedAt']) : null,
      cancelledAt: data['cancelledAt'] != null ? _parseTimestamp(data['cancelledAt']) : null,
      // Límites
      dailyLimit: data['dailyLimit']?.toDouble(),
      monthlyLimit: data['monthlyLimit']?.toDouble(),
      atmLimit: data['atmLimit']?.toDouble(),
      onlineLimit: data['onlineLimit']?.toDouble(),
      // Información de solicitud
      requestReason: data['requestReason'] ?? '',
      deliveryAddress: data['deliveryAddress'],
      deliveryDistrict: data['deliveryDistrict'],
      deliveryProvince: data['deliveryProvince'],
      deliveryDepartment: data['deliveryDepartment'],
      deliveryPhone: data['deliveryPhone'],
      additionalComments: data['additionalComments'],
      // Configuraciones de seguridad
      isContactlessEnabled: data['isContactlessEnabled'],
      isOnlineEnabled: data['isOnlineEnabled'],
      isAtmEnabled: data['isAtmEnabled'],
      isInternationalEnabled: data['isInternationalEnabled'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'accountId': accountId,
      'microfinancieraId': microfinancieraId,
      'cardNumber': cardNumber,
      'cardType': cardType.name,
      'cardBrand': cardBrand.name,
      'holderName': holderName,
      'expiryDate': Timestamp.fromDate(expiryDate),
      'status': status.name,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
      'activatedAt': activatedAt != null ? Timestamp.fromDate(activatedAt!) : null,
      'blockedAt': blockedAt != null ? Timestamp.fromDate(blockedAt!) : null,
      'cancelledAt': cancelledAt != null ? Timestamp.fromDate(cancelledAt!) : null,
      // Límites
      'dailyLimit': dailyLimit,
      'monthlyLimit': monthlyLimit,
      'atmLimit': atmLimit,
      'onlineLimit': onlineLimit,
      // Información de solicitud
      'requestReason': requestReason,
      'deliveryAddress': deliveryAddress,
      'deliveryDistrict': deliveryDistrict,
      'deliveryProvince': deliveryProvince,
      'deliveryDepartment': deliveryDepartment,
      'deliveryPhone': deliveryPhone,
      'additionalComments': additionalComments,
      // Configuraciones de seguridad
      'isContactlessEnabled': isContactlessEnabled,
      'isOnlineEnabled': isOnlineEnabled,
      'isAtmEnabled': isAtmEnabled,
      'isInternationalEnabled': isInternationalEnabled,
    };
  }

  Card copyWith({
    String? id,
    String? userId,
    String? accountId,
    String? microfinancieraId,
    String? cardNumber,
    CardType? cardType,
    CardBrand? cardBrand,
    String? holderName,
    DateTime? expiryDate,
    CardStatus? status,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? activatedAt,
    DateTime? blockedAt,
    DateTime? cancelledAt,
    double? dailyLimit,
    double? monthlyLimit,
    double? atmLimit,
    double? onlineLimit,
    String? requestReason,
    String? deliveryAddress,
    String? deliveryDistrict,
    String? deliveryProvince,
    String? deliveryDepartment,
    String? deliveryPhone,
    String? additionalComments,
    bool? isContactlessEnabled,
    bool? isOnlineEnabled,
    bool? isAtmEnabled,
    bool? isInternationalEnabled,
  }) {
    return Card(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      accountId: accountId ?? this.accountId,
      microfinancieraId: microfinancieraId ?? this.microfinancieraId,
      cardNumber: cardNumber ?? this.cardNumber,
      cardType: cardType ?? this.cardType,
      cardBrand: cardBrand ?? this.cardBrand,
      holderName: holderName ?? this.holderName,
      expiryDate: expiryDate ?? this.expiryDate,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      activatedAt: activatedAt ?? this.activatedAt,
      blockedAt: blockedAt ?? this.blockedAt,
      cancelledAt: cancelledAt ?? this.cancelledAt,
      dailyLimit: dailyLimit ?? this.dailyLimit,
      monthlyLimit: monthlyLimit ?? this.monthlyLimit,
      atmLimit: atmLimit ?? this.atmLimit,
      onlineLimit: onlineLimit ?? this.onlineLimit,
      requestReason: requestReason ?? this.requestReason,
      deliveryAddress: deliveryAddress ?? this.deliveryAddress,
      deliveryDistrict: deliveryDistrict ?? this.deliveryDistrict,
      deliveryProvince: deliveryProvince ?? this.deliveryProvince,
      deliveryDepartment: deliveryDepartment ?? this.deliveryDepartment,
      deliveryPhone: deliveryPhone ?? this.deliveryPhone,
      additionalComments: additionalComments ?? this.additionalComments,
      isContactlessEnabled: isContactlessEnabled ?? this.isContactlessEnabled,
      isOnlineEnabled: isOnlineEnabled ?? this.isOnlineEnabled,
      isAtmEnabled: isAtmEnabled ?? this.isAtmEnabled,
      isInternationalEnabled: isInternationalEnabled ?? this.isInternationalEnabled,
    );
  }

  String get maskedCardNumber {
    if (cardNumber.length == 16) {
      // Para números de 16 dígitos, mostrar solo los últimos 4
      return '**** **** **** ${cardNumber.substring(12)}';
    } else if (cardNumber.length >= 4) {
      // Para otros casos, mostrar solo los últimos 4 dígitos
      return '**** **** **** ${cardNumber.substring(cardNumber.length - 4)}';
    }
    // Si el número es muy corto, enmascarar completamente
    return '**** **** **** ****';
  }
  
  String get fullyMaskedCardNumber {
    // Para casos donde no se debe mostrar ningún dígito
    return '**** **** **** ****';
  }
  
  String get shortCardNumber {
    if (cardNumber.length >= 4) {
      return cardNumber.substring(cardNumber.length - 4);
    }
    return cardNumber;
  }
  
  String get formattedExpiryDate {
    return '${expiryDate.month.toString().padLeft(2, '0')}/${expiryDate.year.toString().substring(2)}';
  }
  
  bool get isActive => status == CardStatus.active;
  
  bool get isBlocked => status == CardStatus.blocked;
  
  bool get isExpired => DateTime.now().isAfter(expiryDate);
  
  bool get isRequested => status == CardStatus.requested;
  
  bool get isInProduction => status == CardStatus.inProduction;
  
  bool get isDelivered => status == CardStatus.delivered;

  static DateTime _parseTimestamp(dynamic timestamp) {
    if (timestamp is Timestamp) {
      return timestamp.toDate();
    } else if (timestamp is DateTime) {
      return timestamp;
    } else {
      return DateTime.now();
    }
  }
}

enum CardType {
  debit('Débito'),
  credit('Crédito'),
  prepaid('Prepago');

  const CardType(this.displayName);
  final String displayName;
}

enum CardBrand {
  visa('Visa'),
  mastercard('Mastercard'),
  amex('American Express'),
  dinersClub('Diners Club');

  const CardBrand(this.displayName);
  final String displayName;
}

enum CardStatus {
  requested('Solicitada'),
  approved('Aprobada'),
  inProduction('En Producción'),
  delivered('Entregada'),
  active('Activa'),
  blocked('Bloqueada'),
  expired('Vencida'),
  cancelled('Cancelada');

  const CardStatus(this.displayName);
  final String displayName;
}