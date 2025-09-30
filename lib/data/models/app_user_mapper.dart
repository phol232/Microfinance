import 'package:firebase_auth/firebase_auth.dart' as firebase;

import '../../domain/entities/app_user.dart';

class AppUserMapper {
  const AppUserMapper._();

  static AppUser? fromFirebaseUser(firebase.User? user) {
    if (user == null) return null;
    return AppUser(
      uid: user.uid,
      email: user.email,
      displayName: user.displayName,
      photoUrl: user.photoURL,
      isAnonymous: user.isAnonymous,
      providerIds: user.providerData.map((e) => e.providerId).toList(growable: false),
    );
  }
}
