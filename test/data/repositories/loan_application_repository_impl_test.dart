import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:mobile/data/repositories/loan_application_repository_impl.dart';
import 'package:mobile/data/datasources/loan_application_datasource.dart';

import 'loan_application_repository_impl_test.mocks.dart';

@GenerateMocks([LoanApplicationDataSource])
void main() {
  late LoanApplicationRepositoryImpl repository;
  late MockLoanApplicationDataSource mockDataSource;

  setUp(() {
    mockDataSource = MockLoanApplicationDataSource();
    repository = LoanApplicationRepositoryImpl(dataSource: mockDataSource);
  });

  group('LoanApplicationRepositoryImpl', () {
    const testMicrofinancieraId = 'test_mf_id';
    const testApplicationId = 'test_app_id';
    const testNewStatus = 'approved';
    const testUserId = 'test_user_id';
    const testReason = 'Test reason';

    group('updateApplicationStatus', () {
      test('should complete successfully when datasource succeeds', () async {
        // Arrange
        when(
          mockDataSource.updateApplicationStatus(
            any,
            any,
            any,
            any,
            reason: anyNamed('reason'),
          ),
        ).thenAnswer((_) async {});

        // Act & Assert - should not throw
        await repository.updateApplicationStatus(
          testMicrofinancieraId,
          testApplicationId,
          testNewStatus,
          testUserId,
          reason: testReason,
        );

        // Verify the datasource was called with correct parameters
        verify(
          mockDataSource.updateApplicationStatus(
            testMicrofinancieraId,
            testApplicationId,
            testNewStatus,
            testUserId,
            reason: testReason,
          ),
        ).called(1);
      });

      test('should throw exception when datasource throws exception', () async {
        when(
          mockDataSource.updateApplicationStatus(
            any,
            any,
            any,
            any,
            reason: anyNamed('reason'),
          ),
        ).thenThrow(Exception('Server error'));

        // Act & Assert
        expect(
          () => repository.updateApplicationStatus(
            testMicrofinancieraId,
            testApplicationId,
            testNewStatus,
            testUserId,
            reason: testReason,
          ),
          throwsA(isA<Exception>()),
        );

        verify(
          mockDataSource.updateApplicationStatus(
            testMicrofinancieraId,
            testApplicationId,
            testNewStatus,
            testUserId,
            reason: testReason,
          ),
        ).called(1);
      });

      test('should throw SocketException when network error occurs', () async {
        // Arrange
        when(
          mockDataSource.updateApplicationStatus(
            any,
            any,
            any,
            any,
            reason: anyNamed('reason'),
          ),
        ).thenThrow(const SocketException('Network error'));

        // Act & Assert
        expect(
          () => repository.updateApplicationStatus(
            testMicrofinancieraId,
            testApplicationId,
            testNewStatus,
            testUserId,
            reason: testReason,
          ),
          throwsA(isA<SocketException>()),
        );

        verify(
          mockDataSource.updateApplicationStatus(
            testMicrofinancieraId,
            testApplicationId,
            testNewStatus,
            testUserId,
            reason: testReason,
          ),
        ).called(1);
      });

      test('should pass additional data when provided', () async {
        // Arrange
        const additionalData = {'key': 'value'};
        when(
          mockDataSource.updateApplicationStatus(
            any,
            any,
            any,
            any,
            reason: anyNamed('reason'),
            additionalData: anyNamed('additionalData'),
          ),
        ).thenAnswer((_) async {});

        // Act
        await repository.updateApplicationStatus(
          testMicrofinancieraId,
          testApplicationId,
          testNewStatus,
          testUserId,
          reason: testReason,
          additionalData: additionalData,
        );

        // Assert
        verify(
          mockDataSource.updateApplicationStatus(
            testMicrofinancieraId,
            testApplicationId,
            testNewStatus,
            testUserId,
            reason: testReason,
            additionalData: additionalData,
          ),
        ).called(1);
      });
    });
  });
}
