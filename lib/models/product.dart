import 'package:cloud_firestore/cloud_firestore.dart';

class Product {
  final String id;
  final String name;
  final double rateNominal;
  final int termMonths;
  final int minAmountCents;
  final int maxAmountCents;
  final FeesInfo fees;
  final String status; // "active"|"inactive"
  final DateTime createdAt;
  final DateTime updatedAt;

  Product({
    required this.id,
    required this.name,
    required this.rateNominal,
    required this.termMonths,
    required this.minAmountCents,
    required this.maxAmountCents,
    required this.fees,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Product.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

    return Product(
      id: doc.id,
      name: data['name'] ?? '',
      rateNominal: (data['rateNominal'] ?? 0.0).toDouble(),
      termMonths: data['termMonths'] ?? 0,
      minAmountCents: data['minAmountCents'] ?? 0,
      maxAmountCents: data['maxAmountCents'] ?? 0,
      fees: FeesInfo.fromMap(data['fees'] ?? {}),
      status: data['status'] ?? '',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'rateNominal': rateNominal,
      'termMonths': termMonths,
      'minAmountCents': minAmountCents,
      'maxAmountCents': maxAmountCents,
      'fees': fees.toMap(),
      'status': status,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }
}

class FeesInfo {
  final double? originationPct;
  final int? flatFeeCents;

  FeesInfo({this.originationPct, this.flatFeeCents});

  factory FeesInfo.fromMap(Map<String, dynamic> map) {
    return FeesInfo(
      originationPct: map['originationPct']?.toDouble(),
      flatFeeCents: map['flatFeeCents'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (originationPct != null) 'originationPct': originationPct,
      if (flatFeeCents != null) 'flatFeeCents': flatFeeCents,
    };
  }
}
