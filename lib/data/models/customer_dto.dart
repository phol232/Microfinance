import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/customer.dart';

class CustomerDto {
  const CustomerDto({
    this.id,
    required this.mfId,
    this.userId,
    this.personType,
    required this.docType,
    required this.docNumber,
    required this.fullName,
    required this.phone,
    this.email,
    this.address,
    required this.searchKeys,
    required this.isActive,
    required this.createdAt,
    required this.createdBy,
  });

  final String? id;
  final String mfId;
  final String? userId;
  final String? personType;
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

  factory CustomerDto.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? <String, dynamic>{};
    return CustomerDto(
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
      createdAt: _parseTimestamp(data['createdAt']),
      createdBy: data['createdBy'] ?? '',
    );
  }

  factory CustomerDto.fromDomain(Customer customer) {
    return CustomerDto(
      id: customer.id.isEmpty ? null : customer.id,
      mfId: customer.mfId,
      userId: customer.userId,
      personType: customer.personType,
      docType: customer.docType,
      docNumber: customer.docNumber,
      fullName: customer.fullName,
      phone: customer.phone,
      email: customer.email,
      address: customer.address,
      searchKeys: customer.searchKeys,
      isActive: customer.isActive,
      createdAt: customer.createdAt,
      createdBy: customer.createdBy,
    );
  }

  Customer toDomain() {
    return Customer(
      id: id ?? '',
      mfId: mfId,
      userId: userId,
      personType: personType,
      docType: docType,
      docNumber: docNumber,
      fullName: fullName,
      phone: phone,
      email: email,
      address: address,
      searchKeys: searchKeys,
      isActive: isActive,
      createdAt: createdAt,
      createdBy: createdBy,
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

  static DateTime _parseTimestamp(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return DateTime.fromMillisecondsSinceEpoch(0);
  }
}

class CustomerLoanDto {
  const CustomerLoanDto({
    this.id,
    required this.mfId,
    required this.customerId,
    required this.loanId,
    required this.status,
    required this.createdAt,
  });

  final String? id;
  final String mfId;
  final String customerId;
  final String loanId;
  final String status;
  final DateTime createdAt;

  factory CustomerLoanDto.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? <String, dynamic>{};
    return CustomerLoanDto(
      id: doc.id,
      mfId: data['mfId'] ?? '',
      customerId: data['customerId'] ?? '',
      loanId: data['loanId'] ?? '',
      status: data['status'] ?? 'active',
      createdAt: CustomerDto._parseTimestamp(data['createdAt']),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'mfId': mfId,
      'customerId': customerId,
      'loanId': loanId,
      'status': status,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
