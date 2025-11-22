import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/credit_product.dart';

class CreditProductDto {
  const CreditProductDto({
    this.id,
    required this.name,
    required this.code,
    required this.mfId,
    required this.rateNominal,
    required this.interestType,
    required this.amountMin,
    required this.amountMax,
    required this.termMin,
    required this.termMax,
    required this.fees,
    required this.penalties,
    required this.createdAt,
    required this.updatedAt,
  });

  final String? id;
  final String name;
  final String code;
  final String mfId;
  final double rateNominal;
  final String interestType;
  final double amountMin;
  final double amountMax;
  final int termMin;
  final int termMax;
  final Map<String, dynamic> fees;
  final Map<String, dynamic> penalties;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory CreditProductDto.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? <String, dynamic>{};
    return CreditProductDto(
      id: doc.id,
      name: data['name'] ?? '',
      code: data['code'] ?? '',
      mfId: data['mfId'] ?? '',
      rateNominal: (data['rateNominal'] ?? 0).toDouble(),
      interestType: data['interestType'] ?? 'flat',
      amountMin: (data['amountMin'] ?? 0).toDouble(),
      amountMax: (data['amountMax'] ?? 0).toDouble(),
      termMin: data['termMin'] ?? 0,
      termMax: data['termMax'] ?? 0,
      fees: data['fees'] != null ? Map<String, dynamic>.from(data['fees']) : <String, dynamic>{},
      penalties: data['penalties'] != null ? Map<String, dynamic>.from(data['penalties']) : <String, dynamic>{},
      createdAt: _parseTimestamp(data['createdAt']),
      updatedAt: _parseTimestamp(data['updatedAt']),
    );
  }

  factory CreditProductDto.fromDomain(CreditProduct product) {
    return CreditProductDto(
      id: product.id.isEmpty ? null : product.id,
      name: product.name,
      code: product.code,
      mfId: product.mfId,
      rateNominal: product.rateNominal,
      interestType: product.interestType,
      amountMin: product.amountMin,
      amountMax: product.amountMax,
      termMin: product.termMin,
      termMax: product.termMax,
      fees: product.fees,
      penalties: product.penalties,
      createdAt: product.createdAt,
      updatedAt: product.updatedAt,
    );
  }

  CreditProduct toDomain() {
    return CreditProduct(
      id: id ?? '',
      name: name,
      code: code,
      mfId: mfId,
      rateNominal: rateNominal,
      interestType: interestType,
      amountMin: amountMin,
      amountMax: amountMax,
      termMin: termMin,
      termMax: termMax,
      fees: fees,
      penalties: penalties,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'code': code,
      'mfId': mfId,
      'rateNominal': rateNominal,
      'interestType': interestType,
      'amountMin': amountMin,
      'amountMax': amountMax,
      'termMin': termMin,
      'termMax': termMax,
      'fees': fees,
      'penalties': penalties,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  static DateTime _parseTimestamp(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return DateTime.fromMillisecondsSinceEpoch(0);
  }
}
