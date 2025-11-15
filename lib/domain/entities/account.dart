import 'package:cloud_firestore/cloud_firestore.dart';

/// Entidad de dominio para representar una cuenta bancaria/financiera
class Account {
  const Account({
    required this.id,
    required this.userId,
    required this.microfinancieraId,
    required this.accountNumber,
    required this.accountType,
    required this.currency,
    required this.balance,
    required this.status,
    required this.createdAt,
    this.updatedAt,
    this.closedAt,
    // Campos bancarios peruanos
    required this.cci, // Código de Cuenta Interbancario (20 dígitos)
    required this.interestRate, // Tasa de interés DECIMAL(5,2)
    // Información del titular
    required this.holderFirstName,
    required this.holderLastName,
    required this.holderDni,
    required this.holderPhone,
    required this.holderEmail,
    required this.holderAddress,
    required this.holderDistrict,
    required this.holderProvince,
    required this.holderDepartment,
    // Información laboral
    this.employmentType,
    this.employerName,
    this.position,
    this.monthlyIncome,
    // Información adicional
    this.initialDeposit,
    this.hasCreditHistory,
    this.hasBankAccount,
    this.bankName,
    this.additionalComments,
  });

  // Identificadores
  final String id;
  final String userId;
  final String microfinancieraId;
  final String accountNumber;
  
  // Campos bancarios peruanos
  final String cci; // Código de Cuenta Interbancario (20 dígitos)
  final double interestRate; // Tasa de interés DECIMAL(5,2) - ejemplo: 3.25
  
  // Información de la cuenta
  final AccountType accountType;
  final String currency; // 'PEN', 'USD'
  final double balance;
  final AccountStatus status;
  
  // Fechas
  final DateTime createdAt;
  final DateTime? updatedAt;
  final DateTime? closedAt;
  
  // Información del titular (basado en los 7 pasos del portal)
  final String holderFirstName;
  final String holderLastName;
  final String holderDni;
  final String holderPhone;
  final String holderEmail;
  final String holderAddress;
  final String holderDistrict;
  final String holderProvince;
  final String holderDepartment;
  
  // Información laboral
  final EmploymentType? employmentType;
  final String? employerName;
  final String? position;
  final double? monthlyIncome;
  
  // Información adicional
  final double? initialDeposit;
  final bool? hasCreditHistory;
  final bool? hasBankAccount;
  final String? bankName;
  final String? additionalComments;

  factory Account.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? <String, dynamic>{};
    return Account(
      id: doc.id,
      userId: data['userId'] ?? '',
      microfinancieraId: data['microfinancieraId'] ?? '',
      accountNumber: data['accountNumber'] ?? '',
      // Campos bancarios peruanos
      cci: data['cci'] ?? '',
      interestRate: (data['interestRate'] ?? 0.0).toDouble(),
      accountType: AccountType.values.firstWhere(
        (type) => type.name == data['accountType'],
        orElse: () => AccountType.savings,
      ),
      currency: data['currency'] ?? 'PEN',
      balance: (data['balance'] ?? 0.0).toDouble(),
      status: AccountStatus.values.firstWhere(
        (status) => status.name == data['status'],
        orElse: () => AccountStatus.pending,
      ),
      createdAt: _parseTimestamp(data['createdAt']),
      updatedAt: data['updatedAt'] != null ? _parseTimestamp(data['updatedAt']) : null,
      closedAt: data['closedAt'] != null ? _parseTimestamp(data['closedAt']) : null,
      // Información del titular
      holderFirstName: data['holderFirstName'] ?? '',
      holderLastName: data['holderLastName'] ?? '',
      holderDni: data['holderDni'] ?? '',
      holderPhone: data['holderPhone'] ?? '',
      holderEmail: data['holderEmail'] ?? '',
      holderAddress: data['holderAddress'] ?? '',
      holderDistrict: data['holderDistrict'] ?? '',
      holderProvince: data['holderProvince'] ?? '',
      holderDepartment: data['holderDepartment'] ?? '',
      // Información laboral
      employmentType: data['employmentType'] != null
          ? EmploymentType.values.firstWhere(
              (type) => type.name == data['employmentType'],
              orElse: () => EmploymentType.employed,
            )
          : null,
      employerName: data['employerName'],
      position: data['position'],
      monthlyIncome: data['monthlyIncome']?.toDouble(),
      // Información adicional
      initialDeposit: data['initialDeposit']?.toDouble(),
      hasCreditHistory: data['hasCreditHistory'],
      hasBankAccount: data['hasBankAccount'],
      bankName: data['bankName'],
      additionalComments: data['additionalComments'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'microfinancieraId': microfinancieraId,
      'accountNumber': accountNumber,
      // Campos bancarios peruanos
      'cci': cci,
      'interestRate': interestRate,
      'accountType': accountType.name,
      'currency': currency,
      'balance': balance,
      'status': status.name,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
      'closedAt': closedAt != null ? Timestamp.fromDate(closedAt!) : null,
      // Información del titular
      'holderFirstName': holderFirstName,
      'holderLastName': holderLastName,
      'holderDni': holderDni,
      'holderPhone': holderPhone,
      'holderEmail': holderEmail,
      'holderAddress': holderAddress,
      'holderDistrict': holderDistrict,
      'holderProvince': holderProvince,
      'holderDepartment': holderDepartment,
      // Información laboral
      'employmentType': employmentType?.name,
      'employerName': employerName,
      'position': position,
      'monthlyIncome': monthlyIncome,
      // Información adicional
      'initialDeposit': initialDeposit,
      'hasCreditHistory': hasCreditHistory,
      'hasBankAccount': hasBankAccount,
      'bankName': bankName,
      'additionalComments': additionalComments,
    };
  }

