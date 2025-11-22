class MlScore {
  final String id;
  final String applicationId;
  final double value;
  final String band;
  final List<String> reasonCodes;
  final String modelVersion;
  final DateTime createdAt;

  MlScore({
    required this.id,
    required this.applicationId,
    required this.value,
    required this.band,
    required this.reasonCodes,
    required this.modelVersion,
    required this.createdAt,
  });

}

class MlMetrics {
  final String id;
  final String? customerId;
  final String? loanId;
  final double? f1TxClass;
  final double? mapeForecast;
  final double? explainabilityPct;
  final int? latencyP95Ms;
  final double? adoptionRatePct;
  final DateTime updatedAt;

  MlMetrics({
    required this.id,
    this.customerId,
    this.loanId,
    this.f1TxClass,
    this.mapeForecast,
    this.explainabilityPct,
    this.latencyP95Ms,
    this.adoptionRatePct,
    required this.updatedAt,
  });

}
