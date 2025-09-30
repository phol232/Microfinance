import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypto/crypto.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../core/config/firebase_config.dart';
import '../../domain/entities/user_profile.dart';

class FirebaseAuthDataSource {
  FirebaseAuthDataSource({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
    GoogleSignIn? googleSignIn,
    FacebookAuth? facebookAuth,
  }) : _auth = auth ?? FirebaseAuth.instance,
       _firestore = firestore ?? FirebaseFirestore.instance,
       _googleSignIn = googleSignIn ?? GoogleSignIn.instance,
       _facebookAuth = facebookAuth ?? FacebookAuth.instance;

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;
  final GoogleSignIn _googleSignIn;
  final FacebookAuth _facebookAuth;
  Future<void>? _googleInitialization;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  User? get currentUser => _auth.currentUser;

  Future<UserCredential?> signInAnonymously() async {
    try {
      return await _auth.signInAnonymously();
    } catch (error, stackTrace) {
      _logError('signInAnonymously', error, stackTrace);
      return null;
    }
  }

  Future<UserCredential?> signInWithEmailAndPassword(
    String email,
    String password,
  ) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      final user = credential.user;
      if (user != null) {
        unawaited(ensureUserDocuments(user));
      }
      return credential;
    } on FirebaseAuthException catch (error, stackTrace) {
      _logError('signInWithEmailAndPassword', error, stackTrace);
      rethrow;
    } catch (error, stackTrace) {
      _logError('signInWithEmailAndPassword', error, stackTrace);
      rethrow;
    }
  }

  Future<UserCredential?> registerWithEmailAndPassword({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    required String dni,
    required String phone,
  }) async {
    try {
      // Validate email and DNI uniqueness before registration.
      final emailExists = await checkEmailExists(email);
      if (emailExists) {
        throw PlatformException(
          code: 'email-already-in-use',
          message: 'Este email ya está registrado',
        );
      }

      if (dni.isNotEmpty) {
        final dniExists = await checkDniExists(dni);
        if (dniExists) {
          throw PlatformException(
            code: 'dni-already-in-use',
            message: 'Este DNI ya está registrado',
          );
        }
      }

      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = credential.user;
      if (user == null) {
        throw FirebaseAuthException(
          code: 'user-not-created',
          message: 'No se pudo crear el usuario en Firebase Auth',
        );
      }

      final hashedPassword = _hashPassword(password);
      final now = FieldValue.serverTimestamp();

      final profileData = <String, dynamic>{
        'uid': user.uid,
        'email': email,
        'firstName': firstName,
        'lastName': lastName,
        'fullName': '$firstName $lastName',
        'dni': dni.isNotEmpty ? dni : null,
        'phone': phone.isNotEmpty ? phone : null,
        'photoUrl': null,
        'createdAt': now,
        'updatedAt': now,
      };

      await _firestore
          .collection('user_profiles')
          .doc(user.uid)
          .set(profileData);

      await _firestore.collection('users').doc(user.uid).set(<String, dynamic>{
        'uid': user.uid,
        'email': email,
        'displayName': '$firstName $lastName',
        'createdAt': now,
        'lastLoginAt': now,
      });

      await _firestore.collection('user_credentials').doc(user.uid).set({
        'hashedPassword': hashedPassword,
        'createdAt': now,
      });

      return credential;
    } on FirebaseAuthException catch (error, stackTrace) {
      _logError('registerWithEmailAndPassword', error, stackTrace);
      rethrow;
    } catch (error, stackTrace) {
      _logError('registerWithEmailAndPassword', error, stackTrace);
      rethrow;
    }
  }

  Future<UserCredential?> signInWithGoogle() async {
    try {
      if (kIsWeb) {
        final googleProvider = GoogleAuthProvider()..addScope('email');
        return await _auth.signInWithPopup(googleProvider);
      }

      await _ensureGoogleInitialized();

      try {
        await _googleSignIn.disconnect();
      } catch (_) {
        await _googleSignIn.signOut();
      }

      late final GoogleSignInAccount googleUser;
      try {
        googleUser = await _googleSignIn.authenticate();
      } on GoogleSignInException catch (error) {
        if (error.code == GoogleSignInExceptionCode.canceled ||
            error.code == GoogleSignInExceptionCode.interrupted ||
            error.code == GoogleSignInExceptionCode.uiUnavailable) {
          return null;
        }
        rethrow;
      }

      final googleAuth = googleUser.authentication;
      final idToken = googleAuth.idToken;
      if (idToken == null) {
        debugPrint('Google Sign-In did not provide an ID token');
        return null;
      }

      final credential = GoogleAuthProvider.credential(idToken: idToken);

      final userCredential = await _auth.signInWithCredential(credential);
      final user = userCredential.user;
      if (user != null) {
        unawaited(ensureUserDocuments(user));
      }

      return userCredential;
    } on GoogleSignInException catch (error, stackTrace) {
      if (error.code == GoogleSignInExceptionCode.canceled ||
          error.code == GoogleSignInExceptionCode.interrupted ||
          error.code == GoogleSignInExceptionCode.uiUnavailable) {
        return null;
      }
      _logError('signInWithGoogle', error, stackTrace);
      rethrow;
    } catch (error, stackTrace) {
      _logError('signInWithGoogle', error, stackTrace);
      rethrow;
    }
  }

  Future<UserCredential?> signInWithFacebook() async {
    try {
      if (kIsWeb) {
        final facebookProvider = FacebookAuthProvider();
        return await _auth.signInWithPopup(facebookProvider);
      }

      final result = await _facebookAuth.login(
        permissions: const ['email', 'public_profile'],
      );

      switch (result.status) {
        case LoginStatus.success:
          final accessToken = result.accessToken?.token;
          if (accessToken == null) {
            debugPrint('Facebook Sign-In did not return an access token');
            return null;
          }
          final credential = FacebookAuthProvider.credential(accessToken);
          final userCredential = await _auth.signInWithCredential(credential);
          final user = userCredential.user;
          if (user != null) {
            unawaited(ensureUserDocuments(user));
          }
          return userCredential;
        case LoginStatus.cancelled:
          return null;
        case LoginStatus.failed:
        case LoginStatus.operationInProgress:
          final error = result.message ?? 'Unknown error';
          throw FirebaseAuthException(
            code: result.status.name,
            message: 'Facebook Sign-In failed: $error',
          );
      }
    } catch (error, stackTrace) {
      _logError('signInWithFacebook', error, stackTrace);
      rethrow;
    }
  }

  Future<void> signOut() async {
    try {
      if (!kIsWeb) {
        await _ensureGoogleInitialized();
        await _googleSignIn.signOut();
      }
      await _facebookAuth.logOut();
      await _auth.signOut();
    } catch (error, stackTrace) {
      _logError('signOut', error, stackTrace);
      rethrow;
    }
  }

  Future<void> ensureCurrentUserDocuments({
    String? firstName,
    String? lastName,
    String? photoUrl,
  }) async {
    final user = _auth.currentUser;
    if (user == null) return;
    await ensureUserDocuments(
      user,
      firstName: firstName,
      lastName: lastName,
      photoUrl: photoUrl,
    );
  }

  Future<void> ensureUserDocuments(
    User user, {
    String? firstName,
    String? lastName,
    String? photoUrl,
  }) async {
    try {
      final usersCollection = _firestore.collection('users');
      final profilesCollection = _firestore.collection('user_profiles');

      final userDocRef = usersCollection.doc(user.uid);
      final profileDocRef = profilesCollection.doc(user.uid);

      final userSnapshot = await userDocRef.get();
      final now = FieldValue.serverTimestamp();
      final providerIds = user.providerData
          .map((provider) => provider.providerId)
          .toList();

      final userData = <String, dynamic>{
        'uid': user.uid,
        'email': user.email,
        'displayName': user.displayName,
        'photoUrl': photoUrl ?? user.photoURL,
        'providerIds': providerIds,
        'lastLoginAt': now,
      };

      if (!userSnapshot.exists) {
        userData['createdAt'] = now;
      }

      await userDocRef.set(userData, SetOptions(merge: true));

      final profileSnapshot = await profileDocRef.get();

      final parsedNames = _resolveNames(
        user.displayName,
        explicitFirstName: firstName,
        explicitLastName: lastName,
      );

      final profileData = <String, dynamic>{
        'uid': user.uid,
        'email': user.email,
        'firstName': parsedNames.firstName,
        'lastName': parsedNames.lastName,
        'fullName': parsedNames.fullName,
        'photoUrl': photoUrl ?? user.photoURL,
        'updatedAt': now,
      };

      if (!profileSnapshot.exists) {
        profileData['createdAt'] = now;
      }

      await profileDocRef.set(profileData, SetOptions(merge: true));
    } catch (error, stackTrace) {
      _logError('ensureUserDocuments', error, stackTrace);
    }
  }

  Future<UserProfile?> getUserProfile(String uid) async {
    try {
      final doc = await _firestore.collection('user_profiles').doc(uid).get();
      if (doc.exists && doc.data() != null) {
        return UserProfile.fromMap(doc.data()!, doc.id);
      }
      return null;
    } catch (error, stackTrace) {
      _logError('getUserProfile', error, stackTrace);
      return null;
    }
  }

  Stream<UserProfile?> watchUserProfile(String uid) {
    return _firestore.collection('user_profiles').doc(uid).snapshots().map((
      doc,
    ) {
      if (doc.exists && doc.data() != null) {
        return UserProfile.fromMap(doc.data()!, doc.id);
      }
      return null;
    });
  }

  Future<void> updateUserProfile(
    String uid,
    Map<String, dynamic> updates,
  ) async {
    final updatesData = Map<String, dynamic>.from(updates)
      ..['updatedAt'] = FieldValue.serverTimestamp();

    await _firestore.collection('user_profiles').doc(uid).update(updatesData);

    if (updates.containsKey('fullName')) {
      await _firestore.collection('users').doc(uid).update({
        'displayName': updates['fullName'],
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }
  }

  Future<bool> checkEmailExists(String email) async {
    try {
      final query = await _firestore
          .collection('user_profiles')
          .where('email', isEqualTo: email)
          .get();
      return query.docs.isNotEmpty;
    } catch (error, stackTrace) {
      _logError('checkEmailExists', error, stackTrace);
      return false;
    }
  }

  Future<bool> checkDniExists(String dni) async {
    try {
      if (dni.isEmpty) return false;
      final query = await _firestore
          .collection('user_profiles')
          .where('dni', isEqualTo: dni)
          .get();
      return query.docs.isNotEmpty;
    } catch (error, stackTrace) {
      _logError('checkDniExists', error, stackTrace);
      return false;
    }
  }

  Future<void> _ensureGoogleInitialized() {
    return _googleInitialization ??= _googleSignIn.initialize(
      clientId: _googleClientId(),
    );
  }

  String? _googleClientId() {
    if (kIsWeb) return null;
    final options = FirebaseConfig.currentPlatform;
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return options.androidClientId;
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
        return options.iosClientId;
      default:
        return null;
    }
  }

  _NameParts _resolveNames(
    String? displayName, {
    String? explicitFirstName,
    String? explicitLastName,
  }) {
    String? first = explicitFirstName?.trim();
    String? last = explicitLastName?.trim();

    if ((first == null || first.isEmpty) && (last == null || last.isEmpty)) {
      final parts = displayName?.trim().split(RegExp(r'\s+')) ?? <String>[];
      if (parts.isNotEmpty) {
        first = parts.first;
      }
      if (parts.length > 1) {
        last = parts.sublist(1).join(' ');
      }
    }

    final buffer = <String>[];
    if (first != null && first.isNotEmpty) buffer.add(first);
    if (last != null && last.isNotEmpty) buffer.add(last);
    final fullName = buffer.isNotEmpty ? buffer.join(' ') : displayName;

    return _NameParts(firstName: first, lastName: last, fullName: fullName);
  }

  String _hashPassword(String password) {
    final bytes = utf8.encode(password);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  void _logError(String method, Object error, StackTrace stackTrace) {
    debugPrint('FirebaseAuthDataSource::$method error: $error');
    debugPrintStack(stackTrace: stackTrace);
  }
}

class _NameParts {
  const _NameParts({this.firstName, this.lastName, this.fullName});

  final String? firstName;
  final String? lastName;
  final String? fullName;
}
