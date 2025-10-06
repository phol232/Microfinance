import '../entities/app_user.dart';
import '../entities/user_profile.dart';
import '../entities/microfinanciera.dart';

abstract class AuthRepository {
  Stream<AppUser?> authStateChanges();

  AppUser? get currentUser;

  Future<AppUser?> signInWithEmailAndPassword({
    required String email,
    required String password,
    required String microfinancieraId,
  });

  Future<AppUser?> registerWithEmailAndPassword({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    required String dni,
    required String phone,
    required String microfinancieraId,
    List<String> roles = const ['analyst'],
  });

  Future<List<Microfinanciera>> getActiveMicrofinancieras();

  Future<AppUser?> signInWithGoogle({
    required String microfinancieraId,
    List<String> roles = const ['analyst'],
  });

  Future<AppUser?> signInWithFacebook();

  Future<AppUser?> signInAnonymously();

  Future<void> signOut();

  Future<UserProfile?> fetchUserProfile(String uid);

  Stream<UserProfile?> watchUserProfile(String uid);

  Future<void> updateUserProfile({
    required String uid,
    required String microfinancieraId,
    required String membershipId,
    String? customerId,
    required Map<String, dynamic> updates,
  });

  Future<bool> checkDniExists(String dni);

  Future<bool> checkEmailExists(String email);
}
