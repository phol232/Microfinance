import 'package:flutter_test/flutter_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import '../../../lib/data/datasources/loan_application_datasource.dart';
import '../../../lib/domain/entities/loan_application.dart';

void main() {
  group('LoanApplicationDataSource Integration Tests', () {
    late LoanApplicationDataSource dataSource;
    late FakeFirebaseFirestore fakeFirestore;

    const testMicrofinancieraId = 'test_microfinanciera';
    const testApplicationId = 'test_application';
    const testUserId = 'test_user';
    const testAgentId = 'test_agent';

    setUp(() {
      fakeFirestore = FakeFirebaseFirestore();
      dataSource = LoanApplicationDataSource(firestore: fakeFirestore);
    });

    group('getAllApplications', () {
      test('should return empty list when no applications exist', () async {
        // Act
        final result = await dataSource.getAllApplications(testMicrofinancieraId);

        // Assert
        expect(result, isEmpty);
      });

      test('should return applications when they exist', () async {
        // Arrange
        await fakeFirestore
            .collection('microfinancieras')
            .doc(testMicrofinancieraId)
            .collection('loanApplications')
            .doc(testApplicationId)
            .set({
          'id': testApplicationId,
          'applicantName': 'Test User',
          'amount': 1000.0,
          'status': 'pending',
          'createdAt': DateTime.now(),
          'updatedAt': DateTime.now(),
          'personalInfo': {
            'firstName': 'Test',
            'lastName': 'User',
            'email': 'test@example.com',
            'phone': '123456789',
            'address': 'Test Address',
            'dateOfBirth': DateTime.now().subtract(const Duration(days: 365 * 25)),
            'occupation': 'Test Occupation',
            'monthlyIncome': 2000.0,
          },
          'loanInfo': {
            'amount': 1000.0,
            'purpose': 'Test Purpose',
            'termMonths': 12,
            'interestRate': 0.15,
          },
          'routing': {
            'agentId': testAgentId,
            'assignedAt': DateTime.now(),
          },
        });

        // Act
        final result = await dataSource.getAllApplications(testMicrofinancieraId);

        // Assert
        expect(result, hasLength(1));
        expect(result.first.id, testApplicationId);
        expect(result.first.personalInfo?.firstName, 'Test');
      });
    });

    group('getAssignedToAgent', () {
      test('should return applications assigned to specific agent', () async {
        // Arrange
        await fakeFirestore
            .collection('microfinancieras')
            .doc(testMicrofinancieraId)
            .collection('loanApplications')
            .doc(testApplicationId)
            .set({
          'id': testApplicationId,
          'applicantName': 'Test User',
          'amount': 1000.0,
          'status': 'pending',
          'createdAt': DateTime.now(),
          'updatedAt': DateTime.now(),
          'personalInfo': {
            'firstName': 'Test',
            'lastName': 'User',
            'email': 'test@example.com',
            'phone': '123456789',
            'address': 'Test Address',
            'dateOfBirth': DateTime.now().subtract(const Duration(days: 365 * 25)),
            'occupation': 'Test Occupation',
            'monthlyIncome': 2000.0,
          },
          'loanInfo': {
            'amount': 1000.0,
            'purpose': 'Test Purpose',
            'termMonths': 12,
            'interestRate': 0.15,
          },
          'routing': {
            'agentId': testAgentId,
            'assignedAt': DateTime.now(),
          },
        });

        // Act
        final result = await dataSource.getAssignedToAgent(
          testMicrofinancieraId,
          testAgentId,
        );

        // Assert
        expect(result, hasLength(1));
        expect(result.first.routing?.agentId, testAgentId);
      });

      test('should filter by status when provided', () async {
        // Arrange
        await fakeFirestore
            .collection('microfinancieras')
            .doc(testMicrofinancieraId)
            .collection('loanApplications')
            .doc('app1')
            .set({
          'id': 'app1',
          'applicantName': 'User 1',
          'amount': 1000.0,
          'status': 'pending',
          'createdAt': DateTime.now(),
          'updatedAt': DateTime.now(),
          'personalInfo': {
            'firstName': 'User',
            'lastName': '1',
            'email': 'user1@example.com',
            'phone': '123456789',
            'address': 'Test Address',
            'dateOfBirth': DateTime.now().subtract(const Duration(days: 365 * 25)),
            'occupation': 'Test Occupation',
            'monthlyIncome': 2000.0,
          },
          'loanInfo': {
            'amount': 1000.0,
            'purpose': 'Test Purpose',
            'termMonths': 12,
            'interestRate': 0.15,
          },
          'routing': {
            'agentId': testAgentId,
            'assignedAt': DateTime.now(),
          },
        });

        await fakeFirestore
            .collection('microfinancieras')
            .doc(testMicrofinancieraId)
            .collection('loanApplications')
            .doc('app2')
            .set({
          'id': 'app2',
          'applicantName': 'User 2',
          'amount': 2000.0,
          'status': 'approved',
          'createdAt': DateTime.now(),
          'updatedAt': DateTime.now(),
          'personalInfo': {
            'firstName': 'User',
            'lastName': '2',
            'email': 'user2@example.com',
            'phone': '123456789',
            'address': 'Test Address',
            'dateOfBirth': DateTime.now().subtract(const Duration(days: 365 * 25)),
            'occupation': 'Test Occupation',
            'monthlyIncome': 2000.0,
          },
          'loanInfo': {
            'amount': 2000.0,
            'purpose': 'Test Purpose',
            'termMonths': 12,
            'interestRate': 0.15,
          },
          'routing': {
            'agentId': testAgentId,
            'assignedAt': DateTime.now(),
          },
        });

        // Act
        final result = await dataSource.getAssignedToAgent(
          testMicrofinancieraId,
          testAgentId,
          statusFilter: ['pending'],
        );

        // Assert
        expect(result, hasLength(1));
        expect(result.first.status, 'pending');
      });
    });

    group('updateApplicationStatus', () {
      test('should update application status successfully', () async {
        // Arrange
        await fakeFirestore
            .collection('microfinancieras')
            .doc(testMicrofinancieraId)
            .collection('loanApplications')
            .doc(testApplicationId)
            .set({
          'id': testApplicationId,
          'applicantName': 'Test User',
          'amount': 1000.0,
          'status': 'pending',
          'createdAt': DateTime.now(),
          'updatedAt': DateTime.now(),
          'personalInfo': {
            'firstName': 'Test',
            'lastName': 'User',
            'email': 'test@example.com',
            'phone': '123456789',
            'address': 'Test Address',
            'dateOfBirth': DateTime.now().subtract(const Duration(days: 365 * 25)),
            'occupation': 'Test Occupation',
            'monthlyIncome': 2000.0,
          },
          'loanInfo': {
            'amount': 1000.0,
            'purpose': 'Test Purpose',
            'termMonths': 12,
            'interestRate': 0.15,
          },
          'routing': {
            'agentId': testAgentId,
            'assignedAt': DateTime.now(),
          },
        });

        // Act
        await dataSource.updateApplicationStatus(
          testMicrofinancieraId,
          testApplicationId,
          'approved',
          testUserId,
          reason: 'Test approval',
        );

        // Assert
        final doc = await fakeFirestore
            .collection('microfinancieras')
            .doc(testMicrofinancieraId)
            .collection('loanApplications')
            .doc(testApplicationId)
            .get();

        expect(doc.data()?['status'], 'approved');
      });

      test('should throw exception when application does not exist', () async {
        // Act & Assert
        expect(
          () => dataSource.updateApplicationStatus(
            testMicrofinancieraId,
            'non_existent_id',
            'approved',
            testUserId,
          ),
          throwsException,
        );
      });
    });
  });
}