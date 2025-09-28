import 'package:cloud_firestore/cloud_firestore.dart';

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

  factory MlScore.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

    return MlScore(
      id: doc.id,
      applicationId: data['applicationId'] ?? '',
      value: (data['value'] ?? 0.0).toDouble(),
      band: data['band'] ?? '',
      reasonCodes: List<String>.from(data['reasonCodes'] ?? []),
      modelVersion: data['modelVersion'] ?? '',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'applicationId': applicationId,
      'value': value,
      'band': band,
      'reasonCodes': reasonCodes,
      'modelVersion': modelVersion,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
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

  factory MlMetrics.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

    return MlMetrics(
      id: doc.id,
      customerId: data['customerId'],
      loanId: data['loanId'],
      f1TxClass: data['f1TxClass']?.toDouble(),
      mapeForecast: data['mapeForecast']?.toDouble(),
      explainabilityPct: data['explainabilityPct']?.toDouble(),
      latencyP95Ms: data['latencyP95Ms'],
      adoptionRatePct: data['adoptionRatePct']?.toDouble(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      if (customerId != null) 'customerId': customerId,
      if (loanId != null) 'loanId': loanId,
      if (f1TxClass != null) 'f1TxClass': f1TxClass,
      if (mapeForecast != null) 'mapeForecast': mapeForecast,
      if (explainabilityPct != null) 'explainabilityPct': explainabilityPct,
      if (latencyP95Ms != null) 'latencyP95Ms': latencyP95Ms,
      if (adoptionRatePct != null) 'adoptionRatePct': adoptionRatePct,
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }
}
