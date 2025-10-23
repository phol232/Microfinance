import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:mobile/data/datasources/firebase_auth_datasource.dart';
import 'firebase_auth_datasource_test.mocks.dart';

@GenerateMocks([FirebaseAuth, GoogleSignIn, User, UserCredential])
void main() {
  group('FirebaseAuthDataSource', () {
    late FirebaseAuthDataSource dataSource;
    late MockFirebaseAuth mockAuth;
    late MockGoogleSignIn mockGoogleSignIn;
    late FakeFirebaseFirestore fakeFirestore;

    setUp(() {
      mockAuth = MockFirebaseAuth();
      mockGoogleSignIn = MockGoogleSignIn();
      fakeFirestore = FakeFirebaseFirestore();

      dataSource = FirebaseAuthDataSource(
        auth: mockAuth,
        firestore: fakeFirestore,
        googleSignIn: mockGoogleSignIn,
      );
    });

    group('authStateChanges', () {
      test('should return auth state changes stream', () {
        // Arrange
        when(
          mockAuth.authStateChanges(),
        ).thenAnswer((_) => const Stream.empty());

        // Act
        final result = dataSource.authStateChanges;

        // Assert
        expect(result, isA<Stream<User?>>());
        verify(mockAuth.authStateChanges()).called(1);
      });
    });

    group('currentUser', () {
      test('should return current user', () {
        // Arrange
        final mockUser = MockUser();
        when(mockAuth.currentUser).thenReturn(mockUser);

        // Act
        final result = dataSource.currentUser;

        // Assert
        expect(result, equals(mockUser));
        verify(mockAuth.currentUser).called(1);
      });
    });

    group('signInAnonymously', () {
      test('should call signInAnonymously method', () async {
        // Arrange
        final mockUserCredential = MockUserCredential();
        when(
          mockAuth.signInAnonymously(),
        ).thenAnswer((_) async => mockUserCredential);

        // Act
        final result = await dataSource.signInAnonymously();

        // Assert
        expect(result, equals(mockUserCredential));
        verify(mockAuth.signInAnonymously()).called(1);
      });
    });

    group('method existence tests', () {
      test('signInWithEmailAndPassword method should exist', () {
        // Verificamos que el método existe y tiene la signatura correcta
        expect(dataSource.signInWithEmailAndPassword, isA<Function>());
      });

      test('registerWithEmailAndPassword method should exist', () {
        // Verificamos que el método existe y tiene la signatura correcta
        expect(dataSource.registerWithEmailAndPassword, isA<Function>());
      });

      test('getUserProfile method should exist', () {
        // Verificamos que el método existe y tiene la signatura correcta
        expect(dataSource.getUserProfile, isA<Function>());
      });

      test('ensureCurrentUserDocuments method should exist', () {
        // Verificamos que el método existe y tiene la signatura correcta
        expect(dataSource.ensureCurrentUserDocuments, isA<Function>());
      });
    });
  });
}
