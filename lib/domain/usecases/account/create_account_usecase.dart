import '../../entities/account.dart';
import '../../repositories/account_repository.dart';
import '../core/usecase.dart';

class CreateAccountUseCase implements UseCase<String, CreateAccountParams> {
  final AccountRepository repository;

  CreateAccountUseCase(this.repository);

  @override
  Future<String> call(CreateAccountParams params) async {
    // Verificar si el usuario puede crear una nueva cuenta
    final canCreate = await repository.canCreateAccount(params.userId);
    if (!canCreate) {
      throw Exception('El usuario ha alcanzado el límite máximo de cuentas');
    }

    // Crear la cuenta
    final account = Account(
      id: '', // Se generará automáticamente
      userId: params.userId,
      microfinancieraId: params.microfinancieraId,
      accountNumber: '', // Se generará automáticamente
      // Campos bancarios peruanos (se generarán automáticamente)
      cci: '', // Se generará automáticamente
      interestRate: 0.0, // Se asignará automáticamente según tipo de cuenta
      accountType: params.accountType,
      currency: params.currency,
      balance: params.initialDeposit ?? 0.0,
      status: AccountStatus.pending,
      createdAt: DateTime.now(),
      // Información del titular
      holderFirstName: params.firstName,
      holderLastName: params.lastName,
      holderDni: params.dni,
      holderPhone: params.phone,
      holderEmail: params.email,
      holderAddress: params.address,
      holderDistrict: params.district,
      holderProvince: params.province,
      holderDepartment: params.department,
      // Información laboral
      employmentType: params.employmentType,
      employerName: params.employer,
      position: params.position,
      monthlyIncome: params.monthlyIncome,
      // Información adicional
      initialDeposit: params.initialDeposit,
      hasCreditHistory: params.hasCreditHistory,
      hasBankAccount: params.hasBankAccount,
      bankName: params.bankName,
      additionalComments: params.comments,
    );

    return await repository.createAccount(account);
  }
}

class CreateAccountParams {
  final String userId;
  final String microfinancieraId;
  final AccountType accountType;
  final String currency;
  
  // Información del titular
  final String firstName;
  final String lastName;
  final String dni;
  final String phone;
  final String email;
  final String address;
  final String district;
  final String province;
  final String department;
  
  // Información laboral
  final EmploymentType employmentType;
  final String? employer;
  final String? position;
  final double? monthlyIncome;
  
  // Información adicional
  final double? initialDeposit;
  final bool? hasCreditHistory;
  final bool? hasBankAccount;
  final String? bankName;
  final String? comments;

  CreateAccountParams({
    required this.userId,
    required this.microfinancieraId,
    required this.accountType,
    required this.currency,
    required this.firstName,
    required this.lastName,
    required this.dni,
    required this.phone,
    required this.email,
    required this.address,
    required this.district,
    required this.province,
    required this.department,
    required this.employmentType,
    this.employer,
    this.position,
    this.monthlyIncome,
    this.initialDeposit,
    this.hasCreditHistory,
    this.hasBankAccount,
    this.bankName,
    this.comments,
  });
}