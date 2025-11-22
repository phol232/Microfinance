import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/transaction.dart';

class FinancialTransactionDto {
  const FinancialTransactionDto({
    this.id,
    required this.mfId,
    required this.type,
    required this.refType,
    required this.refId,
    required this.debit,
    required this.credit,
    required this.currency,
    required this.branchId,
    required this.createdAt,
    this.metadata,
  });

  final String? id;
  final String mfId;
  final String type;
  final String refType;
  final String refId;
  final double debit;
  final double credit;
  final String currency;
  final String branchId;
  final DateTime createdAt;
  final Map<String, dynamic>? metadata;

  factory FinancialTransactionDto.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? <String, dynamic>{};
    return FinancialTransactionDto(
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
      metadata: data['metadata'] as Map<String, dynamic>?,
    );
  }

  factory FinancialTransactionDto.fromDomain(FinancialTransaction tx) {
    return FinancialTransactionDto(
      id: tx.id.isEmpty ? null : tx.id,
      mfId: tx.mfId,
      type: tx.type,
      refType: tx.refType,
      refId: tx.refId,
      debit: tx.debit,
      credit: tx.credit,
      currency: tx.currency,
      branchId: tx.branchId,
      createdAt: tx.createdAt,
      metadata: tx.metadata,
    );
  }

  FinancialTransaction toDomain() {
    return FinancialTransaction(
      id: id ?? '',
      mfId: mfId,
      type: type,
      refType: refType,
      refId: refId,
      debit: debit,
      credit: credit,
      currency: currency,
      branchId: branchId,
      createdAt: createdAt,
      metadata: metadata,
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
      if (metadata != null) 'metadata': metadata,
    };
  }

  static DateTime _parseTimestamp(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return DateTime.fromMillisecondsSinceEpoch(0);
  }
}
