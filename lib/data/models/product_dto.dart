import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/product.dart';

class ProductDto {
  const ProductDto({
    this.id,
    required this.mfId,
    required this.code,
    required this.name,
    required this.interestType,
    required this.rateNominal,
    required this.termMin,
    required this.termMax,
    required this.amountMin,
    required this.amountMax,
    required this.fees,
    required this.penalties,
    required this.createdAt,
  });

  final String? id;
  final String mfId;
  final String code;
  final String name;
  final String interestType;
  final double rateNominal;
  final int termMin;
  final int termMax;
  final double amountMin;
  final double amountMax;
  final Map<String, dynamic> fees;
  final Map<String, dynamic> penalties;
  final DateTime createdAt;

  factory ProductDto.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? <String, dynamic>{};
    return ProductDto(
      id: doc.id,
      mfId: data['mfId'] ?? '',
      code: data['code'] ?? '',
      name: data['name'] ?? '',
      interestType: data['interestType'] ?? 'flat',
      rateNominal: (data['rateNominal'] ?? 0).toDouble(),
      termMin: data['termMin'] ?? 1,
      termMax: data['termMax'] ?? 12,
      amountMin: (data['amountMin'] ?? 0).toDouble(),
      amountMax: (data['amountMax'] ?? 0).toDouble(),
      fees: data['fees'] != null
          ? Map<String, dynamic>.from(data['fees'] as Map)
          : <String, dynamic>{},
      penalties: data['penalties'] != null
          ? Map<String, dynamic>.from(data['penalties'] as Map)
          : <String, dynamic>{},
      createdAt: _parseTimestamp(data['createdAt']),
    );
  }

  factory ProductDto.fromDomain(Product product) {
    return ProductDto(
      id: product.id.isEmpty ? null : product.id,
      mfId: product.mfId,
      code: product.code,
      name: product.name,
      interestType: product.interestType,
      rateNominal: product.rateNominal,
      termMin: product.termMin,
      termMax: product.termMax,
      amountMin: product.amountMin,
      amountMax: product.amountMax,
      fees: product.fees,
      penalties: product.penalties,
      createdAt: product.createdAt,
    );
  }

  Product toDomain() {
    return Product(
      id: id ?? '',
      mfId: mfId,
      code: code,
      name: name,
      interestType: interestType,
      rateNominal: rateNominal,
      termMin: termMin,
      termMax: termMax,
      amountMin: amountMin,
      amountMax: amountMax,
      fees: fees,
      penalties: penalties,
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'mfId': mfId,
      'code': code,
      'name': name,
      'interestType': interestType,
      'rateNominal': rateNominal,
      'termMin': termMin,
      'termMax': termMax,
      'amountMin': amountMin,
      'amountMax': amountMax,
      'fees': fees,
      'penalties': penalties,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  static DateTime _parseTimestamp(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return DateTime.fromMillisecondsSinceEpoch(0);
  }
}
