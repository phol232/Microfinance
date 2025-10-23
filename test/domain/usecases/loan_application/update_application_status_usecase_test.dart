import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mobile/domain/repositories/loan_application_repository.dart';
import 'package:mobile/domain/usecases/loan_application/update_application_status_usecase.dart';
import 'package:mobile/domain/core/error/failures.dart';

import 'update_application_status_usecase_test.mocks.dart';

@GenerateMocks([LoanApplicationRepository])
void main() {
  late UpdateApplicationStatusUseCase useCase;
  late MockLoanApplicationRepository mockRepository;

  setUp(() {
    mockRepository = MockLoanApplicationRepository();
    useCase = UpdateApplicationStatusUseCase(mockRepository);
  });

  group('UpdateApplicationStatusUseCase', () {
    const testMicrofinancieraId = 'test_mf_id';
    const testApplicationId = 'test_app_id';
    const testNewStatus = 'approved';
    const testUserId = 'test_user_id';
    const testReason = 'Test reason';

    test('should update application status successfully', () async {
      // Arrange
      when(mockRepository.updateApplicationStatus(
        any,
        any,
        any,
        any,
        reason: anyNamed('reason'),
      )).thenAnswer((_) async {});

      // Act
      final result = await useCase(
        microfinancieraId: testMicrofinancieraId,
        applicationId: testApplicationId,
        newStatus: testNewStatus,
        userId: testUserId,
        reason: testReason,
      );

      // Assert
      expect(result, const Right(null));
      verify(mockRepository.updateApplicationStatus(
        testMicrofinancieraId,
        testApplicationId,
        testNewStatus,
        testUserId,
        reason: testReason,
      )).called(1);
    });

    test('should return network failure when repository throws exception', () async {
      // Arrange
      when(mockRepository.updateApplicationStatus(
        any,
        any,
        any,
        any,
        reason: anyNamed('reason'),
      )).thenThrow(Exception('Network error'));

      // Act
      final result = await useCase(
        microfinancieraId: testMicrofinancieraId,
        applicationId: testApplicationId,
        newStatus: testNewStatus,
        userId: testUserId,
        reason: testReason,
      );

      // Assert
      expect(result.isLeft(), true);
      verify(mockRepository.updateApplicationStatus(
        testMicrofinancieraId,
        testApplicationId,
        testNewStatus,
        testUserId,
        reason: testReason,
      )).called(1);
    });

    test('should return validation failure for empty microfinancieraId', () async {
      // Act
      final result = await useCase(
        microfinancieraId: '',
        applicationId: testApplicationId,
        newStatus: testNewStatus,
        userId: testUserId,
        reason: testReason,
      );

      // Assert
      expect(result.isLeft(), true);
      result.fold(
        (failure) => expect(failure, isA<ValidationFailure>()),
        (_) => fail('Expected ValidationFailure'),
      );
      verifyZeroInteractions(mockRepository);
    });

    test('should return validation failure for empty applicationId', () async {
      // Act
      final result = await useCase(
        microfinancieraId: testMicrofinancieraId,
        applicationId: '',
        newStatus: testNewStatus,
        userId: testUserId,
        reason: testReason,
      );

      // Assert
      expect(result.isLeft(), true);
      result.fold(
        (failure) => expect(failure, isA<ValidationFailure>()),
        (_) => fail('Expected ValidationFailure'),
      );
    });

    test('should return validation failure for empty newStatus', () async {
      // Act
      final result = await useCase(
        microfinancieraId: testMicrofinancieraId,
        applicationId: testApplicationId,
        newStatus: '',
        userId: testUserId,
        reason: testReason,
      );

      // Assert
      expect(result.isLeft(), true);
      result.fold(
        (failure) => expect(failure, isA<ValidationFailure>()),
        (_) => fail('Expected ValidationFailure'),
      );
    });

    test('should return validation failure for empty userId', () async {
      // Act
      final result = await useCase(
        microfinancieraId: testMicrofinancieraId,
        applicationId: testApplicationId,
        newStatus: testNewStatus,
        userId: '',
        reason: testReason,
      );

      // Assert
      expect(result.isLeft(), true);
      result.fold(
        (failure) => expect(failure, isA<ValidationFailure>()),
        (_) => fail('Expected ValidationFailure'),
      );
    });
  });
}