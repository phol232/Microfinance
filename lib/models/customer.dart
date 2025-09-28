import 'package:cloud_firestore/cloud_firestore.dart';

class Customer {
  final String id;
  final String fullName;
  final String dni;
  final String phone;
  final String? email;
  final String? address;
  final String? district;
  final String branchId;
  final String status; // "active"|"blocked"|"closed"
  final double? riskScore;
  final String custNo;
  final DateTime createdAt;
  final DateTime updatedAt;

  Customer({
    required this.id,
    required this.fullName,
    required this.dni,
    required this.phone,
    this.email,
    this.address,
    this.district,
    required this.branchId,
    required this.status,
    this.riskScore,
    required this.custNo,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Customer.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

    return Customer(
      id: doc.id,
      fullName: data['fullName'] ?? '',
      dni: data['dni'] ?? '',
      phone: data['phone'] ?? '',
      email: data['email'],
      address: data['address'],
      district: data['district'],
      branchId: data['branchId'] ?? '',
      status: data['status'] ?? '',
      riskScore: data['riskScore']?.toDouble(),
      custNo: data['custNo'] ?? '',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'fullName': fullName,
      'dni': dni,
      'phone': phone,
      if (email != null) 'email': email,
      if (address != null) 'address': address,
      if (district != null) 'district': district,
      'branchId': branchId,
      'status': status,
      if (riskScore != null) 'riskScore': riskScore,
      'custNo': custNo,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }
}
