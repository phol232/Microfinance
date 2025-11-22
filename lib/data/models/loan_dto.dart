import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/loan.dart';

class LoanDto {
  const LoanDto({
    this.id,
    required this.mfId,
    required this.applicationId,
    required this.productId,
    required this.customerId,
    required this.principal,
    required this.rateNominal,
    required this.termMonths,
    required this.status,
    required this.branchId,
    required this.createdAt,
    this.startDate,
    this.nextDueDate,
    this.outstandingPrincipal,
  });

  final String? id;
  final String mfId;
  final String applicationId;
  final String productId;
  final String customerId;
  final double principal;
  final double rateNominal;
  final int termMonths;
  final String status;
  final String branchId;
  final DateTime createdAt;
  final DateTime? startDate;
  final DateTime? nextDueDate;
  final double? outstandingPrincipal;

  factory LoanDto.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? <String, dynamic>{};
    return LoanDto(
      id: doc.id,
      mfId: data['mfId'] ?? '',
      applicationId: data['applicationId'] ?? '',
      productId: data['productId'] ?? '',
      customerId: data['customerId'] ?? '',
      principal: (data['principal'] ?? 0).toDouble(),
      rateNominal: (data['rateNominal'] ?? 0).toDouble(),
      termMonths: data['term'] ?? 0,
      status: data['status'] ?? 'active',
      branchId: data['branchId'] ?? '',
      createdAt: _parseTimestamp(data['createdAt']),
      startDate:
          data['startDate'] != null ? _parseTimestamp(data['startDate']) : null,
      nextDueDate: data['nextDueDate'] != null
          ? _parseTimestamp(data['nextDueDate'])
          : null,
      outstandingPrincipal: data['outstandingPrincipal']?.toDouble(),
    );
  }

  factory LoanDto.fromDomain(Loan loan) {
    return LoanDto(
      id: loan.id.isEmpty ? null : loan.id,
      mfId: loan.mfId,
      applicationId: loan.applicationId,
      productId: loan.productId,
      customerId: loan.customerId,
      principal: loan.principal,
      rateNominal: loan.rateNominal,
      termMonths: loan.termMonths,
      status: loan.status,
      branchId: loan.branchId,
      createdAt: loan.createdAt,
      startDate: loan.startDate,
      nextDueDate: loan.nextDueDate,
      outstandingPrincipal: loan.outstandingPrincipal,
    );
  }

  Loan toDomain() {
    return Loan(
      id: id ?? '',
      mfId: mfId,
      applicationId: applicationId,
      productId: productId,
      customerId: customerId,
      principal: principal,
      rateNominal: rateNominal,
      termMonths: termMonths,
      status: status,
      branchId: branchId,
      createdAt: createdAt,
      startDate: startDate,
      nextDueDate: nextDueDate,
      outstandingPrincipal: outstandingPrincipal,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'mfId': mfId,
      'applicationId': applicationId,
      'productId': productId,
      'customerId': customerId,
      'principal': principal,
      'rateNominal': rateNominal,
      'term': termMonths,
      'status': status,
      'branchId': branchId,
      'createdAt': Timestamp.fromDate(createdAt),
      if (startDate != null) 'startDate': Timestamp.fromDate(startDate!),
      if (nextDueDate != null) 'nextDueDate': Timestamp.fromDate(nextDueDate!),
      if (outstandingPrincipal != null)
        'outstandingPrincipal': outstandingPrincipal,
    };
  }

  static DateTime _parseTimestamp(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return DateTime.fromMillisecondsSinceEpoch(0);
  }
}

class LoanScheduleInstallmentDto {
  const LoanScheduleInstallmentDto({
    this.id,
    required this.installmentNo,
    required this.dueDate,
    required this.principalDue,
    required this.interestDue,
    required this.feeDue,
    required this.totalDue,
    required this.paidTotal,
    required this.status,
  });

  final String? id;
  final int installmentNo;
  final DateTime dueDate;
  final double principalDue;
  final double interestDue;
  final double feeDue;
  final double totalDue;
  final double paidTotal;
  final String status;

