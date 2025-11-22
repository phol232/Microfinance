class Product {
  const Product({
    required this.id,
    required this.mfId,
    required this.code,
    required this.name,
    required this.interestType,
    required this.rateNominal,
    required this.termMin,
    required this.termMax,
    required this.amountMin,
    required this.amountMax,
    required this.fees,
    required this.penalties,
    required this.createdAt,
  });

  final String id;
  final String mfId;
  final String code;
  final String name;
  final String interestType;
  final double rateNominal;
  final int termMin;
  final int termMax;
  final double amountMin;
  final double amountMax;
  final Map<String, dynamic> fees;
  final Map<String, dynamic> penalties;
  final DateTime createdAt;
}
