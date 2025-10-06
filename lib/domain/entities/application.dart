import 'package:cloud_firestore/cloud_firestore.dart';

class Application {
  const Application({
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

  factory Application.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? <String, dynamic>{};
    return Application(
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
      createdAt: _parseTimestamp(data['createdAt']),
      updatedAt: _parseTimestamp(data['updatedAt']),
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
      if (assignedUserId != null) 'assignedUserId': assignedUserId,
      if (customerName != null) 'customerName': customerName,
      if (productName != null) 'productName': productName,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  static DateTime _parseTimestamp(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return DateTime.fromMillisecondsSinceEpoch(0);
  }
}
