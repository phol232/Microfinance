import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/ml_models.dart';

class MlScoreDto {
  const MlScoreDto({
    this.id,
    required this.applicationId,
    required this.value,
    required this.band,
    required this.reasonCodes,
    required this.modelVersion,
    required this.createdAt,
  });

  final String? id;
  final String applicationId;
  final double value;
  final String band;
  final List<String> reasonCodes;
  final String modelVersion;
  final DateTime createdAt;

  factory MlScoreDto.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? <String, dynamic>{};
    return MlScoreDto(
      id: doc.id,
      applicationId: data['applicationId'] ?? '',
      value: (data['value'] ?? 0.0).toDouble(),
      band: data['band'] ?? '',
      reasonCodes: List<String>.from(data['reasonCodes'] ?? []),
      modelVersion: data['modelVersion'] ?? '',
      createdAt: _parseTimestamp(data['createdAt']),
    );
  }

  factory MlScoreDto.fromDomain(MlScore score) {
    return MlScoreDto(
      id: score.id.isEmpty ? null : score.id,
      applicationId: score.applicationId,
      value: score.value,
      band: score.band,
      reasonCodes: score.reasonCodes,
      modelVersion: score.modelVersion,
      createdAt: score.createdAt,
    );
  }

  MlScore toDomain() => MlScore(
        id: id ?? '',
        applicationId: applicationId,
        value: value,
        band: band,
        reasonCodes: reasonCodes,
        modelVersion: modelVersion,
        createdAt: createdAt,
      );

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

class MlMetricsDto {
  const MlMetricsDto({
    this.id,
    this.customerId,
    this.loanId,
    this.f1TxClass,
    this.mapeForecast,
    this.explainabilityPct,
    this.latencyP95Ms,
    this.adoptionRatePct,
    required this.updatedAt,
  });

  final String? id;
  final String? customerId;
  final String? loanId;
  final double? f1TxClass;
  final double? mapeForecast;
  final double? explainabilityPct;
  final int? latencyP95Ms;
  final double? adoptionRatePct;
  final DateTime updatedAt;

  factory MlMetricsDto.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? <String, dynamic>{};
    return MlMetricsDto(
      id: doc.id,
      customerId: data['customerId'],
      loanId: data['loanId'],
      f1TxClass: data['f1TxClass']?.toDouble(),
      mapeForecast: data['mapeForecast']?.toDouble(),
      explainabilityPct: data['explainabilityPct']?.toDouble(),
      latencyP95Ms: data['latencyP95Ms'] as int?,
      adoptionRatePct: data['adoptionRatePct']?.toDouble(),
      updatedAt: _parseTimestamp(data['updatedAt']),
    );
  }

  factory MlMetricsDto.fromDomain(MlMetrics metrics) {
    return MlMetricsDto(
      id: metrics.id.isEmpty ? null : metrics.id,
      customerId: metrics.customerId,
      loanId: metrics.loanId,
      f1TxClass: metrics.f1TxClass,
      mapeForecast: metrics.mapeForecast,
      explainabilityPct: metrics.explainabilityPct,
      latencyP95Ms: metrics.latencyP95Ms,
      adoptionRatePct: metrics.adoptionRatePct,
      updatedAt: metrics.updatedAt,
    );
  }

  MlMetrics toDomain() => MlMetrics(
        id: id ?? '',
        customerId: customerId,
        loanId: loanId,
        f1TxClass: f1TxClass,
        mapeForecast: mapeForecast,
        explainabilityPct: explainabilityPct,
        latencyP95Ms: latencyP95Ms,
        adoptionRatePct: adoptionRatePct,
        updatedAt: updatedAt,
      );

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

DateTime _parseTimestamp(dynamic value) {
  if (value is Timestamp) return value.toDate();
  if (value is DateTime) return value;
  return DateTime.fromMillisecondsSinceEpoch(0);
}
