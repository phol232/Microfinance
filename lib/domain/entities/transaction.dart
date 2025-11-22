class FinancialTransaction {
  const FinancialTransaction({
    required this.id,
    required this.mfId,
    required this.type,
    required this.refType,
    required this.refId,
    required this.debit,
    required this.credit,
    required this.currency,
    required this.branchId,
    required this.createdAt,
    this.metadata,
  });

  final String id;
  final String mfId;
  final String type;
  final String refType;
  final String refId;
  final double debit;
  final double credit;
  final String currency;
  final String branchId;
  final DateTime createdAt;
  final Map<String, dynamic>? metadata;
}
