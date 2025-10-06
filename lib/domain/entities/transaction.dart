import 'package:cloud_firestore/cloud_firestore.dart';

class FinancialTransaction {
  const FinancialTransaction({
    required this.id,
    required this.mfId,
    required this.type,
    required this.refType,
    required this.refId,
    required this.debit,
    required this.credit,
    required this.currency,
    required this.branchId,
    required this.createdAt,
  });

  final String id;
  final String mfId;
  final String type;
  final String refType;
  final String refId;
  final double debit;
  final double credit;
  final String currency;
  final String branchId;
  final DateTime createdAt;

  factory FinancialTransaction.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? <String, dynamic>{};
    return FinancialTransaction(
      id: doc.id,
      mfId: data['mfId'] ?? '',
      type: data['type'] ?? '',
      refType: data['refType'] ?? '',
      refId: data['refId'] ?? '',
      debit: (data['debit'] ?? 0).toDouble(),
      credit: (data['credit'] ?? 0).toDouble(),
      currency: data['currency'] ?? 'PEN',
      branchId: data['branchId'] ?? '',
      createdAt: _parseTimestamp(data['createdAt']),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'mfId': mfId,
      'type': type,
      'refType': refType,
      'refId': refId,
      'debit': debit,
      'credit': credit,
      'currency': currency,
      'branchId': branchId,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  static DateTime _parseTimestamp(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return DateTime.fromMillisecondsSinceEpoch(0);
  }
}
