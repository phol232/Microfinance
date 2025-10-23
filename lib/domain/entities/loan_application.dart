import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/logging/app_logger.dart';

class LoanApplication {
  final String id;
  final String userId;
  final String microfinancieraId;

  // Producto
  final ProductInfo? product;

  // Información Personal
  final PersonalInfo? personalInfo;

  // Información de Contacto
  final ContactInfo? contactInfo;

  // Información Laboral
  final EmploymentInfo? employmentInfo;

  // Información Financiera
  final FinancialInfo? financialInfo;

  // Información Adicional
  final AdditionalInfo? additionalInfo;

  // Consentimientos
  final Consents? consents;

  // Ubicación
  final LocationData? location;

  // Estado y Workflow
  final String
  status; // 'pending' | 'received' | 'routed' | 'in_review' | 'decision' | 'approved' | 'rejected' | 'observed' | 'disbursed'
  final RoutingInfo? routing;
  final ScoringResult? scoring;
  final DecisionInfo? decision;
  final ValidationResult? validations;

  final DateTime createdAt;
  final DateTime updatedAt;

  LoanApplication({
    required this.id,
    required this.userId,
    required this.microfinancieraId,
    this.product,
    this.personalInfo,
    this.contactInfo,
    this.employmentInfo,
    this.financialInfo,
    this.additionalInfo,
    this.consents,
    this.location,
    required this.status,
    this.routing,
    this.scoring,
    this.decision,
    this.validations,
    required this.createdAt,
    required this.updatedAt,
  });

  factory LoanApplication.fromFirestore(DocumentSnapshot doc) {
    try {
      final data = doc.data() as Map<String, dynamic>;

      return LoanApplication(
        id: doc.id,
        userId: data['userId'] ?? '',
        microfinancieraId: data['microfinancieraId'] ?? '',
        product: data['product'] != null
            ? ProductInfo.fromMap(data['product'] as Map<String, dynamic>)
            : null,
        personalInfo: data['personalInfo'] != null
            ? PersonalInfo.fromMap(data['personalInfo'] as Map<String, dynamic>)
            : null,
        contactInfo: data['contactInfo'] != null
            ? ContactInfo.fromMap(data['contactInfo'] as Map<String, dynamic>)
            : null,
        employmentInfo: data['employmentInfo'] != null
            ? EmploymentInfo.fromMap(
                data['employmentInfo'] as Map<String, dynamic>,
              )
            : null,
        financialInfo: data['financialInfo'] != null
            ? FinancialInfo.fromMap(
                data['financialInfo'] as Map<String, dynamic>,
              )
            : null,
        additionalInfo: data['additionalInfo'] != null
            ? AdditionalInfo.fromMap(
                data['additionalInfo'] as Map<String, dynamic>,
              )
            : null,
        consents: data['consents'] != null
            ? Consents.fromMap(data['consents'] as Map<String, dynamic>)
            : null,
        location: data['location'] != null
            ? LocationData.fromMap(data['location'] as Map<String, dynamic>)
            : null,
        status: data['status'] ?? 'pending',
        routing: data['routing'] != null
            ? RoutingInfo.fromMap(data['routing'] as Map<String, dynamic>)
            : null,
        scoring: data['scoring'] != null
            ? ScoringResult.fromMap(data['scoring'] as Map<String, dynamic>)
            : null,
        decision: data['decision'] != null
            ? DecisionInfo.fromMap(data['decision'] as Map<String, dynamic>)
            : null,
        validations: data['validations'] != null
            ? ValidationResult.fromMap(
                data['validations'] as Map<String, dynamic>,
              )
            : null,
        createdAt: _parseTimestamp(data['createdAt']),
        updatedAt: _parseTimestamp(data['updatedAt']),
      );
    } catch (e) {
      AppLogger.error('Error parsing LoanApplication from Firestore', tag: 'LoanApplication', error: e);
      rethrow;
    }
  }

