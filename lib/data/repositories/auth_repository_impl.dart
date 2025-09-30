import '../datasources/firebase_auth_datasource.dart';
import '../models/app_user_mapper.dart';
import '../../domain/entities/app_user.dart';
import '../../domain/entities/user_profile.dart';
import '../../domain/repositories/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl({required FirebaseAuthDataSource dataSource})
      : _dataSource = dataSource;

  final FirebaseAuthDataSource _dataSource;

  @override
  Stream<AppUser?> authStateChanges() {
    return _dataSource.authStateChanges.map(AppUserMapper.fromFirebaseUser);
  }

  @override
  AppUser? get currentUser => AppUserMapper.fromFirebaseUser(_dataSource.currentUser);

  @override
  Future<AppUser?> signInWithEmailAndPassword(String email, String password) async {
    final credential =
        await _dataSource.signInWithEmailAndPassword(email, password);
    return AppUserMapper.fromFirebaseUser(credential?.user);
  }

  @override
  Future<AppUser?> registerWithEmailAndPassword({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    required String dni,
    required String phone,
  }) async {
    final credential = await _dataSource.registerWithEmailAndPassword(
      email: email,
      password: password,
      firstName: firstName,
      lastName: lastName,
      dni: dni,
      phone: phone,
    );
    return AppUserMapper.fromFirebaseUser(credential?.user);
  }

  @override
  Future<AppUser?> signInWithGoogle() async {
    final credential = await _dataSource.signInWithGoogle();
    return AppUserMapper.fromFirebaseUser(credential?.user);
  }

  @override
  Future<AppUser?> signInWithFacebook() async {
    final credential = await _dataSource.signInWithFacebook();
    return AppUserMapper.fromFirebaseUser(credential?.user);
  }

  @override
  Future<AppUser?> signInAnonymously() async {
    final credential = await _dataSource.signInAnonymously();
    return AppUserMapper.fromFirebaseUser(credential?.user);
  }

  @override
  Future<void> signOut() => _dataSource.signOut();

  @override
  Future<UserProfile?> fetchUserProfile(String uid) =>
      _dataSource.getUserProfile(uid);

  @override
  Stream<UserProfile?> watchUserProfile(String uid) =>
      _dataSource.watchUserProfile(uid);

  @override
  Future<void> updateUserProfile(String uid, Map<String, dynamic> updates) =>
      _dataSource.updateUserProfile(uid, updates);

  @override
  Future<bool> checkDniExists(String dni) => _dataSource.checkDniExists(dni);

  @override
  Future<bool> checkEmailExists(String email) =>
      _dataSource.checkEmailExists(email);
}
