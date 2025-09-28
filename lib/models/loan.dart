import 'package:cloud_firestore/cloud_firestore.dart';

class Loan {
  final String id;
  final String customerId;
  final String applicationId;
  final String productId;
  final String branchId;
  final String? agentId;
  final int principalCents;
  final String currency; // "PEN"|"USD"
  final double rateNominal;
  final int termMonths;
  final int graceDays;
  final DateTime? disbursementAt;
  final String
  status; // "approved"|"disbursed"|"in_arrears"|"closed"|"written_off"
  final int arrearsDays;
  final BalancesInfo balances;
  final DateTime createdAt;
  final DateTime updatedAt;

  Loan({
    required this.id,
    required this.customerId,
    required this.applicationId,
    required this.productId,
    required this.branchId,
    this.agentId,
    required this.principalCents,
    required this.currency,
    required this.rateNominal,
    required this.termMonths,
    required this.graceDays,
    this.disbursementAt,
    required this.status,
    required this.arrearsDays,
    required this.balances,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Loan.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

    return Loan(
      id: doc.id,
      customerId: data['customerId'] ?? '',
      applicationId: data['applicationId'] ?? '',
      productId: data['productId'] ?? '',
      branchId: data['branchId'] ?? '',
      agentId: data['agentId'],
      principalCents: data['principalCents'] ?? 0,
      currency: data['currency'] ?? 'PEN',
      rateNominal: (data['rateNominal'] ?? 0.0).toDouble(),
      termMonths: data['termMonths'] ?? 0,
      graceDays: data['graceDays'] ?? 0,
      disbursementAt: data['disbursementAt'] != null
          ? (data['disbursementAt'] as Timestamp).toDate()
          : null,
      status: data['status'] ?? '',
      arrearsDays: data['arrearsDays'] ?? 0,
      balances: BalancesInfo.fromMap(data['balances'] ?? {}),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'customerId': customerId,
      'applicationId': applicationId,
      'productId': productId,
      'branchId': branchId,
      if (agentId != null) 'agentId': agentId,
      'principalCents': principalCents,
      'currency': currency,
      'rateNominal': rateNominal,
      'termMonths': termMonths,
      'graceDays': graceDays,
      if (disbursementAt != null)
        'disbursementAt': Timestamp.fromDate(disbursementAt!),
      'status': status,
      'arrearsDays': arrearsDays,
      'balances': balances.toMap(),
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }
}

class BalancesInfo {
  final int principalDueCents;
  final int interestDueCents;
  final int feesDueCents;

  BalancesInfo({
    required this.principalDueCents,
    required this.interestDueCents,
    required this.feesDueCents,
  });

  factory BalancesInfo.fromMap(Map<String, dynamic> map) {
    return BalancesInfo(
      principalDueCents: map['principalDueCents'] ?? 0,
      interestDueCents: map['interestDueCents'] ?? 0,
      feesDueCents: map['feesDueCents'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'principalDueCents': principalDueCents,
      'interestDueCents': interestDueCents,
      'feesDueCents': feesDueCents,
    };
  }
}

// Subcolección: schedule
class Installment {
  final String id;
  final int idx;
  final DateTime dueAt;
  final int principalCents;
  final int interestCents;
  final int feeCents;
  final int totalCents;
  final int paidCents;
  final String status; // "pending"|"partial"|"paid"|"overdue"

  Installment({
    required this.id,
    required this.idx,
    required this.dueAt,
    required this.principalCents,
    required this.interestCents,
    required this.feeCents,
    required this.totalCents,
    required this.paidCents,
    required this.status,
  });

  factory Installment.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

    return Installment(
      id: doc.id,
      idx: data['idx'] ?? 0,
      dueAt: (data['dueAt'] as Timestamp).toDate(),
      principalCents: data['principalCents'] ?? 0,
      interestCents: data['interestCents'] ?? 0,
      feeCents: data['feeCents'] ?? 0,
      totalCents: data['totalCents'] ?? 0,
      paidCents: data['paidCents'] ?? 0,
      status: data['status'] ?? '',
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'idx': idx,
      'dueAt': Timestamp.fromDate(dueAt),
      'principalCents': principalCents,
      'interestCents': interestCents,
      'feeCents': feeCents,
      'totalCents': totalCents,
      'paidCents': paidCents,
      'status': status,
    };
  }
}

// Subcolección: repayments
class Repayment {
  final String id;
  final DateTime receivedAt;
  final int amountCents;
  final String method; // "cash"|"transfer"|"yape"|"plin"
  final String cashierId;
  final String? receiptNo;
  final List<AppliedPayment> applied;

  Repayment({
    required this.id,
    required this.receivedAt,
    required this.amountCents,
    required this.method,
    required this.cashierId,
    this.receiptNo,
    required this.applied,
  });

  factory Repayment.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

    return Repayment(
      id: doc.id,
      receivedAt: (data['receivedAt'] as Timestamp).toDate(),
      amountCents: data['amountCents'] ?? 0,
      method: data['method'] ?? '',
      cashierId: data['cashierId'] ?? '',
      receiptNo: data['receiptNo'],
      applied:
          (data['applied'] as List<dynamic>?)
              ?.map(
                (item) => AppliedPayment.fromMap(item as Map<String, dynamic>),
              )
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'receivedAt': Timestamp.fromDate(receivedAt),
      'amountCents': amountCents,
      'method': method,
      'cashierId': cashierId,
      if (receiptNo != null) 'receiptNo': receiptNo,
      'applied': applied.map((item) => item.toMap()).toList(),
    };
  }
}

class AppliedPayment {
  final String installmentId;
  final int principalCents;
  final int interestCents;
  final int feeCents;

  AppliedPayment({
    required this.installmentId,
    required this.principalCents,
    required this.interestCents,
    required this.feeCents,
  });

  factory AppliedPayment.fromMap(Map<String, dynamic> map) {
    return AppliedPayment(
      installmentId: map['installmentId'] ?? '',
      principalCents: map['principalCents'] ?? 0,
      interestCents: map['interestCents'] ?? 0,
      feeCents: map['feeCents'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'installmentId': installmentId,
      'principalCents': principalCents,
      'interestCents': interestCents,
      'feeCents': feeCents,
    };
  }
}
