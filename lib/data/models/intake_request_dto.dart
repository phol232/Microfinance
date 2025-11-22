import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/intake_request.dart' as domain;

class IntakeRequestDto {
  const IntakeRequestDto({
    this.id,
    required this.status,
    required this.contact,
    required this.applicant,
    required this.requested,
    required this.consent,
    required this.routing,
    required this.riskFlags,
    required this.createdAt,
    required this.updatedAt,
  });

  final String? id;
  final domain.ContactInfo contact;
  final domain.ApplicantInfo applicant;
  final domain.RequestedInfo requested;
  final domain.ConsentInfo consent;
  final domain.RoutingInfo routing;
  final domain.RiskFlags riskFlags;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory IntakeRequestDto.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? <String, dynamic>{};
    return IntakeRequestDto(
      id: doc.id,
      status: data['status'] ?? '',
      contact: domain.ContactInfo.fromMap(data['contact'] ?? {}),
      applicant: domain.ApplicantInfo.fromMap(data['applicant'] ?? {}),
      requested: domain.RequestedInfo.fromMap(data['requested'] ?? {}),
      consent: domain.ConsentInfo.fromMap(data['consent'] ?? {}),
      routing: domain.RoutingInfo.fromMap(data['routing'] ?? {}),
      riskFlags: domain.RiskFlags.fromMap(data['risk_flags'] ?? {}),
      createdAt: _parseTimestamp(data['createdAt']),
      updatedAt: _parseTimestamp(data['updatedAt']),
    );
  }

  factory IntakeRequestDto.fromDomain(domain.IntakeRequest req) {
    return IntakeRequestDto(
      id: req.id.isEmpty ? null : req.id,
      status: req.status,
      contact: req.contact,
      applicant: req.applicant,
      requested: req.requested,
      consent: req.consent,
      routing: req.routing,
      riskFlags: req.riskFlags,
      createdAt: req.createdAt,
      updatedAt: req.updatedAt,
    );
  }

  domain.IntakeRequest toDomain() {
    return domain.IntakeRequest(
      id: id ?? '',
      status: status,
      contact: contact,
      applicant: applicant,
      requested: requested,
      consent: consent,
      routing: routing,
      riskFlags: riskFlags,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'status': status,
      'contact': contact.toMap(),
      'applicant': applicant.toMap(),
      'requested': requested.toMap(),
      'consent': consent.toMap(),
      'routing': routing.toMap(),
      'risk_flags': riskFlags.toMap(),
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
