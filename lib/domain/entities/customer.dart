import 'package:cloud_firestore/cloud_firestore.dart';

/// Función utilitaria para parsear timestamps de Firestore
DateTime parseTimestamp(dynamic value) {
  if (value is Timestamp) return value.toDate();
  if (value is DateTime) return value;
  return DateTime.fromMillisecondsSinceEpoch(0);
}

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

  factory Customer.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? <String, dynamic>{};
    return Customer(
      id: doc.id,
      mfId: data['mfId'] ?? '',
      userId: data['userId'],
      personType: data['personType'],
      docType: data['docType'] ?? '',
      docNumber: data['docNumber'] ?? '',
      fullName: data['fullName'] ?? '',
      phone: data['phone'] ?? '',
      email: data['email'],
      address: data['address'],
      searchKeys: data['searchKeys'] != null
          ? List<String>.from((data['searchKeys'] as Iterable))
          : const <String>[],
      isActive: data['isActive'] ?? true,
      createdAt: parseTimestamp(data['createdAt']),
      createdBy: data['createdBy'] ?? '',
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'mfId': mfId,
      if (userId != null) 'userId': userId,
      if (personType != null) 'personType': personType,
      'docType': docType,
      'docNumber': docNumber,
      'fullName': fullName,
      'phone': phone,
      if (email != null) 'email': email,
      if (address != null) 'address': address,
      'searchKeys': searchKeys,
      'isActive': isActive,
      'createdAt': Timestamp.fromDate(createdAt),
      'createdBy': createdBy,
    };
  }
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

  factory CustomerApplication.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? <String, dynamic>{};
    return CustomerApplication(
      id: doc.id,
      mfId: data['mfId'] ?? '',
      customerId: data['customerId'] ?? '',
      productId: data['productId'] ?? '',
      amount: (data['amount'] ?? 0).toDouble(),
      termMonths: data['term'] ?? 0,
      status: data['status'] ?? 'draft',
      assignedUserId: data['assignedUserId'],
      customerName: data['customerName'],
      productName: data['productName'],
      createdAt: parseTimestamp(data['createdAt']),
      updatedAt: parseTimestamp(data['updatedAt']),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'mfId': mfId,
      'customerId': customerId,
      'productId': productId,
      'amount': amount,
      'term': termMonths,
      'status': status,
      'assignedUserId': assignedUserId,
      if (customerName != null) 'customerName': customerName,
      if (productName != null) 'productName': productName,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }
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

  factory ApplicationTrackingEvent.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? <String, dynamic>{};
    return ApplicationTrackingEvent(
      id: doc.id,
      at: parseTimestamp(data['at']),
      actorUserId: data['actorUserId'] ?? '',
      action: data['action'] ?? '',
      status: data['status'] ?? '',
      note: data['note'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'at': Timestamp.fromDate(at),
      'actorUserId': actorUserId,
      'action': action,
      'status': status,
      if (note != null) 'note': note,
    };
  }
}

class CustomerLoan {
  const CustomerLoan({
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

  factory CustomerLoan.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? <String, dynamic>{};
    return CustomerLoan(
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
      createdAt: parseTimestamp(data['createdAt']),
      startDate: data['startDate'] != null
          ? parseTimestamp(data['startDate'])
          : null,
      nextDueDate: data['nextDueDate'] != null
          ? parseTimestamp(data['nextDueDate'])
          : null,
      outstandingPrincipal: data['outstandingPrincipal']?.toDouble(),
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

  factory LoanInstallment.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? <String, dynamic>{};
    return LoanInstallment(
      id: doc.id,
      installmentNo: data['installmentNo'] ?? 0,
      dueDate: parseTimestamp(data['dueDate']),
      principalDue: (data['principalDue'] ?? 0).toDouble(),
      interestDue: (data['interestDue'] ?? 0).toDouble(),
      feeDue: (data['feeDue'] ?? 0).toDouble(),
      totalDue: (data['totalDue'] ?? 0).toDouble(),
      paidTotal: (data['paidTotal'] ?? 0).toDouble(),
      status: data['status'] ?? 'due',
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

  factory LoanRepayment.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? <String, dynamic>{};
    return LoanRepayment(
      id: doc.id,
      mfId: data['mfId'] ?? '',
      loanId: data['loanId'] ?? '',
      installmentNo: data['installmentNo'] ?? 0,
      amount: (data['amount'] ?? 0).toDouble(),
      method: data['method'] ?? 'cash',
      paidAt: parseTimestamp(data['paidAt']),
      receivedBy: data['receivedBy'] ?? '',
      txId: data['txId'],
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
