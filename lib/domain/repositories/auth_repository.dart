import '../entities/app_user.dart';
import '../entities/user_profile.dart';

/// Abstraction for authentication related operations.
abstract class AuthRepository {
  Stream<AppUser?> authStateChanges();

  AppUser? get currentUser;

  Future<AppUser?> signInWithEmailAndPassword(String email, String password);

  Future<AppUser?> registerWithEmailAndPassword({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    required String dni,
    required String phone,
  });

  Future<AppUser?> signInWithGoogle();

  Future<AppUser?> signInWithFacebook();

  Future<AppUser?> signInAnonymously();

  Future<void> signOut();

  Future<UserProfile?> fetchUserProfile(String uid);

  Stream<UserProfile?> watchUserProfile(String uid);

  Future<void> updateUserProfile(String uid, Map<String, dynamic> updates);

  Future<bool> checkDniExists(String dni);

  Future<bool> checkEmailExists(String email);
}
