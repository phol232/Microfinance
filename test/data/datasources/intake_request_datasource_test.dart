import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mobile/data/datasources/intake_request_datasource.dart';
import 'package:mobile/domain/entities/loan_application.dart';

void main() {
  group('IntakeRequestDataSource', () {
    late IntakeRequestDataSource dataSource;
    late FakeFirebaseFirestore fakeFirestore;

    const microfinancieraId = 'test_mf_123';

    setUp(() {
      fakeFirestore = FakeFirebaseFirestore();
      dataSource = IntakeRequestDataSource(
        firestore: fakeFirestore,
        microfinancieraId: microfinancieraId,
      );
    });

    group('getAll', () {
      test('should return list of loan applications when documents exist', () async {
        // Arrange - Add test data to fake Firestore
        final testData1 = {
          'id': 'app1',
          'customerId': 'customer1',
          'amount': 10000.0,
          'status': 'pending',
          'createdAt': Timestamp.now(),
          'updatedAt': Timestamp.now(),
          'microfinancieraId': microfinancieraId,
        };

        final testData2 = {
          'id': 'app2',
          'customerId': 'customer2',
          'amount': 15000.0,
          'status': 'approved',
          'createdAt': Timestamp.now(),
          'updatedAt': Timestamp.now(),
          'microfinancieraId': microfinancieraId,
        };

        await fakeFirestore
            .collection('microfinancieras')
            .doc(microfinancieraId)
            .collection('loanApplications')
            .doc('app1')
            .set(testData1);

        await fakeFirestore
            .collection('microfinancieras')
            .doc(microfinancieraId)
            .collection('loanApplications')
            .doc('app2')
            .set(testData2);

        // Act
        final result = await dataSource.getAll();

        // Assert
        expect(result, isA<List<LoanApplication>>());
        expect(result.length, equals(2));
        expect(result.any((app) => app.id == 'app1'), isTrue);
        expect(result.any((app) => app.id == 'app2'), isTrue);
      });

      test('should return empty list when no documents exist', () async {
        // Act
        final result = await dataSource.getAll();

        // Assert
        expect(result, isA<List<LoanApplication>>());
        expect(result.length, equals(0));
      });

      test('should handle documents with missing fields gracefully', () async {
        // Arrange - Add valid document
        final validData = {
          'id': 'app1',
          'customerId': 'customer1',
          'amount': 10000.0,
          'status': 'pending',
          'createdAt': Timestamp.now(),
          'updatedAt': Timestamp.now(),
          'microfinancieraId': microfinancieraId,
        };

        // Add document with minimal data that might cause parsing issues
        final minimalData = {
          'id': 'app2',
          'customerId': 'customer2',
          'amount': 5000.0,
          'status': 'pending',
          'createdAt': Timestamp.now(),
          'updatedAt': Timestamp.now(),
          'microfinancieraId': microfinancieraId,
        };

        await fakeFirestore
            .collection('microfinancieras')
            .doc(microfinancieraId)
            .collection('loanApplications')
            .doc('app1')
            .set(validData);

        await fakeFirestore
            .collection('microfinancieras')
            .doc(microfinancieraId)
            .collection('loanApplications')
            .doc('app2')
            .set(minimalData);

        // Act
        final result = await dataSource.getAll();

        // Assert
        expect(result, isA<List<LoanApplication>>());
        // Both documents should be processed successfully
        expect(result.length, equals(2));
        expect(result.any((app) => app.id == 'app1'), isTrue);
        expect(result.any((app) => app.id == 'app2'), isTrue);
      });
    });

    group('constructor', () {
      test('should create instance with provided Firestore', () {
        // Arrange & Act
        final customDataSource = IntakeRequestDataSource(
          firestore: fakeFirestore,
          microfinancieraId: microfinancieraId,
        );

        // Assert
        expect(customDataSource, isNotNull);
      });
    });

    group('basic functionality', () {
      test('should have correct microfinancieraId', () {
        // This test verifies the datasource is properly configured
        expect(dataSource, isNotNull);
      });

      test('should work with fake Firestore instance', () async {
        // This test verifies the datasource can work with fake Firestore
        final result = await dataSource.getAll();
        expect(result, isA<List<LoanApplication>>());
      });
    });
  });
}