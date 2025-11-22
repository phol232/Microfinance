import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/account.dart';

/// DTO responsable de mapear cuentas contra Firestore sin acoplar al dominio.
class AccountDto {
  const AccountDto({
    this.id,
    required this.userId,
    required this.microfinancieraId,
    required this.accountNumber,
    required this.cci,
    required this.interestRate,
    required this.accountType,
    required this.currency,
    required this.balance,
    required this.status,
    required this.createdAt,
    this.updatedAt,
    this.closedAt,
    required this.holderFirstName,
    required this.holderLastName,
    required this.holderDni,
    required this.holderPhone,
    required this.holderEmail,
    required this.holderAddress,
    required this.holderDistrict,
    required this.holderProvince,
    required this.holderDepartment,
    this.employmentType,
    this.employerName,
    this.position,
    this.monthlyIncome,
    this.initialDeposit,
    this.hasCreditHistory,
    this.hasBankAccount,
    this.bankName,
    this.additionalComments,
  });

  final String? id;
  final String userId;
  final String microfinancieraId;
  final String accountNumber;
  final String cci;
  final double interestRate;
  final AccountType accountType;
  final String currency;
  final double balance;
  final AccountStatus status;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final DateTime? closedAt;
  final String holderFirstName;
  final String holderLastName;
  final String holderDni;
  final String holderPhone;
  final String holderEmail;
  final String holderAddress;
  final String holderDistrict;
  final String holderProvince;
  final String holderDepartment;
  final EmploymentType? employmentType;
  final String? employerName;
  final String? position;
  final double? monthlyIncome;
  final double? initialDeposit;
  final bool? hasCreditHistory;
  final bool? hasBankAccount;
  final String? bankName;
  final String? additionalComments;

  factory AccountDto.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? <String, dynamic>{};
    return AccountDto(
      id: doc.id,
      userId: data['userId'] ?? '',
      microfinancieraId: data['microfinancieraId'] ?? '',
      accountNumber: data['accountNumber'] ?? '',
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
      updatedAt:
          data['updatedAt'] != null ? _parseTimestamp(data['updatedAt']) : null,
      closedAt:
          data['closedAt'] != null ? _parseTimestamp(data['closedAt']) : null,
      holderFirstName: data['holderFirstName'] ?? '',
      holderLastName: data['holderLastName'] ?? '',
      holderDni: data['holderDni'] ?? '',
      holderPhone: data['holderPhone'] ?? '',
      holderEmail: data['holderEmail'] ?? '',
      holderAddress: data['holderAddress'] ?? '',
      holderDistrict: data['holderDistrict'] ?? '',
      holderProvince: data['holderProvince'] ?? '',
      holderDepartment: data['holderDepartment'] ?? '',
      employmentType: data['employmentType'] != null
          ? EmploymentType.values.firstWhere(
              (type) => type.name == data['employmentType'],
              orElse: () => EmploymentType.employed,
            )
          : null,
      employerName: data['employerName'],
      position: data['position'],
      monthlyIncome: data['monthlyIncome']?.toDouble(),
      initialDeposit: data['initialDeposit']?.toDouble(),
      hasCreditHistory: data['hasCreditHistory'],
      hasBankAccount: data['hasBankAccount'],
      bankName: data['bankName'],
      additionalComments: data['additionalComments'],
    );
  }

  factory AccountDto.fromDomain(Account account) {
    return AccountDto(
      id: account.id.isEmpty ? null : account.id,
      userId: account.userId,
      microfinancieraId: account.microfinancieraId,
      accountNumber: account.accountNumber,
      cci: account.cci,
      interestRate: account.interestRate,
      accountType: account.accountType,
      currency: account.currency,
      balance: account.balance,
      status: account.status,
      createdAt: account.createdAt,
      updatedAt: account.updatedAt,
      closedAt: account.closedAt,
      holderFirstName: account.holderFirstName,
      holderLastName: account.holderLastName,
      holderDni: account.holderDni,
      holderPhone: account.holderPhone,
      holderEmail: account.holderEmail,
      holderAddress: account.holderAddress,
      holderDistrict: account.holderDistrict,
      holderProvince: account.holderProvince,
      holderDepartment: account.holderDepartment,
      employmentType: account.employmentType,
      employerName: account.employerName,
      position: account.position,
      monthlyIncome: account.monthlyIncome,
      initialDeposit: account.initialDeposit,
      hasCreditHistory: account.hasCreditHistory,
      hasBankAccount: account.hasBankAccount,
      bankName: account.bankName,
      additionalComments: account.additionalComments,
    );
  }

  Account toDomain() {
    return Account(
      id: id ?? '',
      userId: userId,
      microfinancieraId: microfinancieraId,
      accountNumber: accountNumber,
      cci: cci,
      interestRate: interestRate,
      accountType: accountType,
      currency: currency,
      balance: balance,
      status: status,
      createdAt: createdAt,
      updatedAt: updatedAt,
      closedAt: closedAt,
      holderFirstName: holderFirstName,
      holderLastName: holderLastName,
      holderDni: holderDni,
      holderPhone: holderPhone,
      holderEmail: holderEmail,
      holderAddress: holderAddress,
      holderDistrict: holderDistrict,
      holderProvince: holderProvince,
      holderDepartment: holderDepartment,
      employmentType: employmentType,
      employerName: employerName,
      position: position,
      monthlyIncome: monthlyIncome,
      initialDeposit: initialDeposit,
      hasCreditHistory: hasCreditHistory,
      hasBankAccount: hasBankAccount,
      bankName: bankName,
      additionalComments: additionalComments,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'microfinancieraId': microfinancieraId,
      'accountNumber': accountNumber,
      'cci': cci,
      'interestRate': interestRate,
      'accountType': accountType.name,
      'currency': currency,
      'balance': balance,
      'status': status.name,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
      'closedAt': closedAt != null ? Timestamp.fromDate(closedAt!) : null,
      'holderFirstName': holderFirstName,
      'holderLastName': holderLastName,
      'holderDni': holderDni,
      'holderPhone': holderPhone,
      'holderEmail': holderEmail,
      'holderAddress': holderAddress,
      'holderDistrict': holderDistrict,
      'holderProvince': holderProvince,
      'holderDepartment': holderDepartment,
      'employmentType': employmentType?.name,
      'employerName': employerName,
      'position': position,
      'monthlyIncome': monthlyIncome,
      'initialDeposit': initialDeposit,
      'hasCreditHistory': hasCreditHistory,
      'hasBankAccount': hasBankAccount,
      'bankName': bankName,
      'additionalComments': additionalComments,
    };
  }

  static DateTime _parseTimestamp(dynamic timestamp) {
    if (timestamp is Timestamp) return timestamp.toDate();
    if (timestamp is DateTime) return timestamp;
    return DateTime.now();
  }
}
