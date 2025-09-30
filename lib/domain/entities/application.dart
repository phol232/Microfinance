import 'package:cloud_firestore/cloud_firestore.dart';
import 'common.dart';

class Application {
  final String id;
  final String intakeId;
  final String? customerId;
  final KycInfo kyc;
  final String productId;
  final RequestedInfo requested;
  final String status;
  final BureauInfo bureau;
  final ScoreInfo score;
  final DateTime? submittedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  Application({
    required this.id,
    required this.intakeId,
    this.customerId,
    required this.kyc,
    required this.productId,
    required this.requested,
    required this.status,
    required this.bureau,
    required this.score,
    this.submittedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Application.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

    return Application(
      id: doc.id,
      intakeId: data['intakeId'] ?? '',
      customerId: data['customerId'],
      kyc: KycInfo.fromMap(data['kyc'] ?? {}),
      productId: data['productId'] ?? '',
      requested: RequestedInfo.fromMap(data['requested'] ?? {}),
      status: data['status'] ?? '',
      bureau: BureauInfo.fromMap(data['bureau'] ?? {}),
      score: ScoreInfo.fromMap(data['score'] ?? {}),
      submittedAt: data['submittedAt'] != null
          ? (data['submittedAt'] as Timestamp).toDate()
          : null,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'intakeId': intakeId,
      if (customerId != null) 'customerId': customerId,
      'kyc': kyc.toMap(),
      'productId': productId,
      'requested': requested.toMap(),
      'status': status,
      'bureau': bureau.toMap(),
      'score': score.toMap(),
      if (submittedAt != null) 'submittedAt': Timestamp.fromDate(submittedAt!),
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }
}

class KycInfo {
  final String address;
  final List<String>? references;
  final String? businessType;

  KycInfo({required this.address, this.references, this.businessType});

  factory KycInfo.fromMap(Map<String, dynamic> map) {
    return KycInfo(
      address: map['address'] ?? '',
      references: map['references'] != null
          ? List<String>.from(map['references'])
          : null,
      businessType: map['businessType'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'address': address,
      if (references != null) 'references': references,
      if (businessType != null) 'businessType': businessType,
    };
  }
}

class BureauInfo {
  final String? reportRef;
  final DateTime? fetchedAt;

  BureauInfo({this.reportRef, this.fetchedAt});

  factory BureauInfo.fromMap(Map<String, dynamic> map) {
    return BureauInfo(
      reportRef: map['reportRef'],
      fetchedAt: map['fetchedAt'] != null
          ? (map['fetchedAt'] as Timestamp).toDate()
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (reportRef != null) 'reportRef': reportRef,
      if (fetchedAt != null) 'fetchedAt': Timestamp.fromDate(fetchedAt!),
    };
  }
}

class ScoreInfo {
  final double? value;
  final String? band;
  final List<String>? reasonCodes;
  final String? modelVersion;

  ScoreInfo({this.value, this.band, this.reasonCodes, this.modelVersion});

  factory ScoreInfo.fromMap(Map<String, dynamic> map) {
    return ScoreInfo(
      value: map['value']?.toDouble(),
      band: map['band'],
      reasonCodes: map['reasonCodes'] != null
          ? List<String>.from(map['reasonCodes'])
          : null,
      modelVersion: map['modelVersion'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (value != null) 'value': value,
      if (band != null) 'band': band,
      if (reasonCodes != null) 'reasonCodes': reasonCodes,
      if (modelVersion != null) 'modelVersion': modelVersion,
    };
  }
}
