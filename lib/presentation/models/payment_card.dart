class PaymentCard {
  final String id;
  final String cardNumber;
  final String cardHolderName;
  final String expiryDate;
  final String cardType; // 'visa', 'mastercard', 'amex', etc.
  final bool isDefault;

  PaymentCard({
    required this.id,
    required this.cardNumber,
    required this.cardHolderName,
    required this.expiryDate,
    required this.cardType,
    this.isDefault = false,
  });

  // Get masked card number (e.g., "****1234")
  String get maskedCardNumber {
    if (cardNumber.length >= 4) {
      return '****${cardNumber.substring(cardNumber.length - 4)}';
    }
    return cardNumber;
  }

  // Get card brand icon
  String get cardIcon {
    switch (cardType.toLowerCase()) {
      case 'visa':
        return '💳';
      case 'mastercard':
        return '💳';
      case 'amex':
        return '💳';
      default:
        return '💳';
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'cardNumber': cardNumber,
      'cardHolderName': cardHolderName,
      'expiryDate': expiryDate,
      'cardType': cardType,
      'isDefault': isDefault,
    };
  }

  factory PaymentCard.fromJson(Map<String, dynamic> json) {
    return PaymentCard(
      id: json['id'],
      cardNumber: json['cardNumber'],
      cardHolderName: json['cardHolderName'],
      expiryDate: json['expiryDate'],
      cardType: json['cardType'],
      isDefault: json['isDefault'] ?? false,
    );
  }

  PaymentCard copyWith({
    String? id,
    String? cardNumber,
    String? cardHolderName,
    String? expiryDate,
    String? cardType,
    bool? isDefault,
  }) {
    return PaymentCard(
      id: id ?? this.id,
      cardNumber: cardNumber ?? this.cardNumber,
      cardHolderName: cardHolderName ?? this.cardHolderName,
      expiryDate: expiryDate ?? this.expiryDate,
      cardType: cardType ?? this.cardType,
      isDefault: isDefault ?? this.isDefault,
    );
  }
}