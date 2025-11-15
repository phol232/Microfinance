class CartItem {
  final String id;
  final String loanId;
  final int installmentNumber;
  final DateTime dueDate;
  final double totalPayment;
  final double principal;
  final double interest;
  final String productName;
  final String productCode;
  final String clientName;

  CartItem({
    required this.id,
    required this.loanId,
    required this.installmentNumber,
    required this.dueDate,
    required this.totalPayment,
    required this.principal,
    required this.interest,
    required this.productName,
    required this.productCode,
    required this.clientName,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'loanId': loanId,
      'installmentNumber': installmentNumber,
      'dueDate': dueDate.toIso8601String(),
      'totalPayment': totalPayment,
      'principal': principal,
      'interest': interest,
      'productName': productName,
      'productCode': productCode,
      'clientName': clientName,
    };
  }

  factory CartItem.fromJson(Map<String, dynamic> json) {
    return CartItem(
      id: json['id'],
      loanId: json['loanId'],
      installmentNumber: json['installmentNumber'],
      dueDate: DateTime.parse(json['dueDate']),
      totalPayment: json['totalPayment'],
      principal: json['principal'],
      interest: json['interest'],
      productName: json['productName'],
      productCode: json['productCode'],
      clientName: json['clientName'],
    );
  }
}