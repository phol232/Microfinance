import '../core/usecase.dart';
import '../../entities/loan_application.dart';
import '../../repositories/loan_application_repository.dart';

class CreateLoanApplicationUseCase implements UseCase<String, CreateLoanApplicationParams> {
  final LoanApplicationRepository repository;

  CreateLoanApplicationUseCase(this.repository);

  @override
  Future<String> call(CreateLoanApplicationParams params) async {
    return await repository.createApplication(
      params.microfinancieraId,
      params.application,
    );
  }
}

class CreateLoanApplicationParams {
  final String microfinancieraId;
  final LoanApplication application;

  CreateLoanApplicationParams({
    required this.microfinancieraId,
    required this.application,
  });
}