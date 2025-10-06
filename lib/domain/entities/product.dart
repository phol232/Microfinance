import 'package:cloud_firestore/cloud_firestore.dart';

class Product {
  const Product({
    required this.id,
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

  final String id;
  final String mfId;
  final String code;
  final String name;
  final String interestType; // "flat" | "declining"
  final double rateNominal;
  final int termMin;
  final int termMax;
  final double amountMin;
  final double amountMax;
  final Map<String, dynamic> fees;
  final Map<String, dynamic> penalties;
  final DateTime createdAt;

  factory Product.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? <String, dynamic>{};
    return Product(
      id: doc.id,
      mfId: data['mfId'] ?? '',
      code: data['code'] ?? '',
      name: data['name'] ?? '',
      interestType: data['interestType'] ?? 'flat',
      rateNominal: (data['rateNominal'] ?? 0).toDouble(),
      termMin: data['termMin'] ?? 0,
      termMax: data['termMax'] ?? 0,
      amountMin: (data['amountMin'] ?? 0).toDouble(),
      amountMax: (data['amountMax'] ?? 0).toDouble(),
      fees: Map<String, dynamic>.from(data['fees'] ?? <String, dynamic>{}),
      penalties:
          Map<String, dynamic>.from(data['penalties'] ?? <String, dynamic>{}),
      createdAt: _parseTimestamp(data['createdAt']),
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
