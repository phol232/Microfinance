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
    required this.cci,
    required this.interestRate,
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

  final String id;
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

  Account copyWith({
    String? id,
    String? userId,
    String? microfinancieraId,
    String? accountNumber,
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
