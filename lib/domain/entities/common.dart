// Clases comunes compartidas entre modelos
class RequestedInfo {
  final int amountCents;
  final int termMonths;
  final String?
  productId; // Opcional en applications, requerido en intake_requests
  final String? purpose; // Propósito del préstamo

  RequestedInfo({
    required this.amountCents,
    required this.termMonths,
    this.productId,
    this.purpose,
  });

  // Convertir centavos a soles
  double get amount => amountCents / 100.0;

  factory RequestedInfo.fromMap(Map<String, dynamic> map) {
    return RequestedInfo(
      amountCents: map['amountCents'] ?? 0,
      termMonths: map['termMonths'] ?? 0,
      productId: map['productId'],
      purpose: map['purpose'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'amountCents': amountCents,
      'termMonths': termMonths,
      if (productId != null) 'productId': productId,
      if (purpose != null) 'purpose': purpose,
    };
  }
}
