import 'package:cloud_firestore/cloud_firestore.dart';
import 'common.dart';

class IntakeRequest {
  final String id;
  final String status; // "received"|"validated"|"routed"|"rejected"|"converted"
  final ContactInfo contact;
  final ApplicantInfo applicant;
  final RequestedInfo requested;
  final ConsentInfo consent;
  final RoutingInfo routing;
  final RiskFlags riskFlags;
  final DateTime createdAt;
  final DateTime updatedAt;

  IntakeRequest({
    required this.id,
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

  factory IntakeRequest.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

    return IntakeRequest(
      id: doc.id,
      status: data['status'] ?? '',
      contact: ContactInfo.fromMap(data['contact'] ?? {}),
      applicant: ApplicantInfo.fromMap(data['applicant'] ?? {}),
      requested: RequestedInfo.fromMap(data['requested'] ?? {}),
      consent: ConsentInfo.fromMap(data['consent'] ?? {}),
      routing: RoutingInfo.fromMap(data['routing'] ?? {}),
      riskFlags: RiskFlags.fromMap(data['risk_flags'] ?? {}),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
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
}

class ContactInfo {
  final String phone;
  final String email;
  final bool verified;

  ContactInfo({
    required this.phone,
    required this.email,
    required this.verified,
  });

  factory ContactInfo.fromMap(Map<String, dynamic> map) {
    return ContactInfo(
      phone: map['phone'] ?? '',
      email: map['email'] ?? '',
      verified: map['verified'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {'phone': phone, 'email': email, 'verified': verified};
  }
}

class ApplicantInfo {
  final String dni;
  final String fullName;
  final String district;
  final String? activity;

  ApplicantInfo({
    required this.dni,
    required this.fullName,
    required this.district,
    this.activity,
  });

  factory ApplicantInfo.fromMap(Map<String, dynamic> map) {
    return ApplicantInfo(
      dni: map['dni'] ?? '',
      fullName: map['fullName'] ?? '',
      district: map['district'] ?? '',
      activity: map['activity'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'dni': dni,
      'fullName': fullName,
      'district': district,
      if (activity != null) 'activity': activity,
    };
  }
}

class ConsentInfo {
  final bool accepted;
  final String version;
  final DateTime at;

  ConsentInfo({
    required this.accepted,
    required this.version,
    required this.at,
  });

  factory ConsentInfo.fromMap(Map<String, dynamic> map) {
    return ConsentInfo(
      accepted: map['accepted'] ?? false,
      version: map['version'] ?? '',
      at: (map['at'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'accepted': accepted,
      'version': version,
      'at': Timestamp.fromDate(at),
    };
  }
}

class RoutingInfo {
  final String branchId;
  final String? assignedUserId;

  RoutingInfo({required this.branchId, this.assignedUserId});

  factory RoutingInfo.fromMap(Map<String, dynamic> map) {
    return RoutingInfo(
      branchId: map['branchId'] ?? '',
      assignedUserId: map['assignedUserId'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'branchId': branchId,
      if (assignedUserId != null) 'assignedUserId': assignedUserId,
    };
  }
}

class RiskFlags {
  final double spamScore;
  final String? reason;

  RiskFlags({required this.spamScore, this.reason});

  factory RiskFlags.fromMap(Map<String, dynamic> map) {
    return RiskFlags(
      spamScore: (map['spamScore'] ?? 0.0).toDouble(),
      reason: map['reason'],
    );
  }

  Map<String, dynamic> toMap() {
    return {'spamScore': spamScore, if (reason != null) 'reason': reason};
  }
}