  factory LoanScheduleInstallmentDto.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? <String, dynamic>{};
    return LoanScheduleInstallmentDto(
      id: doc.id,
      installmentNo: data['installmentNo'] ?? 0,
      dueDate: LoanDto._parseTimestamp(data['dueDate']),
      principalDue: (data['principalDue'] ?? 0).toDouble(),
      interestDue: (data['interestDue'] ?? 0).toDouble(),
      feeDue: (data['feeDue'] ?? 0).toDouble(),
      totalDue: (data['totalDue'] ?? 0).toDouble(),
      paidTotal: (data['paidTotal'] ?? 0).toDouble(),
      status: data['status'] ?? 'due',
    );
  }

  factory LoanScheduleInstallmentDto.fromDomain(
    LoanScheduleInstallment installment,
  ) {
    return LoanScheduleInstallmentDto(
      id: installment.id.isEmpty ? null : installment.id,
      installmentNo: installment.installmentNo,
      dueDate: installment.dueDate,
      principalDue: installment.principalDue,
      interestDue: installment.interestDue,
      feeDue: installment.feeDue,
      totalDue: installment.totalDue,
      paidTotal: installment.paidTotal,
      status: installment.status,
    );
  }

  LoanScheduleInstallment toDomain() {
    return LoanScheduleInstallment(
      id: id ?? '',
      installmentNo: installmentNo,
      dueDate: dueDate,
      principalDue: principalDue,
      interestDue: interestDue,
      feeDue: feeDue,
      totalDue: totalDue,
      paidTotal: paidTotal,
      status: status,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'installmentNo': installmentNo,
      'dueDate': Timestamp.fromDate(dueDate),
      'principalDue': principalDue,
      'interestDue': interestDue,
      'feeDue': feeDue,
      'totalDue': totalDue,
      'paidTotal': paidTotal,
      'status': status,
    };
  }
}

class LoanRepaymentDto {
  const LoanRepaymentDto({
    this.id,
    required this.mfId,
    required this.loanId,
    required this.installmentNo,
    required this.amount,
    required this.method,
    required this.paidAt,
    required this.receivedBy,
    this.txId,
  });

  final String? id;
  final String mfId;
  final String loanId;
  final int installmentNo;
  final double amount;
  final String method;
  final DateTime paidAt;
  final String receivedBy;
  final String? txId;

  factory LoanRepaymentDto.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? <String, dynamic>{};
    return LoanRepaymentDto(
      id: doc.id,
      mfId: data['mfId'] ?? '',
      loanId: data['loanId'] ?? '',
      installmentNo: data['installmentNo'] ?? 0,
      amount: (data['amount'] ?? 0).toDouble(),
      method: data['method'] ?? 'cash',
      paidAt: LoanDto._parseTimestamp(data['paidAt']),
      receivedBy: data['receivedBy'] ?? '',
      txId: data['txId'],
    );
  }

  factory LoanRepaymentDto.fromDomain(LoanRepayment repayment) {
    return LoanRepaymentDto(
      id: repayment.id.isEmpty ? null : repayment.id,
      mfId: repayment.mfId,
      loanId: repayment.loanId,
      installmentNo: repayment.installmentNo,
      amount: repayment.amount,
      method: repayment.method,
      paidAt: repayment.paidAt,
      receivedBy: repayment.receivedBy,
      txId: repayment.txId,
    );
  }

  LoanRepayment toDomain() {
    return LoanRepayment(
      id: id ?? '',
      mfId: mfId,
      loanId: loanId,
      installmentNo: installmentNo,
      amount: amount,
      method: method,
      paidAt: paidAt,
      receivedBy: receivedBy,
      txId: txId,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'mfId': mfId,
      'loanId': loanId,
      'installmentNo': installmentNo,
      'amount': amount,
      'method': method,
      'paidAt': Timestamp.fromDate(paidAt),
      'receivedBy': receivedBy,
      if (txId != null) 'txId': txId,
    };
  }
}
