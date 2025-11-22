import '../core/usecase.dart';
import '../../entities/loan_application.dart';
import '../../repositories/loan_application_repository.dart';
import '../../core/error/failures.dart';
import 'package:fpdart/fpdart.dart';

class CreateLoanApplicationUseCase implements UseCase<String, CreateLoanApplicationParams> {
  final LoanApplicationRepository repository;

  CreateLoanApplicationUseCase(this.repository);

  @override
  Future<Either<Failure, String>> call(CreateLoanApplicationParams params) async {
    try {
      final id = await repository.createApplication(
        params.microfinancieraId,
        params.application,
      );
      return Right(id);
    } catch (e) {
      return Left(UnknownFailure(e.toString(), code: 'create_loan_application'));
    }
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
