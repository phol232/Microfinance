import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../core/config/firebase_config.dart';
import '../../domain/entities/user_profile.dart';
import '../../domain/entities/microfinanciera.dart';

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

  Future<UserCredential?> signInWithEmailAndPassword({
    required String email,
    required String password,
    required String microfinancieraId,
  }) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = credential.user;
      if (user == null) {
        throw FirebaseAuthException(
          code: 'user-null',
          message: 'Error al autenticar usuario',
        );
      }

      final usersCollection = _firestore
          .collection('microfinancieras')
          .doc(microfinancieraId)
          .collection('users');

      DocumentSnapshot<Map<String, dynamic>>? membershipDoc;

      final directDoc = await usersCollection.doc(user.uid).get();
      if (directDoc.exists) {
        membershipDoc = directDoc;
      } else {
        final membershipQuery = await usersCollection
            .where('userId', isEqualTo: user.uid)
            .limit(1)
            .get();
        if (membershipQuery.docs.isNotEmpty) {
          membershipDoc = membershipQuery.docs.first;
        }
      }

      if (membershipDoc == null || !membershipDoc.exists) {
        await _auth.signOut();
        throw FirebaseAuthException(
          code: 'membership-not-found',
          message: 'Usuario no autorizado para esta microfinanciera',
        );
      }

      final membershipData = membershipDoc.data() ?? <String, dynamic>{};
      final status = (membershipData['status'] as String?) ?? 'pending';

      if (status != 'active') {
        await _auth.signOut();
        throw FirebaseAuthException(
          code: 'membership-inactive',
          message: 'Usuario desactivado. Contacte al administrador',
        );
      }

      await membershipDoc.reference.update({
        'lastLoginAt': Timestamp.fromDate(DateTime.now()),
      });

      final membershipRoles = (membershipData['roles'] as List<dynamic>? ?? [])
          .map((value) => value.toString())
          .where((value) => value.isNotEmpty)
          .toList();
      final membershipPhone =
          (membershipData['phone'] as String?)?.trim().isNotEmpty == true
              ? (membershipData['phone'] as String).trim()
              : null;
      final membershipDni =
          (membershipData['dni'] as String?)?.trim().isNotEmpty == true
              ? (membershipData['dni'] as String).trim()
              : null;

      unawaited(
        ensureUserDocuments(
          user,
          microfinancieraId: microfinancieraId,
          membershipId: membershipDoc.id,
          roles: membershipRoles,
          phone: membershipPhone,
          dni: membershipDni,
        ),
      );

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
    required String microfinancieraId,
    List<String> roles = const ['analyst'],
  }) async {
    try {
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

      final microfinancieraDoc = await _firestore
          .collection('microfinancieras')
          .doc(microfinancieraId)
          .get();

      if (!microfinancieraDoc.exists) {
        throw PlatformException(
          code: 'microfinanciera-not-found',
          message: 'La microfinanciera seleccionada no existe',
        );
      }

      final microfinancieraData = microfinancieraDoc.data()!;
      if (microfinancieraData['isActive'] != true) {
        throw PlatformException(
          code: 'microfinanciera-inactive',
          message: 'La microfinanciera seleccionada no está activa',
        );
      }

      final normalizedRoles = roles.isEmpty ? const ['customer'] : roles;

      final missingRoles = <String>[];
      for (final roleId in normalizedRoles) {
        final roleSnapshot = await microfinancieraDoc.reference
            .collection('roles')
            .doc(roleId)
            .get();
        if (!roleSnapshot.exists) {
          missingRoles.add(roleId);
        }
      }

      if (missingRoles.isNotEmpty) {
        throw PlatformException(
          code: 'role-not-found',
          message:
              'Los roles ${missingRoles.join(', ')} no existen en la microfinanciera seleccionada',
        );
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

      final trimmedFirstName = firstName.trim();
      final trimmedLastName = lastName.trim();
      final trimmedPhone = phone.trim();
      final trimmedDni = dni.trim();
      final displayName = '$trimmedFirstName $trimmedLastName'.trim();
      final serverTimestamp = FieldValue.serverTimestamp();

      final usersCollection = _firestore
          .collection('microfinancieras')
          .doc(microfinancieraId)
          .collection('users');

      final userData = <String, dynamic>{
        'userId': user.uid,
        'mfId': microfinancieraId,
        'email': email,
        'displayName': displayName.isNotEmpty ? displayName : null,
        'photoUrl': user.photoURL,
        'linkedProviders': ['password'],
        'roles': normalizedRoles,
        'primaryRoleId': normalizedRoles.first,
        'status': 'active',
        'createdAt': serverTimestamp,
        'lastLoginAt': serverTimestamp,
        'phone': trimmedPhone.isNotEmpty ? trimmedPhone : null,
        'dni': trimmedDni.isNotEmpty ? trimmedDni : null,
        'firstName': trimmedFirstName.isNotEmpty ? trimmedFirstName : null,
        'lastName': trimmedLastName.isNotEmpty ? trimmedLastName : null,
      };

      await usersCollection.doc(user.uid).set(userData);

      if (normalizedRoles.contains('customer')) {
        final customersCollection = _firestore
            .collection('microfinancieras')
            .doc(microfinancieraId)
            .collection('customers');

        final normalizedFullName = displayName.isNotEmpty
            ? displayName
            : email.split('@').first;

        final searchKeys = <String>{
          if (trimmedFirstName.isNotEmpty) trimmedFirstName.toLowerCase(),
          if (trimmedLastName.isNotEmpty) trimmedLastName.toLowerCase(),
          if (normalizedFullName.isNotEmpty) normalizedFullName.toLowerCase(),
          if (trimmedDni.isNotEmpty) trimmedDni,
          if (trimmedPhone.isNotEmpty) trimmedPhone,
          email.toLowerCase(),
        }..removeWhere((value) => value.isEmpty);

        final customerData = <String, dynamic>{
          'mfId': microfinancieraId,
          'userId': user.uid,
          'personType': 'natural',
          'docType': 'dni',
          'docNumber': trimmedDni.isNotEmpty ? trimmedDni : null,
          'firstName': trimmedFirstName.isNotEmpty ? trimmedFirstName : null,
          'lastName': trimmedLastName.isNotEmpty ? trimmedLastName : null,
          'fullName': normalizedFullName,
          'phone': trimmedPhone.isNotEmpty ? trimmedPhone : null,
          'email': email,
          'searchKeys': searchKeys.toList(),
          'isActive': true,
          'createdAt': serverTimestamp,
          'createdBy': user.uid,
          'primaryRoleId': normalizedRoles.first,
        };

        await customersCollection.doc(user.uid).set(customerData);
      }

      await _ensureWorkerRecordForUser(
        microfinancieraRef: microfinancieraDoc.reference,
        user: user,
        roles: normalizedRoles,
        displayName: displayName,
        email: email,
        phone: trimmedPhone.isNotEmpty ? trimmedPhone : null,
        dni: trimmedDni.isNotEmpty ? trimmedDni : null,
      );

      await user.updateDisplayName(displayName);

      await ensureUserDocuments(
        user,
        firstName: trimmedFirstName,
        lastName: trimmedLastName,
        photoUrl: user.photoURL,
        microfinancieraId: microfinancieraId,
        membershipId: user.uid,
        roles: normalizedRoles,
        phone: trimmedPhone.isNotEmpty ? trimmedPhone : null,
        dni: trimmedDni.isNotEmpty ? trimmedDni : null,
      );

      return credential;
    } on FirebaseAuthException catch (error, stackTrace) {
      _logError('registerWithEmailAndPassword', error, stackTrace);
      rethrow;
    } catch (error, stackTrace) {
      _logError('registerWithEmailAndPassword', error, stackTrace);
      rethrow;
    }
  }

  Future<UserCredential?> signInWithGoogle({
    required String microfinancieraId,
    List<String> roles = const ['analyst'],
  }) async {
    try {
      if (kIsWeb) {
        final googleProvider = GoogleAuthProvider()..addScope('email');
        final credential = await _auth.signInWithPopup(googleProvider);
        final user = credential.user;
        if (user != null) {
          final assignedRoles = await _ensureMembershipForSocialSignIn(
            user: user,
            microfinancieraId: microfinancieraId,
            roles: roles,
            provider: 'google',
          );
          unawaited(
            ensureUserDocuments(
              user,
              microfinancieraId: microfinancieraId,
              membershipId: user.uid,
              roles: assignedRoles,
              phone: user.phoneNumber,
              dni: null,
            ),
          );
        }
        return credential;
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
        final assignedRoles = await _ensureMembershipForSocialSignIn(
          user: user,
          microfinancieraId: microfinancieraId,
          roles: roles,
          provider: 'google',
        );
        unawaited(
          ensureUserDocuments(
            user,
            microfinancieraId: microfinancieraId,
            membershipId: user.uid,
            roles: assignedRoles,
            phone: user.phoneNumber,
            dni: null,
          ),
        );
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

  Future<List<String>> _ensureMembershipForSocialSignIn({
    required User user,
    required String microfinancieraId,
    required List<String> roles,
    required String provider,
  }) async {
    final microfinancieraRef =
        _firestore.collection('microfinancieras').doc(microfinancieraId);
    final microfinancieraSnapshot = await microfinancieraRef.get();

    if (!microfinancieraSnapshot.exists) {
      throw PlatformException(
        code: 'microfinanciera-not-found',
        message: 'La microfinanciera seleccionada no existe',
      );
    }

    final microData = microfinancieraSnapshot.data() ?? <String, dynamic>{};
    if (microData['isActive'] != true) {
      throw PlatformException(
        code: 'microfinanciera-inactive',
        message: 'La microfinanciera seleccionada no está activa',
      );
    }

    final newRoles = await _resolveRolesForMembership(
      microfinancieraRef: microfinancieraRef,
      requestedRoles: roles,
    );

    final usersCollection = microfinancieraRef.collection('users');
    final membershipRef = usersCollection.doc(user.uid);
    final membershipSnapshot = await membershipRef.get();
    final now = FieldValue.serverTimestamp();

    final trimmedDisplayName = user.displayName?.trim();
    final trimmedEmail = user.email?.trim();
    final providerKey = provider.trim().isNotEmpty ? provider.trim() : 'google';

    if (!membershipSnapshot.exists) {
      final membershipData = <String, dynamic>{
        'userId': user.uid,
        'mfId': microfinancieraId,
        'email': trimmedEmail,
        'displayName':
            trimmedDisplayName != null && trimmedDisplayName.isNotEmpty
                ? trimmedDisplayName
                : null,
        'photoUrl': user.photoURL,
        'linkedProviders': [providerKey],
        'roles': newRoles,
        'primaryRoleId': newRoles.first,
        'status': 'active',
        'createdAt': now,
        'lastLoginAt': now,
        'phone': user.phoneNumber,
        'dni': null,
      };

      await membershipRef.set(membershipData);
      await _ensureCustomerRecordForUser(
        microfinancieraRef: microfinancieraRef,
        user: user,
        roles: newRoles,
        displayName: trimmedDisplayName ?? user.displayName,
        email: trimmedEmail ?? user.email,
        phone: user.phoneNumber,
        dni: null,
      );
      await _ensureWorkerRecordForUser(
        microfinancieraRef: microfinancieraRef,
        user: user,
        roles: newRoles,
        displayName: trimmedDisplayName ?? user.displayName,
        email: trimmedEmail ?? user.email,
        phone: user.phoneNumber,
        dni: null,
      );
      return newRoles;
    }

    final membershipData = membershipSnapshot.data() ?? <String, dynamic>{};
    final mergedRoles = (membershipData['roles'] as List<dynamic>? ?? [])
        .map((role) => role.toString())
        .where((role) => role.isNotEmpty)
        .toSet()
        .toList();

    final providerSet = (membershipData['linkedProviders'] as List<dynamic>? ?? [])
        .map((value) => value.toString())
        .where((value) => value.isNotEmpty)
        .toSet()
      ..add(providerKey);

    final existingRolesList = (membershipData['roles'] as List<dynamic>? ?? [])
        .map((value) => value.toString())
        .where((value) => value.isNotEmpty)
        .toList();

    final roleSet = existingRolesList.toSet();
    for (final role in newRoles) {
      if (roleSet.add(role)) {
        existingRolesList.add(role);
      }
    }

    final mergedRolesFinal = existingRolesList.isEmpty
        ? List<String>.from(newRoles)
        : existingRolesList;

    if (mergedRolesFinal.isEmpty) {
      mergedRolesFinal.add('analyst');
    }

    final existingPrimary = (membershipData['primaryRoleId'] as String?)?.trim();
    final resolvedPrimary =
        (existingPrimary != null && existingPrimary.isNotEmpty)
            ? existingPrimary
            : mergedRolesFinal.first;

    final existingStatus = (membershipData['status'] as String?)?.trim();
    final resolvedStatus =
        (existingStatus != null && existingStatus.isNotEmpty)
            ? existingStatus
            : 'active';

    final resolvedDisplayName =
        trimmedDisplayName?.isNotEmpty == true
            ? trimmedDisplayName
            : (membershipData['displayName'] as String?) ?? user.displayName;
    final resolvedEmail =
        trimmedEmail?.isNotEmpty == true
            ? trimmedEmail
            : (membershipData['email'] as String?) ?? user.email;
    final resolvedPhone =
        user.phoneNumber ?? (membershipData['phone'] as String?);
    final resolvedDni = (membershipData['dni'] as String?);

    final updates = <String, dynamic>{
      'userId': user.uid,
      'mfId': microfinancieraId,
      'linkedProviders': providerSet.toList(),
      'roles': mergedRoles,
      'primaryRoleId': resolvedPrimary,
      'status': resolvedStatus,
      'lastLoginAt': now,
      'updatedAt': now,
      if (resolvedEmail != null && resolvedEmail.isNotEmpty) 'email': resolvedEmail,
      if (resolvedDisplayName != null && resolvedDisplayName.isNotEmpty)
        'displayName': resolvedDisplayName,
      if (resolvedPhone != null && resolvedPhone.isNotEmpty) 'phone': resolvedPhone,
      if (resolvedDni != null && resolvedDni.trim().isNotEmpty)
        'dni': resolvedDni.trim(),
    };

    final photoUrl = user.photoURL;
    if (photoUrl != null && photoUrl.isNotEmpty) {
      updates['photoUrl'] = photoUrl;
    }

    await membershipRef.set(updates, SetOptions(merge: true));
    await _ensureCustomerRecordForUser(
      microfinancieraRef: microfinancieraRef,
      user: user,
      roles: mergedRoles,
      displayName: resolvedDisplayName ?? user.displayName,
      email: resolvedEmail,
      phone: resolvedPhone,
      dni: resolvedDni,
    );
    await _ensureWorkerRecordForUser(
      microfinancieraRef: microfinancieraRef,
      user: user,
      roles: mergedRoles,
      displayName: resolvedDisplayName ?? user.displayName,
      email: resolvedEmail,
      phone: resolvedPhone,
      dni: resolvedDni,
    );
    return mergedRoles;
  }

  Future<List<String>> _resolveRolesForMembership({
    required DocumentReference<Map<String, dynamic>> microfinancieraRef,
    required List<String> requestedRoles,
  }) async {
    final rolesCollection = microfinancieraRef.collection('roles');
    final trimmedRoles = requestedRoles
        .map((role) => role.trim())
        .where((role) => role.isNotEmpty)
        .toList();

    final desiredRoles = trimmedRoles.isEmpty
        ? <String>['analyst']
        : trimmedRoles.toSet().toList();

    final resolvedRoles = <String>[];
    for (final roleId in desiredRoles) {
      final roleSnapshot = await rolesCollection.doc(roleId).get();
      if (roleSnapshot.exists) {
        resolvedRoles.add(roleId);
      }
    }

    if (resolvedRoles.isNotEmpty) {
      return resolvedRoles;
    }

    final defaultsDoc = await microfinancieraRef
        .collection('_meta')
        .doc('defaults')
        .get();
    final defaultsData = defaultsDoc.data() ?? <String, dynamic>{};

    final fallbackRoleIds = <String?>[
      defaultsData['defaultAnalystRoleId'] as String?,
      defaultsData['defaultCustomerRoleId'] as String?,
    ];

    for (final fallbackRoleId in fallbackRoleIds) {
      final fallbackId = fallbackRoleId?.trim();
      if (fallbackId == null || fallbackId.isEmpty) continue;
      final fallbackSnapshot = await rolesCollection.doc(fallbackId).get();
      if (fallbackSnapshot.exists) {
        return [fallbackId];
      }
    }

    final analystSnapshot = await rolesCollection.doc('analyst').get();
    if (analystSnapshot.exists) {
      return ['analyst'];
    }

    final customerSnapshot = await rolesCollection.doc('customer').get();
    if (customerSnapshot.exists) {
      return ['customer'];
    }

    return desiredRoles.isNotEmpty ? desiredRoles : <String>['analyst'];
  }

  Future<void> _ensureCustomerRecordForUser({
    required DocumentReference<Map<String, dynamic>> microfinancieraRef,
    required User user,
    required List<String> roles,
    String? displayName,
    String? email,
    String? phone,
    String? dni,
  }) async {
    try {
      final normalizedRoles = roles
          .map((role) => role.trim())
          .where((role) => role.isNotEmpty)
          .toList();

      if (!normalizedRoles.contains('customer')) {
        return;
      }

      final customersCollection = microfinancieraRef.collection('customers');
      final customerRef = customersCollection.doc(user.uid);
      final existingSnapshot = await customerRef.get();
      final timestamp = FieldValue.serverTimestamp();

      final resolvedDisplayName = () {
        final explicit = displayName?.trim();
        if (explicit != null && explicit.isNotEmpty) {
          return explicit;
        }
        final emailFallback = email?.split('@').first;
        if (emailFallback != null && emailFallback.isNotEmpty) {
          return emailFallback;
        }
        return user.displayName?.trim().isNotEmpty == true
            ? user.displayName!.trim()
            : 'Usuario';
      }();

      final resolvedEmail = email?.trim();
      final resolvedPhone = phone?.trim();
      final resolvedDni = dni?.trim();

      final nameParts = _resolveNames(
        resolvedDisplayName,
        explicitFirstName: null,
        explicitLastName: null,
      );

      final searchKeys = <String>{
        if (nameParts.firstName != null)
          nameParts.firstName!.toLowerCase(),
        if (nameParts.lastName != null)
          nameParts.lastName!.toLowerCase(),
        resolvedDisplayName.toLowerCase(),
        if (resolvedEmail != null) resolvedEmail.toLowerCase(),
        if (resolvedPhone != null) resolvedPhone,
        if (resolvedDni != null) resolvedDni,
      }..removeWhere((value) => value.isEmpty);

      final customerData = <String, dynamic>{
        'mfId': microfinancieraRef.id,
        'userId': user.uid,
        'firstName': nameParts.firstName,
        'lastName': nameParts.lastName,
        'fullName': resolvedDisplayName,
        'email': resolvedEmail,
        'phone': resolvedPhone,
        'searchKeys': searchKeys.toList(),
        'primaryRoleId': normalizedRoles.contains('customer')
            ? 'customer'
            : (normalizedRoles.isNotEmpty ? normalizedRoles.first : 'customer'),
        'isActive': true,
        'docType': 'dni',
        'docNumber': resolvedDni,
        'dni': resolvedDni,
      };

      if (!existingSnapshot.exists) {
        customerData['personType'] = 'natural';
        customerData['createdAt'] = timestamp;
        customerData['createdBy'] = user.uid;
        await customerRef.set(customerData);
      } else {
        customerData['updatedAt'] = timestamp;
        await customerRef.set(customerData, SetOptions(merge: true));
      }
    } catch (error, stackTrace) {
      _logError('ensureCustomerRecordForUser', error, stackTrace);
    }
  }

  Future<void> _ensureWorkerRecordForUser({
    required DocumentReference<Map<String, dynamic>> microfinancieraRef,
    required User user,
    required List<String> roles,
    String? displayName,
    String? email,
    String? phone,
    String? dni,
  }) async {
    try {
      final staffRoles = roles
          .map((role) => role.trim())
          .where((role) => role.isNotEmpty && role != 'customer')
          .toSet()
          .toList();

      final workersCollection = microfinancieraRef.collection('workers');
      final workerRef = workersCollection.doc(user.uid);
      final workerSnapshot = await workerRef.get();
      final timestamp = FieldValue.serverTimestamp();

      if (staffRoles.isEmpty) {
        if (workerSnapshot.exists) {
          await workerRef.set(
            {
              'roleIds': <String>[],
              'isActive': false,
              'updatedAt': timestamp,
            },
            SetOptions(merge: true),
          );
        }
        return;
      }

      final resolvedDisplayName = () {
        final explicit = displayName?.trim();
        if (explicit != null && explicit.isNotEmpty) {
          return explicit;
        }
        final emailFallback = email?.split('@').first;
        if (emailFallback != null && emailFallback.isNotEmpty) {
          return emailFallback;
        }
        return user.displayName?.trim().isNotEmpty == true
            ? user.displayName!.trim()
            : 'Colaborador';
      }();

      final resolvedPhone = phone?.trim();
      final resolvedRolesSet = staffRoles.toSet();

      if (!workerSnapshot.exists) {
        final workerData = <String, dynamic>{
          'mfId': microfinancieraRef.id,
          'userId': user.uid,
          'displayName': resolvedDisplayName,
          'roleIds': resolvedRolesSet.toList(),
          'isActive': true,
          'createdAt': timestamp,
          'branchId': null,
        };

        if (resolvedPhone != null && resolvedPhone.isNotEmpty) {
          workerData['phone'] = resolvedPhone;
        }
        if (dni != null && dni.trim().isNotEmpty) {
          workerData['dni'] = dni.trim();
        }
        final resolvedEmail = email?.trim();
        if (resolvedEmail != null && resolvedEmail.isNotEmpty) {
          workerData['email'] = resolvedEmail;
        }

        await workerRef.set(workerData);
        return;
      }

      final existingData = workerSnapshot.data() ?? <String, dynamic>{};
      final existingRoles = (existingData['roleIds'] as List<dynamic>? ?? [])
          .map((role) => role.toString())
          .where((role) => role.isNotEmpty)
          .toSet();
      existingRoles.addAll(resolvedRolesSet);

      final updateData = <String, dynamic>{
        'displayName': resolvedDisplayName,
        'roleIds': existingRoles.toList(),
        'isActive': true,
        'updatedAt': timestamp,
      };

      if (resolvedPhone != null && resolvedPhone.isNotEmpty) {
        updateData['phone'] = resolvedPhone;
      }
      if (dni != null && dni.trim().isNotEmpty) {
        updateData['dni'] = dni.trim();
      }
      final resolvedEmail = email?.trim();
      if (resolvedEmail != null && resolvedEmail.isNotEmpty) {
        updateData['email'] = resolvedEmail;
      }

      await workerRef.set(updateData, SetOptions(merge: true));
    } catch (error, stackTrace) {
      _logError('ensureWorkerRecordForUser', error, stackTrace);
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
    String? microfinancieraId,
    String? membershipId,
    List<String>? roles,
    String? phone,
    String? dni,
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

      if (phone != null && phone.trim().isNotEmpty) {
        userData['phone'] = phone.trim();
      }

      if (dni != null && dni.trim().isNotEmpty) {
        userData['dni'] = dni.trim();
      }

      final trimmedMfId = microfinancieraId?.trim();
      if (trimmedMfId != null && trimmedMfId.isNotEmpty) {
        userData['primaryMfId'] = trimmedMfId;
        userData['primaryMembershipId'] =
            (membershipId != null && membershipId.trim().isNotEmpty)
                ? membershipId.trim()
                : user.uid;
        if (roles != null && roles.isNotEmpty) {
          userData['primaryRoles'] = roles;
        }
        userData['recentMfIds'] = FieldValue.arrayUnion([trimmedMfId]);
      }

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

      if (phone != null && phone.trim().isNotEmpty) {
        profileData['phone'] = phone.trim();
      }

      if (dni != null && dni.trim().isNotEmpty) {
        profileData['dni'] = dni.trim();
      }

      if (trimmedMfId != null && trimmedMfId.isNotEmpty) {
        profileData['microfinancieraId'] = trimmedMfId;
        profileData['membershipId'] =
            (membershipId != null && membershipId.trim().isNotEmpty)
                ? membershipId.trim()
                : user.uid;
        if (roles != null && roles.isNotEmpty) {
          profileData['roles'] = roles;
        }
      }

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
      final usersCollection = _firestore.collection('users');
      final rootUserSnapshot = await usersCollection.doc(uid).get();
      final rootUserData = rootUserSnapshot.data();

      String? primaryMfId =
          (rootUserData?['primaryMfId'] as String?)?.trim();
      String? primaryMembershipId =
          (rootUserData?['primaryMembershipId'] as String?)?.trim();

      DocumentSnapshot<Map<String, dynamic>>? membershipDoc;
      Map<String, dynamic>? membershipData;
      DocumentReference<Map<String, dynamic>>? microfinancieraRef;
      String? microfinancieraId;

      if (primaryMfId != null && primaryMfId.isNotEmpty) {
        final candidateMicroRef =
            _firestore.collection('microfinancieras').doc(primaryMfId);
        final candidateMembershipRef = candidateMicroRef
            .collection('users')
            .doc(
              (primaryMembershipId != null && primaryMembershipId.isNotEmpty)
                  ? primaryMembershipId
                  : uid,
            );
        final candidateMembershipDoc = await candidateMembershipRef.get();
        if (candidateMembershipDoc.exists) {
          membershipDoc = candidateMembershipDoc;
          membershipData = candidateMembershipDoc.data();
          microfinancieraRef = candidateMicroRef;
          microfinancieraId = candidateMicroRef.id;
        }
      }

      if (membershipDoc == null) {
        final microfinancierasSnapshot =
            await _firestore.collection('microfinancieras').get();
        for (final microDoc in microfinancierasSnapshot.docs) {
          final candidateDoc =
              await microDoc.reference.collection('users').doc(uid).get();
          if (candidateDoc.exists) {
            membershipDoc = candidateDoc;
            membershipData = candidateDoc.data();
            microfinancieraRef = microDoc.reference;
            microfinancieraId = microDoc.id;
            break;
          }
        }
      }

      if (membershipDoc == null) {
        final membershipQuery = await _firestore
            .collectionGroup('users')
            .where('userId', isEqualTo: uid)
            .limit(1)
            .get();

        if (membershipQuery.docs.isEmpty) {
          return null;
        }

        final queryDoc = membershipQuery.docs.first;
        membershipDoc = queryDoc;
        membershipData = queryDoc.data();
        microfinancieraRef = queryDoc.reference.parent.parent;
        microfinancieraId = microfinancieraRef?.id;
      }

      microfinancieraId ??= primaryMfId;

      DocumentSnapshot<Map<String, dynamic>>? customerDoc;
      Map<String, dynamic>? customerData;
      if (microfinancieraRef != null) {
        final customerQuery = await microfinancieraRef
            .collection('customers')
            .where('userId', isEqualTo: uid)
            .limit(1)
            .get();
        if (customerQuery.docs.isNotEmpty) {
          customerDoc = customerQuery.docs.first;
          customerData = customerDoc.data();
        }
      }

      String? stringFrom(dynamic value) =>
          value is String && value.trim().isNotEmpty ? value : null;

      String? emailFrom(dynamic value) {
        final email = stringFrom(value);
        return email?.trim();
      }

      final email =
          emailFrom(membershipData!['email']) ??
          emailFrom(customerData?['email']) ??
          emailFrom(rootUserData?['email']) ??
          '';

      final displayName =
          stringFrom(customerData?['fullName']) ??
          stringFrom(membershipData['displayName']) ??
          stringFrom(rootUserData?['displayName']) ??
          (email.isNotEmpty ? email.split('@').first : '');

      final profileMap = <String, dynamic>{
        'email': email,
        'fullName': displayName,
        'photoUrl':
            stringFrom(membershipData['photoUrl']) ??
            stringFrom(customerData?['photoUrl']),
        'phone':
            stringFrom(customerData?['phone']) ??
            stringFrom(membershipData['phone']) ??
            stringFrom(rootUserData?['phone']),
        'dni':
            stringFrom(customerData?['docNumber']) ??
            stringFrom(membershipData['dni']) ??
            stringFrom(rootUserData?['dni']),
        'firstName':
            stringFrom(customerData?['firstName']) ??
            stringFrom(membershipData['firstName']),
        'lastName':
            stringFrom(customerData?['lastName']) ??
            stringFrom(membershipData['lastName']),
        'createdAt': membershipData['createdAt'] ?? customerData?['createdAt'],
        'updatedAt': membershipData['updatedAt'] ?? customerData?['updatedAt'],
        'lastLoginAt': membershipData['lastLoginAt'],
        'microfinancieraId': microfinancieraId,
        'membershipId': membershipDoc.id,
        'customerId': customerDoc?.id,
        'roles': membershipData['roles'] ?? rootUserData?['primaryRoles'],
      };

      return UserProfile.fromMap(profileMap, uid);
    } catch (error, stackTrace) {
      _logError('getUserProfile', error, stackTrace);
      return null;
    }
  }

  Stream<UserProfile?> watchUserProfile(String uid) {
    final controller = StreamController<UserProfile?>();
    StreamSubscription<QuerySnapshot<Map<String, dynamic>>>?
    membershipSubscription;
    StreamSubscription<QuerySnapshot<Map<String, dynamic>>>?
    customerSubscription;

    Future<void> emitProfile() async {
      try {
        final profile = await getUserProfile(uid);
        if (!controller.isClosed) {
          controller.add(profile);
        }
      } catch (error, stackTrace) {
        _logError('watchUserProfile.emitProfile', error, stackTrace);
      }
    }

    controller.onListen = () {
      emitProfile();

      membershipSubscription = _firestore
          .collectionGroup('users')
          .where('userId', isEqualTo: uid)
          .limit(1)
          .snapshots()
          .listen(
            (_) => emitProfile(),
            onError: (error, stackTrace) =>
                _logError('watchUserProfile.users', error, stackTrace),
          );

      customerSubscription = _firestore
          .collectionGroup('customers')
          .where('userId', isEqualTo: uid)
          .limit(1)
          .snapshots()
          .listen(
            (_) => emitProfile(),
            onError: (error, stackTrace) =>
                _logError('watchUserProfile.customers', error, stackTrace),
          );
    };

    controller.onCancel = () async {
      await membershipSubscription?.cancel();
      await customerSubscription?.cancel();
    };

    return controller.stream;
  }

  Future<void> updateUserProfile({
    required String uid,
    required String microfinancieraId,
    required String membershipId,
    String? customerId,
    required Map<String, dynamic> updates,
  }) async {
    String? trimmedString(dynamic value) {
      if (value == null) return null;
      final stringValue = value.toString().trim();
      return stringValue.isEmpty ? null : stringValue;
    }

    final usersCollection = _firestore
        .collection('microfinancieras')
        .doc(microfinancieraId)
        .collection('users');

    final membershipRef = usersCollection.doc(membershipId);
    final membershipSnapshot = await membershipRef.get();
    if (!membershipSnapshot.exists) {
      throw Exception('Membresía no encontrada para el usuario');
    }

    final membershipData = membershipSnapshot.data() ?? <String, dynamic>{};

    final trimmedFirstName = trimmedString(updates['firstName']);
    final trimmedLastName = trimmedString(updates['lastName']);
    final trimmedFullName =
        trimmedString(
          updates['fullName'] ??
              [
                trimmedFirstName,
                trimmedLastName,
              ].where((part) => part != null && part.isNotEmpty).join(' '),
        ) ??
        trimmedString(membershipData['displayName']);
    final trimmedPhotoUrl = trimmedString(updates['photoUrl']);
    final trimmedPhone = trimmedString(updates['phone']);
    final trimmedDni = trimmedString(updates['dni']);

    final existingFirstName = trimmedString(membershipData['firstName']);
    final existingLastName = trimmedString(membershipData['lastName']);
    final existingPhone = trimmedString(membershipData['phone']);
    final existingDni = trimmedString(membershipData['dni']);
    final existingDisplayName = trimmedString(membershipData['displayName']);

    final resolvedFirstName = trimmedFirstName ?? existingFirstName;
    final resolvedLastName = trimmedLastName ?? existingLastName;
    final resolvedPhone =
        updates.containsKey('phone') ? trimmedPhone : existingPhone;
    final resolvedDni = updates.containsKey('dni') ? trimmedDni : existingDni;
    final resolvedFullName =
        trimmedFullName ?? existingDisplayName ??
        [resolvedFirstName, resolvedLastName]
            .where((value) => value != null && value.isNotEmpty)
            .join(' ');
    final resolvedPhotoUrl =
        updates.containsKey('photoUrl') ? trimmedPhotoUrl : trimmedString(membershipData['photoUrl']);

    final membershipUpdates = <String, dynamic>{};
    if (resolvedFullName.isNotEmpty) {
      membershipUpdates['displayName'] = resolvedFullName;
    }
    if (updates.containsKey('photoUrl')) {
      membershipUpdates['photoUrl'] = resolvedPhotoUrl;
    }
    if (resolvedFirstName != null) {
      membershipUpdates['firstName'] = resolvedFirstName;
    }
    if (resolvedLastName != null) {
      membershipUpdates['lastName'] = resolvedLastName;
    }
    if (updates.containsKey('phone')) {
      membershipUpdates['phone'] = resolvedPhone;
    }
    if (updates.containsKey('dni')) {
      membershipUpdates['dni'] = resolvedDni;
    }

    if (membershipUpdates.isNotEmpty) {
      membershipUpdates['updatedAt'] = FieldValue.serverTimestamp();
      await membershipRef.update(membershipUpdates);

      if (membershipUpdates.containsKey('displayName') &&
          _auth.currentUser != null) {
        await _auth.currentUser!.updateDisplayName(
          membershipUpdates['displayName'] as String?,
        );
      }
    }

    DocumentReference<Map<String, dynamic>>? customerRef;
    DocumentSnapshot<Map<String, dynamic>>? customerSnapshot;
    if (customerId != null) {
      customerRef = _firestore
          .collection('microfinancieras')
          .doc(microfinancieraId)
          .collection('customers')
          .doc(customerId);
      customerSnapshot = await customerRef.get();
    } else {
      final customerQuery = await _firestore
          .collection('microfinancieras')
          .doc(microfinancieraId)
          .collection('customers')
          .where('userId', isEqualTo: uid)
          .limit(1)
          .get();
      if (customerQuery.docs.isNotEmpty) {
        customerSnapshot = customerQuery.docs.first;
        customerRef = customerSnapshot.reference;
      }
    }

    if (customerRef != null) {
      final existingCustomerData =
          customerSnapshot?.data() ?? <String, dynamic>{};

      final customerFirstName =
          trimmedFirstName ??
          trimmedString(existingCustomerData['firstName']) ??
          resolvedFirstName;
      final customerLastName =
          trimmedLastName ??
          trimmedString(existingCustomerData['lastName']) ??
          resolvedLastName;
      final customerFullName =
          trimmedFullName ??
          trimmedString(existingCustomerData['fullName']) ??
          resolvedFullName;
      final customerPhone = updates.containsKey('phone')
          ? trimmedPhone
          : trimmedString(existingCustomerData['phone']) ?? resolvedPhone;
      final customerDocNumber = updates.containsKey('dni')
          ? trimmedDni
          : trimmedString(existingCustomerData['docNumber']) ?? resolvedDni;
      final resolvedEmail = trimmedString(membershipData['email']);  // Definir resolvedEmail
      final customerEmail = resolvedEmail ?? trimmedString(existingCustomerData['email']) ?? '';  // Definir customerEmail

      final customerUpdates = <String, dynamic>{
        'updatedAt': FieldValue.serverTimestamp(),
        'firstName': customerFirstName,
        'lastName': customerLastName,
        'fullName': customerFullName,
        'phone': customerPhone,
        'docNumber': customerDocNumber,
        'email': customerEmail,
      };

      final searchKeys = <String>{
        if (customerFirstName != null && customerFirstName.isNotEmpty)
          customerFirstName.toLowerCase(),
        if (customerLastName != null && customerLastName.isNotEmpty)
          customerLastName.toLowerCase(),
        if (customerFullName.isNotEmpty)
          customerFullName.toLowerCase(),
        if (customerDocNumber != null && customerDocNumber.isNotEmpty)
          customerDocNumber,
        if (customerPhone != null && customerPhone.isNotEmpty)
          customerPhone,
        if (customerEmail.isNotEmpty)
          customerEmail.toLowerCase(),
      }..removeWhere((value) => value.trim().isEmpty);

      customerUpdates['searchKeys'] = searchKeys.toList();

      await customerRef.update(customerUpdates);
    }

    final resolvedEmail = trimmedString(membershipData['email']);  // Definir resolvedEmail

    final roles = (membershipData['roles'] as List<dynamic>? ?? []).map((e) => e.toString()).where((e) => e.isNotEmpty).toList();  // Definir roles correctamente
    final staffRoles = roles.where((role) => role != 'customer').toSet().toList();

    final microfinancieraRef = _firestore.collection('microfinancieras').doc(microfinancieraId);  // Definir microfinancieraRef

    final workersCollection = microfinancieraRef.collection('workers');
    final workerRef = workersCollection.doc(uid);
    final workerSnapshot = await workerRef.get();
    final workerTimestamp = FieldValue.serverTimestamp();

    if (staffRoles.isEmpty) {
      if (workerSnapshot.exists) {
        await workerRef.set(
          {
            'roleIds': <String>[],
            'isActive': false,
            'updatedAt': workerTimestamp,
          },
          SetOptions(merge: true),
        );
      }
    } else {
      final baseEmail = resolvedEmail ?? '';
      final workerData = <String, dynamic>{
        'mfId': microfinancieraId,
        'userId': uid,
        'displayName': resolvedFullName,
        'roleIds': staffRoles,
        'isActive': true,
        'phone': resolvedPhone,
        'dni': resolvedDni,
        'email': baseEmail,
        'updatedAt': workerTimestamp,
      };

      if (!workerSnapshot.exists) {
        workerData['createdAt'] = workerTimestamp;
      }

      await workerRef.set(workerData, SetOptions(merge: true));
    }

    final resolvedProfileFirstName = resolvedFirstName;
    final resolvedProfileLastName = resolvedLastName;
    final resolvedProfileFullName = resolvedFullName;

    final rootUserUpdates = <String, dynamic>{
      'displayName': resolvedProfileFullName,
      'phone': resolvedPhone,
      'dni': resolvedDni,
      'photoUrl': resolvedPhotoUrl,
      'primaryMfId': microfinancieraId,
      'primaryMembershipId': membershipId,
      'primaryRoles': roles,
      'recentMfIds': FieldValue.arrayUnion([microfinancieraId]),
      'updatedAt': FieldValue.serverTimestamp(),
    };

    await _firestore.collection('users').doc(uid).set(
          rootUserUpdates,
          SetOptions(merge: true),
        );

    final rootProfileUpdates = <String, dynamic>{
      'firstName': resolvedProfileFirstName,
      'lastName': resolvedProfileLastName,
      'fullName': resolvedProfileFullName,
      'phone': resolvedPhone,
      'dni': resolvedDni,
      'photoUrl': resolvedPhotoUrl,
      'microfinancieraId': microfinancieraId,
      'membershipId': membershipId,
      'updatedAt': FieldValue.serverTimestamp(),
    };

    await _firestore.collection('user_profiles').doc(uid).set(
          rootProfileUpdates,
          SetOptions(merge: true),
        );
  }

  Future<bool> checkEmailExists(String email) async {
    try {
      // Check across all microfinancieras for email uniqueness
      final microfinancieras = await _firestore
          .collection('microfinancieras')
          .get();

      for (final mfDoc in microfinancieras.docs) {
        final query = await _firestore
            .collection('microfinancieras')
            .doc(mfDoc.id)
            .collection('users')
            .where('email', isEqualTo: email)
            .get();

        if (query.docs.isNotEmpty) {
          return true;
        }
      }

      return false;
    } catch (error, stackTrace) {
      _logError('checkEmailExists', error, stackTrace);
      return false;
    }
  }

  Future<bool> checkDniExists(String dni) async {
    try {
      if (dni.isEmpty) return false;

      // Check across all microfinancieras for DNI uniqueness
      final microfinancieras = await _firestore
          .collection('microfinancieras')
          .get();

      for (final mfDoc in microfinancieras.docs) {
        final query = await _firestore
            .collection('microfinancieras')
            .doc(mfDoc.id)
            .collection('customers')
            .where('docNumber', isEqualTo: dni)
            .get();

        if (query.docs.isNotEmpty) {
          return true;
        }
      }

      return false;
    } catch (error, stackTrace) {
      _logError('checkDniExists', error, stackTrace);
      return false;
    }
  }

  Future<List<Microfinanciera>> getActiveMicrofinancieras() async {
    try {
      final query = await _firestore
          .collection('microfinancieras')
          .where('isActive', isEqualTo: true)
          .orderBy('name')
          .get();

      return query.docs
          .map((doc) => Microfinanciera.fromFirestore(doc))
          .toList();
    } catch (error, stackTrace) {
      _logError('getActiveMicrofinancieras', error, stackTrace);
      return [];
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