  static DateTime _parseTimestamp(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return DateTime.now();
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'microfinancieraId': microfinancieraId,
      if (product != null) 'product': product!.toMap(),
      if (personalInfo != null) 'personalInfo': personalInfo!.toMap(),
      if (contactInfo != null) 'contactInfo': contactInfo!.toMap(),
      if (employmentInfo != null) 'employmentInfo': employmentInfo!.toMap(),
      if (financialInfo != null) 'financialInfo': financialInfo!.toMap(),
      if (additionalInfo != null) 'additionalInfo': additionalInfo!.toMap(),
      if (consents != null) 'consents': consents!.toMap(),
      if (location != null) 'location': location!.toMap(),
      'status': status,
      if (routing != null) 'routing': routing!.toMap(),
      if (scoring != null) 'scoring': scoring!.toMap(),
      if (decision != null) 'decision': decision!.toMap(),
      if (validations != null) 'validations': validations!.toMap(),
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }
}

// Routing Info
class RoutingInfo {
  final String branchId;
  final String? agentId;
  final DateTime? assignedAt;
  final String district;

  RoutingInfo({
    required this.branchId,
    this.agentId,
    this.assignedAt,
    required this.district,
  });

  factory RoutingInfo.fromMap(Map<String, dynamic> map) {
    return RoutingInfo(
      branchId: map['branchId'] ?? '',
      agentId: map['agentId'],
      assignedAt: map['assignedAt'] != null
          ? (map['assignedAt'] as Timestamp).toDate()
          : null,
      district: map['district'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'branchId': branchId,
      if (agentId != null) 'agentId': agentId,
      if (assignedAt != null) 'assignedAt': Timestamp.fromDate(assignedAt!),
      'district': district,
    };
  }
}

// Scoring Result
class ScoringResult {
  final int score;
  final String band; // A, B, C, D
  final List<String> reasonCodes;
  final String modelVersion;
  final DateTime calculatedAt;

  ScoringResult({
    required this.score,
    required this.band,
    required this.reasonCodes,
    required this.modelVersion,
    required this.calculatedAt,
  });

