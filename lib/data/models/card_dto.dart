import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/card.dart';

/// DTO para mapear tarjetas contra Firestore sin acoplar el dominio.
class CardDto {
  const CardDto({
    this.id,
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
    this.dailyLimit,
    this.monthlyLimit,
    this.atmLimit,
    this.onlineLimit,
    required this.requestReason,
    this.deliveryAddress,
    this.deliveryDistrict,
    this.deliveryProvince,
    this.deliveryDepartment,
    this.deliveryPhone,
    this.additionalComments,
    this.isContactlessEnabled,
    this.isOnlineEnabled,
    this.isAtmEnabled,
    this.isInternationalEnabled,
  });

  final String? id;
  final String userId;
  final String accountId;
  final String microfinancieraId;
  final String cardNumber;
  final CardType cardType;
  final CardBrand cardBrand;
  final String holderName;
  final DateTime expiryDate;
  final CardStatus status;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final DateTime? activatedAt;
  final DateTime? blockedAt;
  final DateTime? cancelledAt;
  final double? dailyLimit;
  final double? monthlyLimit;
  final double? atmLimit;
  final double? onlineLimit;
  final String requestReason;
  final String? deliveryAddress;
  final String? deliveryDistrict;
  final String? deliveryProvince;
  final String? deliveryDepartment;
  final String? deliveryPhone;
  final String? additionalComments;
  final bool? isContactlessEnabled;
  final bool? isOnlineEnabled;
  final bool? isAtmEnabled;
  final bool? isInternationalEnabled;

  factory CardDto.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? <String, dynamic>{};
    return CardDto(
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
      updatedAt:
          data['updatedAt'] != null ? _parseTimestamp(data['updatedAt']) : null,
      activatedAt: data['activatedAt'] != null
          ? _parseTimestamp(data['activatedAt'])
          : null,
      blockedAt:
          data['blockedAt'] != null ? _parseTimestamp(data['blockedAt']) : null,
      cancelledAt: data['cancelledAt'] != null
          ? _parseTimestamp(data['cancelledAt'])
          : null,
      dailyLimit: data['dailyLimit']?.toDouble(),
      monthlyLimit: data['monthlyLimit']?.toDouble(),
      atmLimit: data['atmLimit']?.toDouble(),
      onlineLimit: data['onlineLimit']?.toDouble(),
      requestReason: data['requestReason'] ?? '',
      deliveryAddress: data['deliveryAddress'],
      deliveryDistrict: data['deliveryDistrict'],
      deliveryProvince: data['deliveryProvince'],
      deliveryDepartment: data['deliveryDepartment'],
      deliveryPhone: data['deliveryPhone'],
      additionalComments: data['additionalComments'],
      isContactlessEnabled: data['isContactlessEnabled'],
      isOnlineEnabled: data['isOnlineEnabled'],
      isAtmEnabled: data['isAtmEnabled'],
      isInternationalEnabled: data['isInternationalEnabled'],
    );
  }

  factory CardDto.fromDomain(Card card) {
    return CardDto(
      id: card.id.isEmpty ? null : card.id,
      userId: card.userId,
      accountId: card.accountId,
      microfinancieraId: card.microfinancieraId,
      cardNumber: card.cardNumber,
      cardType: card.cardType,
      cardBrand: card.cardBrand,
      holderName: card.holderName,
      expiryDate: card.expiryDate,
      status: card.status,
      createdAt: card.createdAt,
      updatedAt: card.updatedAt,
      activatedAt: card.activatedAt,
      blockedAt: card.blockedAt,
      cancelledAt: card.cancelledAt,
      dailyLimit: card.dailyLimit,
      monthlyLimit: card.monthlyLimit,
      atmLimit: card.atmLimit,
      onlineLimit: card.onlineLimit,
      requestReason: card.requestReason,
      deliveryAddress: card.deliveryAddress,
      deliveryDistrict: card.deliveryDistrict,
      deliveryProvince: card.deliveryProvince,
      deliveryDepartment: card.deliveryDepartment,
      deliveryPhone: card.deliveryPhone,
      additionalComments: card.additionalComments,
      isContactlessEnabled: card.isContactlessEnabled,
      isOnlineEnabled: card.isOnlineEnabled,
      isAtmEnabled: card.isAtmEnabled,
      isInternationalEnabled: card.isInternationalEnabled,
    );
  }

  Card toDomain() {
    return Card(
      id: id ?? '',
      userId: userId,
      accountId: accountId,
      microfinancieraId: microfinancieraId,
      cardNumber: cardNumber,
      cardType: cardType,
      cardBrand: cardBrand,
      holderName: holderName,
      expiryDate: expiryDate,
      status: status,
      createdAt: createdAt,
      updatedAt: updatedAt,
      activatedAt: activatedAt,
      blockedAt: blockedAt,
      cancelledAt: cancelledAt,
      dailyLimit: dailyLimit,
      monthlyLimit: monthlyLimit,
      atmLimit: atmLimit,
      onlineLimit: onlineLimit,
      requestReason: requestReason,
      deliveryAddress: deliveryAddress,
      deliveryDistrict: deliveryDistrict,
      deliveryProvince: deliveryProvince,
      deliveryDepartment: deliveryDepartment,
      deliveryPhone: deliveryPhone,
      additionalComments: additionalComments,
      isContactlessEnabled: isContactlessEnabled,
      isOnlineEnabled: isOnlineEnabled,
      isAtmEnabled: isAtmEnabled,
      isInternationalEnabled: isInternationalEnabled,
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
      'activatedAt':
          activatedAt != null ? Timestamp.fromDate(activatedAt!) : null,
      'blockedAt': blockedAt != null ? Timestamp.fromDate(blockedAt!) : null,
      'cancelledAt':
          cancelledAt != null ? Timestamp.fromDate(cancelledAt!) : null,
      'dailyLimit': dailyLimit,
      'monthlyLimit': monthlyLimit,
      'atmLimit': atmLimit,
      'onlineLimit': onlineLimit,
      'requestReason': requestReason,
      'deliveryAddress': deliveryAddress,
      'deliveryDistrict': deliveryDistrict,
      'deliveryProvince': deliveryProvince,
      'deliveryDepartment': deliveryDepartment,
      'deliveryPhone': deliveryPhone,
      'additionalComments': additionalComments,
      'isContactlessEnabled': isContactlessEnabled,
      'isOnlineEnabled': isOnlineEnabled,
      'isAtmEnabled': isAtmEnabled,
      'isInternationalEnabled': isInternationalEnabled,
    };
  }

  static DateTime _parseTimestamp(dynamic timestamp) {
    if (timestamp is Timestamp) return timestamp.toDate();
    if (timestamp is DateTime) return timestamp;
    return DateTime.now();
  }
}
