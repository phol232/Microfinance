class Loan {
  const Loan({
    required this.id,
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

  final String id;
  final String mfId;
  final String applicationId;
  final String productId;
  final String customerId;
  final double principal;
  final double rateNominal;
  final int termMonths;
  final String status; // "active" | "closed" | "in_arrears"
  final String branchId;
  final DateTime createdAt;
  final DateTime? startDate;
  final DateTime? nextDueDate;
  final double? outstandingPrincipal;
}

class LoanScheduleInstallment {
  const LoanScheduleInstallment({
    required this.id,
    required this.installmentNo,
    required this.dueDate,
    required this.principalDue,
    required this.interestDue,
    required this.feeDue,
    required this.totalDue,
    required this.paidTotal,
    required this.status,
  });

  final String id;
  final int installmentNo;
  final DateTime dueDate;
  final double principalDue;
  final double interestDue;
  final double feeDue;
  final double totalDue;
  final double paidTotal;
  final String status; // "due" | "paid" | "partial" | "late"

}

class LoanRepayment {
  const LoanRepayment({
    required this.id,
    required this.mfId,
    required this.loanId,
    required this.installmentNo,
    required this.amount,
    required this.method,
    required this.paidAt,
    required this.receivedBy,
    this.txId,
  });

  final String id;
  final String mfId;
  final String loanId;
  final int installmentNo;
  final double amount;
  final String method; // "cash" | "wallet" | "bank"
  final DateTime paidAt;
  final String receivedBy;
  final String? txId;

}
