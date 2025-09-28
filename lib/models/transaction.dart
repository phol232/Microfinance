import 'package:cloud_firestore/cloud_firestore.dart';

class FinancialTransaction {
  final String id;
  final DateTime postedAt;
  final String type; // "disbursement"|"repayment"|"fee"|"adjustment"
  final TransactionRef ref;
  final String? memo;
  final int totalCents;

  FinancialTransaction({
    required this.id,
    required this.postedAt,
    required this.type,
    required this.ref,
    this.memo,
    required this.totalCents,
  });

  factory FinancialTransaction.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

    return FinancialTransaction(
      id: doc.id,
      postedAt: (data['postedAt'] as Timestamp).toDate(),
      type: data['type'] ?? '',
      ref: TransactionRef.fromMap(data['ref'] ?? {}),
      memo: data['memo'],
      totalCents: data['totalCents'] ?? 0,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'postedAt': Timestamp.fromDate(postedAt),
      'type': type,
      'ref': ref.toMap(),
      if (memo != null) 'memo': memo,
      'totalCents': totalCents,
    };
  }
}

class TransactionRef {
  final String? loanId;
  final String? repaymentId;

  TransactionRef({this.loanId, this.repaymentId});

  factory TransactionRef.fromMap(Map<String, dynamic> map) {
    return TransactionRef(
      loanId: map['loanId'],
      repaymentId: map['repaymentId'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (loanId != null) 'loanId': loanId,
      if (repaymentId != null) 'repaymentId': repaymentId,
    };
  }
}

// Subcolección: entries
class Entry {
  final String id;
  final String account;
  final int debitCents;
  final int creditCents;

  Entry({
    required this.id,
    required this.account,
    required this.debitCents,
    required this.creditCents,
  });

  factory Entry.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

    return Entry(
      id: doc.id,
      account: data['account'] ?? '',
      debitCents: data['debitCents'] ?? 0,
      creditCents: data['creditCents'] ?? 0,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'account': account,
      'debitCents': debitCents,
      'creditCents': creditCents,
    };
  }
}
