import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';

import '../firebase_options.dart';
import '../models/user_profile.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;
  final FacebookAuth _facebookAuth = FacebookAuth.instance;
  Future<void>? _googleInitialization;

  AuthService() {
    if (!kIsWeb) {
      unawaited(_ensureGoogleInitialized());
    }
  }

  Future<void> _ensureGoogleInitialized() {
    return _googleInitialization ??= _googleSignIn.initialize(
      clientId: _googleClientId(),
    );
  }

  String? _googleClientId() {
    if (kIsWeb) return null;
    final options = DefaultFirebaseOptions.currentPlatform;
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

  // Stream de estado de autenticación
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Usuario actual
  User? get currentUser => _auth.currentUser;

  // Iniciar sesión anónimo (para desarrollo y pruebas)
  Future<UserCredential?> signInAnonymously() async {
    try {
      return await _auth.signInAnonymously();
    } catch (e) {
      print('Error signing in anonymously: $e');
      return null;
    }
  }

  // Iniciar sesión con email y password (para futuro)
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
        await _ensureUserDocuments(user);
      }

      return credential;
    } catch (e) {
      print('Error signing in with email and password: $e');
      return null;
    }
  }

  // Registrar con email y password (para futuro)
  Future<UserCredential?> createUserWithEmailAndPassword(
    String email,
    String password, {
    String? firstName,
    String? lastName,
    String? photoUrl,
  }) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = credential.user;
      if (user != null) {
        await _ensureUserDocuments(
          user,
          firstName: firstName,
          lastName: lastName,
          photoUrl: photoUrl,
        );
      }

      return credential;
    } catch (e) {
      print('Error creating user with email and password: $e');
      return null;
    }
  }

  // Iniciar sesión con Google
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

      final googleUser = await _googleSignIn.authenticate();

      final googleAuth = googleUser.authentication;
      final idToken = googleAuth.idToken;
      if (idToken == null) {
        print('Google Sign-In did not provide an ID token');
        return null;
      }

      final credential = GoogleAuthProvider.credential(idToken: idToken);

      final userCredential = await _auth.signInWithCredential(credential);

      final user = userCredential.user;
      if (user != null) {
        unawaited(_ensureUserDocuments(user));
      }

      return userCredential;
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled ||
          e.code == GoogleSignInExceptionCode.interrupted ||
          e.code == GoogleSignInExceptionCode.uiUnavailable) {
        return null;
      }
      final errorDetails = e.description ?? '';
      print('Google Sign-In failed: ${e.code} $errorDetails');
      return null;
    } catch (e) {
      print('Error signing in with Google: $e');
      return null;
    }
  }

  // Cerrar sesión
  Future<void> signOut() async {
    try {
      if (!kIsWeb) {
        await _ensureGoogleInitialized();
        await _googleSignIn.signOut();
      }
      await _facebookAuth.logOut();
      await _auth.signOut();
    } catch (e) {
      print('Error signing out: $e');
    }
  }

  // Iniciar sesión con Facebook
  Future<UserCredential?> signInWithFacebook() async {
    try {
      if (kIsWeb) {
        final facebookProvider = FacebookAuthProvider();
        return await _auth.signInWithPopup(facebookProvider);
      }

      final LoginResult result = await _facebookAuth.login(
        permissions: const ['email', 'public_profile'],
      );

      switch (result.status) {
        case LoginStatus.success:
          final accessToken = result.accessToken?.token;
          if (accessToken == null) {
            print('Facebook Sign-In did not return an access token');
            return null;
          }
          final credential = FacebookAuthProvider.credential(accessToken);
          final userCredential = await _auth.signInWithCredential(credential);
          final user = userCredential.user;
          if (user != null) {
            await _ensureUserDocuments(user);
          }
          return userCredential;
        case LoginStatus.cancelled:
          return null;
        case LoginStatus.failed:
        case LoginStatus.operationInProgress:
          final error = result.message ?? 'Unknown error';
          print('Facebook Sign-In failed: $error');
          return null;
      }
    } catch (e) {
      print('Error signing in with Facebook: $e');
      return null;
    }
  }

  // Obtener información del usuario actual
  Map<String, dynamic>? getUserInfo() {
    final user = currentUser;
    if (user == null) return null;

    return {
      'uid': user.uid,
      'email': user.email,
      'displayName': user.displayName,
      'photoURL': user.photoURL,
      'isAnonymous': user.isAnonymous,
    };
  }

  // Verificar si el usuario está autenticado
  bool get isAuthenticated => currentUser != null;

  Future<void> ensureCurrentUserDocuments({
    String? firstName,
    String? lastName,
    String? photoUrl,
  }) async {
    final user = _auth.currentUser;
    if (user == null) return;
    await _ensureUserDocuments(
      user,
      firstName: firstName,
      lastName: lastName,
      photoUrl: photoUrl,
    );
  }

  Future<void> _ensureUserDocuments(
    User user, {
    String? firstName,
    String? lastName,
    String? photoUrl,
  }) async {
    try {
      final firestore = FirebaseFirestore.instance;
      final usersCollection = firestore.collection('users');
      final profilesCollection = firestore.collection('user_profiles');

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
        'photoUrl': user.photoURL,
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
    } catch (e) {
      debugPrint('Error ensuring user documents: $e');
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

  // Hash de contraseña
  String _hashPassword(String password) {
    var bytes = utf8.encode(password);
    var digest = sha256.convert(bytes);
    return digest.toString();
  }

  // Registro manual con todos los campos
  Future<UserCredential> registerWithEmailAndPassword({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    required String dni,
    required String phone,
  }) async {
    final FirebaseFirestore firestore = FirebaseFirestore.instance;

    // Verificar si el email ya existe
    final emailExists = await checkEmailExists(email);
    if (emailExists) {
      throw Exception('Este email ya está registrado');
    }

    // Verificar si el DNI ya existe
    if (dni.isNotEmpty) {
      final dniExists = await checkDniExists(dni);
      if (dniExists) {
        throw Exception('Este DNI ya está registrado');
      }
    }

    // Crear usuario en Firebase Auth
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    final user = credential.user!;
    final hashedPassword = _hashPassword(password);

    // Crear perfil de usuario
    final profileData = {
      'uid': user.uid,
      'email': email,
      'firstName': firstName,
      'lastName': lastName,
      'fullName': '$firstName $lastName',
      'dni': dni.isNotEmpty ? dni : null,
      'phone': phone.isNotEmpty ? phone : null,
      'photoUrl': null,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };

    // Guardar perfil en Firestore
    await firestore.collection('user_profiles').doc(user.uid).set(profileData);

    // Guardar en colección users
    await firestore.collection('users').doc(user.uid).set({
      'uid': user.uid,
      'email': email,
      'displayName': '$firstName $lastName',
      'createdAt': FieldValue.serverTimestamp(),
      'lastLoginAt': FieldValue.serverTimestamp(),
    });

    // Guardar contraseña hasheada
    await firestore.collection('user_credentials').doc(user.uid).set({
      'hashedPassword': hashedPassword,
      'createdAt': FieldValue.serverTimestamp(),
    });

    return credential;
  }

  // Obtener perfil del usuario
  Future<UserProfile?> getUserProfile(String uid) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('user_profiles')
          .doc(uid)
          .get();
      if (doc.exists && doc.data() != null) {
        return UserProfile.fromMap(doc.data()!, doc.id);
      }
      return null;
    } catch (e) {
      print('Error obteniendo perfil: $e');
      return null;
    }
  }

  // Stream del perfil del usuario
  Stream<UserProfile?> getUserProfileStream(String uid) {
    return FirebaseFirestore.instance
        .collection('user_profiles')
        .doc(uid)
        .snapshots()
        .map((doc) {
          if (doc.exists && doc.data() != null) {
            return UserProfile.fromMap(doc.data()!, doc.id);
          }
          return null;
        });
  }

  // Actualizar perfil del usuario
  Future<void> updateUserProfile(
    String uid,
    Map<String, dynamic> updates,
  ) async {
    final firestore = FirebaseFirestore.instance;

    updates['updatedAt'] = FieldValue.serverTimestamp();
    await firestore.collection('user_profiles').doc(uid).update(updates);

    // Si se actualizó el nombre, también actualizar en users
    if (updates.containsKey('fullName')) {
      await firestore.collection('users').doc(uid).update({
        'displayName': updates['fullName'],
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }
  }

  // Verificar si email existe
  Future<bool> checkEmailExists(String email) async {
    try {
      final query = await FirebaseFirestore.instance
          .collection('user_profiles')
          .where('email', isEqualTo: email)
          .get();
      return query.docs.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  // Verificar si DNI existe
  Future<bool> checkDniExists(String dni) async {
    try {
      if (dni.isEmpty) return false;
      final query = await FirebaseFirestore.instance
          .collection('user_profiles')
          .where('dni', isEqualTo: dni)
          .get();
      return query.docs.isNotEmpty;
    } catch (e) {
      return false;
    }
  }
}

class _NameParts {
  const _NameParts({this.firstName, this.lastName, this.fullName});

  final String? firstName;
  final String? lastName;
  final String? fullName;
}
