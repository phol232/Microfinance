import 'package:firebase_auth/firebase_auth.dart';
import 'user_profile.dart';

/// Resultado del proceso de login que incluye todas las credenciales
/// y datos del usuario para evitar consultas adicionales.
class LoginResult {
  final UserCredential credential;
  final UserProfile profile;
  final String membershipId;
  final String microfinancieraId;

  const LoginResult({
    required this.credential,
    required this.profile,
    required this.membershipId,
    required this.microfinancieraId,
  });

  /// Usuario de Firebase Auth
  User? get user => credential.user;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LoginResult &&
          runtimeType == other.runtimeType &&
          credential == other.credential &&
          profile == other.profile &&
          membershipId == other.membershipId &&
          microfinancieraId == other.microfinancieraId;

  @override
  int get hashCode =>
      credential.hashCode ^
      profile.hashCode ^
      membershipId.hashCode ^
      microfinancieraId.hashCode;

  @override
  String toString() =>
      'LoginResult(user: ${user?.uid}, microfinancieraId: $microfinancieraId, membershipId: $membershipId)';
}