  Account copyWith({
    String? id,
    String? userId,
    String? microfinancieraId,
    String? accountNumber,
    // Campos bancarios peruanos
    String? cci,
    double? interestRate,
    AccountType? accountType,
    String? currency,
    double? balance,
    AccountStatus? status,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? closedAt,
    String? holderFirstName,
    String? holderLastName,
    String? holderDni,
    String? holderPhone,
    String? holderEmail,
    String? holderAddress,
    String? holderDistrict,
    String? holderProvince,
    String? holderDepartment,
    EmploymentType? employmentType,
    String? employerName,
    String? position,
    double? monthlyIncome,
    double? initialDeposit,
    bool? hasCreditHistory,
    bool? hasBankAccount,
    String? bankName,
    String? additionalComments,
  }) {
    return Account(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      microfinancieraId: microfinancieraId ?? this.microfinancieraId,
      accountNumber: accountNumber ?? this.accountNumber,
      // Campos bancarios peruanos
      cci: cci ?? this.cci,
      interestRate: interestRate ?? this.interestRate,
      accountType: accountType ?? this.accountType,
      currency: currency ?? this.currency,
      balance: balance ?? this.balance,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      closedAt: closedAt ?? this.closedAt,
      holderFirstName: holderFirstName ?? this.holderFirstName,
      holderLastName: holderLastName ?? this.holderLastName,
      holderDni: holderDni ?? this.holderDni,
      holderPhone: holderPhone ?? this.holderPhone,
      holderEmail: holderEmail ?? this.holderEmail,
      holderAddress: holderAddress ?? this.holderAddress,
      holderDistrict: holderDistrict ?? this.holderDistrict,
      holderProvince: holderProvince ?? this.holderProvince,
      holderDepartment: holderDepartment ?? this.holderDepartment,
      employmentType: employmentType ?? this.employmentType,
      employerName: employerName ?? this.employerName,
      position: position ?? this.position,
      monthlyIncome: monthlyIncome ?? this.monthlyIncome,
      initialDeposit: initialDeposit ?? this.initialDeposit,
      hasCreditHistory: hasCreditHistory ?? this.hasCreditHistory,
      hasBankAccount: hasBankAccount ?? this.hasBankAccount,
      bankName: bankName ?? this.bankName,
      additionalComments: additionalComments ?? this.additionalComments,
    );
  }

  String get fullHolderName => '$holderFirstName $holderLastName';
  
  String get formattedBalance => 'S/ ${balance.toStringAsFixed(2)}';
  
  bool get isActive => status == AccountStatus.active;
  
  bool get isPending => status == AccountStatus.pending;
  
  bool get isClosed => status == AccountStatus.closed;

  static DateTime _parseTimestamp(dynamic timestamp) {
    if (timestamp is Timestamp) {
      return timestamp.toDate();
    } else if (timestamp is DateTime) {
      return timestamp;
    } else {
      return DateTime.now();
    }
  }
}

enum AccountType {
  savings('Ahorros'),
  checking('Corriente'),
  fixedDeposit('Depósito a Plazo'),
  microCredit('Microcrédito');

  const AccountType(this.displayName);
  final String displayName;
}

enum AccountStatus {
  pending('Pendiente'),
  active('Activa'),
  suspended('Suspendida'),
  closed('Cerrada');

  const AccountStatus(this.displayName);
  final String displayName;
}

enum EmploymentType {
  employed('Empleado'),
  selfEmployed('Independiente'),
  business('Empresario'),
  retired('Jubilado'),
  student('Estudiante'),
  unemployed('Desempleado');

  const EmploymentType(this.displayName);
  final String displayName;
}