  factory ScoringResult.fromMap(Map<String, dynamic> map) {
    return ScoringResult(
      score: map['score'] ?? 0,
      band: map['band'] ?? 'D',
      reasonCodes: List<String>.from(map['reasonCodes'] ?? []),
      modelVersion: map['modelVersion'] ?? '1.0',
      calculatedAt: (map['calculatedAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'score': score,
      'band': band,
      'reasonCodes': reasonCodes,
      'modelVersion': modelVersion,
      'calculatedAt': Timestamp.fromDate(calculatedAt),
    };
  }
}

// Decision Info
class DecisionInfo {
  final String result; // approved, rejected, observed, pending
  final String? decidedBy;
  final DateTime? decidedAt;
  final String comments;
  final bool isAutomatic;

  DecisionInfo({
    required this.result,
    this.decidedBy,
    this.decidedAt,
    required this.comments,
    required this.isAutomatic,
  });

  factory DecisionInfo.fromMap(Map<String, dynamic> map) {
    return DecisionInfo(
      result: map['result'] ?? 'pending',
      decidedBy: map['decidedBy'],
      decidedAt: map['decidedAt'] != null
          ? (map['decidedAt'] as Timestamp).toDate()
          : null,
      comments: map['comments'] ?? '',
      isAutomatic: map['isAutomatic'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'result': result,
      if (decidedBy != null) 'decidedBy': decidedBy,
      if (decidedAt != null) 'decidedAt': Timestamp.fromDate(decidedAt!),
      'comments': comments,
      'isAutomatic': isAutomatic,
    };
  }
}

// Validation Result
class ValidationResult {
  final bool isValid;
  final List<String> errors;
  final List<String> warnings;

  ValidationResult({
    required this.isValid,
    required this.errors,
    required this.warnings,
  });

  factory ValidationResult.fromMap(Map<String, dynamic> map) {
    return ValidationResult(
      isValid: map['isValid'] ?? false,
      errors: List<String>.from(map['errors'] ?? []),
      warnings: List<String>.from(map['warnings'] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {'isValid': isValid, 'errors': errors, 'warnings': warnings};
  }
}

class LocationData {
  final double latitude;
  final double longitude;
  final DateTime timestamp;

  LocationData({
    required this.latitude,
    required this.longitude,
    required this.timestamp,
  });

  factory LocationData.fromMap(Map<String, dynamic> map) {
    return LocationData(
      latitude: (map['latitude'] ?? 0).toDouble(),
      longitude: (map['longitude'] ?? 0).toDouble(),
      timestamp: _parseTimestamp(map['timestamp']),
    );
  }

  static DateTime _parseTimestamp(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return DateTime.now();
  }

  Map<String, dynamic> toMap() {
    return {
      'latitude': latitude,
      'longitude': longitude,
      'timestamp': Timestamp.fromDate(timestamp),
    };
  }
}

// Información Personal
class PersonalInfo {
  final String firstName;
  final String lastName;
  final String documentType;
  final String documentNumber;
  final String birthDate;
  final String nationality;
  final String maritalStatus;
  final int? dependents;

  PersonalInfo({
    required this.firstName,
    required this.lastName,
    required this.documentType,
    required this.documentNumber,
    required this.birthDate,
    required this.nationality,
    required this.maritalStatus,
    this.dependents,
  });

  factory PersonalInfo.fromMap(Map<String, dynamic> map) {
    return PersonalInfo(
      firstName: map['firstName'] ?? '',
      lastName: map['lastName'] ?? '',
      documentType: map['documentType'] ?? '',
      documentNumber: map['documentNumber'] ?? '',
      birthDate: map['birthDate'] ?? '',
      nationality: map['nationality'] ?? '',
      maritalStatus: map['maritalStatus'] ?? '',
      dependents: map['dependents'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'firstName': firstName,
      'lastName': lastName,
      'documentType': documentType,
      'documentNumber': documentNumber,
      'birthDate': birthDate,
      'nationality': nationality,
      'maritalStatus': maritalStatus,
      if (dependents != null) 'dependents': dependents,
    };
  }
}

// Información de Contacto
class ContactInfo {
  final String address;
  final String district;
  final String province;
  final String department;
  final String mobilePhone;
  final String email;
  final String? homeReference;

  ContactInfo({
    required this.address,
    required this.district,
    required this.province,
    required this.department,
    required this.mobilePhone,
    required this.email,
    this.homeReference,
  });

  factory ContactInfo.fromMap(Map<String, dynamic> map) {
    return ContactInfo(
      address: map['address'] ?? '',
      district: map['district'] ?? '',
      province: map['province'] ?? '',
      department: map['department'] ?? '',
      mobilePhone: map['mobilePhone'] ?? '',
      email: map['email'] ?? '',
      homeReference: map['homeReference'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'address': address,
      'district': district,
      'province': province,
      'department': department,
      'mobilePhone': mobilePhone,
      'email': email,
      if (homeReference != null) 'homeReference': homeReference,
    };
  }
}

// Información Laboral
class EmploymentInfo {
  final String employmentType;
  final String? employerName;
  final String? position;
  final int? yearsEmployed;
  final int? monthsEmployed;
  final String? contractType;
  final String? workPhone;

  EmploymentInfo({
    required this.employmentType,
    this.employerName,
    this.position,
    this.yearsEmployed,
    this.monthsEmployed,
    this.contractType,
    this.workPhone,
  });

  factory EmploymentInfo.fromMap(Map<String, dynamic> map) {
    return EmploymentInfo(
      employmentType: map['employmentType'] ?? '',
      employerName: map['employerName'],
      position: map['position'],
      yearsEmployed: map['yearsEmployed'],
      monthsEmployed: map['monthsEmployed'],
      contractType: map['contractType'],
      workPhone: map['workPhone'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'employmentType': employmentType,
      if (employerName != null) 'employerName': employerName,
      if (position != null) 'position': position,
      if (yearsEmployed != null) 'yearsEmployed': yearsEmployed,
      if (monthsEmployed != null) 'monthsEmployed': monthsEmployed,
      if (contractType != null) 'contractType': contractType,
      if (workPhone != null) 'workPhone': workPhone,
    };
  }
}

// Información Financiera
class FinancialInfo {
  final double monthlyIncome;
  final double? otherIncome;
  final String? otherIncomeSource;
  final double? monthlyExpenses;
  final double? currentDebts;
  final String? currentDebtsEntity;
  final double loanAmount;
  final int loanTermMonths;
  final String loanPurpose;

  FinancialInfo({
    required this.monthlyIncome,
    this.otherIncome,
    this.otherIncomeSource,
    this.monthlyExpenses,
    this.currentDebts,
    this.currentDebtsEntity,
    required this.loanAmount,
    required this.loanTermMonths,
    required this.loanPurpose,
  });

  factory FinancialInfo.fromMap(Map<String, dynamic> map) {
    return FinancialInfo(
      monthlyIncome: (map['monthlyIncome'] ?? 0).toDouble(),
      otherIncome: map['otherIncome'] != null
          ? (map['otherIncome']).toDouble()
          : null,
      otherIncomeSource: map['otherIncomeSource'],
      monthlyExpenses: map['monthlyExpenses'] != null
          ? (map['monthlyExpenses']).toDouble()
          : null,
      currentDebts: map['currentDebts'] != null
          ? (map['currentDebts']).toDouble()
          : null,
      currentDebtsEntity: map['currentDebtsEntity'],
      loanAmount: (map['loanAmount'] ?? 0).toDouble(),
      loanTermMonths: map['loanTermMonths'] ?? 0,
      loanPurpose: map['loanPurpose'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'monthlyIncome': monthlyIncome,
      if (otherIncome != null) 'otherIncome': otherIncome,
      if (otherIncomeSource != null) 'otherIncomeSource': otherIncomeSource,
      if (monthlyExpenses != null) 'monthlyExpenses': monthlyExpenses,
      if (currentDebts != null) 'currentDebts': currentDebts,
      if (currentDebtsEntity != null) 'currentDebtsEntity': currentDebtsEntity,
      'loanAmount': loanAmount,
      'loanTermMonths': loanTermMonths,
      'loanPurpose': loanPurpose,
    };
  }
}

// Información Adicional
class AdditionalInfo {
  final bool hasCreditHistory;
  final bool hasBankAccount;
  final String? bankName;
  final bool hasGuarantee;
  final String? guaranteeDescription;
  final String? additionalComments;

  AdditionalInfo({
    required this.hasCreditHistory,
    required this.hasBankAccount,
    this.bankName,
    required this.hasGuarantee,
    this.guaranteeDescription,
    this.additionalComments,
  });

  factory AdditionalInfo.fromMap(Map<String, dynamic> map) {
    return AdditionalInfo(
      hasCreditHistory: map['hasCreditHistory'] ?? false,
      hasBankAccount: map['hasBankAccount'] ?? false,
      bankName: map['bankName'],
      hasGuarantee: map['hasGuarantee'] ?? false,
      guaranteeDescription: map['guaranteeDescription'],
      additionalComments: map['additionalComments'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'hasCreditHistory': hasCreditHistory,
      'hasBankAccount': hasBankAccount,
      if (bankName != null) 'bankName': bankName,
      'hasGuarantee': hasGuarantee,
      if (guaranteeDescription != null)
        'guaranteeDescription': guaranteeDescription,
      if (additionalComments != null) 'additionalComments': additionalComments,
    };
  }
}

// Consentimientos
class Consents {
  final bool acceptTerms;
  final bool authorizeCreditCheck;
  final bool confirmTruthfulness;

  Consents({
    required this.acceptTerms,
    required this.authorizeCreditCheck,
    required this.confirmTruthfulness,
  });

  factory Consents.fromMap(Map<String, dynamic> map) {
    return Consents(
      acceptTerms: map['acceptTerms'] ?? false,
      authorizeCreditCheck: map['authorizeCreditCheck'] ?? false,
      confirmTruthfulness: map['confirmTruthfulness'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'acceptTerms': acceptTerms,
      'authorizeCreditCheck': authorizeCreditCheck,
      'confirmTruthfulness': confirmTruthfulness,
    };
  }
}

// Información del Producto
class ProductInfo {
  final String id;
  final String code;
  final String name;
  final double rateNominal;
  final String interestType;
  final int termMin;
  final int termMax;
  final double amountMin;
  final double amountMax;

  ProductInfo({
    required this.id,
    required this.code,
    required this.name,
    required this.rateNominal,
    required this.interestType,
    required this.termMin,
    required this.termMax,
    required this.amountMin,
    required this.amountMax,
  });

  factory ProductInfo.fromMap(Map<String, dynamic> map) {
    return ProductInfo(
      id: map['id'] ?? '',
      code: map['code'] ?? '',
      name: map['name'] ?? '',
      rateNominal: (map['rateNominal'] ?? 0).toDouble(),
      interestType: map['interestType'] ?? 'flat',
      termMin: map['termMin'] ?? 0,
      termMax: map['termMax'] ?? 0,
      amountMin: (map['amountMin'] ?? 0).toDouble(),
      amountMax: (map['amountMax'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'code': code,
      'name': name,
      'rateNominal': rateNominal,
      'interestType': interestType,
      'termMin': termMin,
      'termMax': termMax,
      'amountMin': amountMin,
      'amountMax': amountMax,
    };
  }
}
