import '../../entities/account.dart';
import '../../repositories/account_repository.dart';
import '../core/usecase.dart';
import '../../core/error/failures.dart';
import 'package:fpdart/fpdart.dart';

class CreateAccountUseCase implements UseCase<String, CreateAccountParams> {
  final AccountRepository repository;

  CreateAccountUseCase(this.repository);

  @override
  Future<Either<Failure, String>> call(CreateAccountParams params) async {
    try {
      final canCreate = await repository.canCreateAccount(params.userId);
      if (!canCreate) {
        return const Left(
          ValidationFailure('El usuario ha alcanzado el límite máximo de cuentas'),
        );
      }

      final account = Account(
        id: '',
        userId: params.userId,
        microfinancieraId: params.microfinancieraId,
        accountNumber: '',
        cci: '',
        interestRate: 0.0,
        accountType: params.accountType,
        currency: params.currency,
        balance: params.initialDeposit ?? 0.0,
        status: AccountStatus.pending,
        createdAt: DateTime.now(),
        holderFirstName: params.firstName,
        holderLastName: params.lastName,
        holderDni: params.dni,
        holderPhone: params.phone,
        holderEmail: params.email,
        holderAddress: params.address,
        holderDistrict: params.district,
        holderProvince: params.province,
        holderDepartment: params.department,
        employmentType: params.employmentType,
        employerName: params.employer,
        position: params.position,
        monthlyIncome: params.monthlyIncome,
        initialDeposit: params.initialDeposit,
        hasCreditHistory: params.hasCreditHistory,
        hasBankAccount: params.hasBankAccount,
        bankName: params.bankName,
        additionalComments: params.comments,
      );

      final id = await repository.createAccount(account);
      return Right(id);
    } catch (e) {
      return Left(UnknownFailure(e.toString(), code: 'create_account'));
    }
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
