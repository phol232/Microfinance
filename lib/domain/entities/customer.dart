class Customer {
  const Customer({
    required this.id,
    required this.mfId,
    this.userId,
    required this.docType,
    required this.docNumber,
    required this.fullName,
    required this.phone,
    this.email,
    this.address,
    this.personType,
    required this.searchKeys,
    required this.isActive,
    required this.createdAt,
    required this.createdBy,
  });

  final String id;
  final String mfId;
  final String? userId;
  final String? personType; // "natural" | "juridica"
  final String docType;
  final String docNumber;
  final String fullName;
  final String phone;
  final String? email;
  final String? address;
  final List<String> searchKeys;
  final bool isActive;
  final DateTime createdAt;
  final String createdBy;
}

class CustomerApplication {
  const CustomerApplication({
    required this.id,
    required this.mfId,
    required this.customerId,
    required this.productId,
    required this.amount,
    required this.termMonths,
    required this.status,
    this.assignedUserId,
    this.customerName,
    this.productName,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String mfId;
  final String customerId;
  final String productId;
  final double amount;
  final int termMonths;
  final String status;
  final String? assignedUserId;
  final String? customerName;
  final String? productName;
  final DateTime createdAt;
  final DateTime updatedAt;
}

class ApplicationTrackingEvent {
  const ApplicationTrackingEvent({
    required this.id,
    required this.at,
    required this.actorUserId,
    required this.action,
    required this.status,
    this.note,
  });

  final String id;
  final DateTime at;
  final String actorUserId;
  final String action;
  final String status;
  final String? note;
}

class CustomerLoan {
  const CustomerLoan({
    required this.id,
    required this.mfId,
    required this.customerId,
    required this.status,
    required this.createdAt,
    this.applicationId,
    this.productId,
    this.principal,
    this.rateNominal,
    this.termMonths,
    this.branchId,
    this.startDate,
    this.nextDueDate,
    this.outstandingPrincipal,
  });

  final String id;
  final String mfId;
  final String customerId;
  final String? applicationId;
  final String? productId;
  final double? principal;
  final double? rateNominal;
  final int? termMonths;
  final String status; // "active" | "closed" | "in_arrears"
  final String? branchId;
  final DateTime createdAt;
  final DateTime? startDate;
  final DateTime? nextDueDate;
  final double? outstandingPrincipal;
}

class LoanInstallment {
  const LoanInstallment({
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
