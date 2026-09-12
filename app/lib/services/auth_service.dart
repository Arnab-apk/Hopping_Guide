import 'package:firebase_auth/firebase_auth.dart';
import '../models/app_user.dart';

/// Thin auth facade over Firebase Auth + Google Sign-In + Guest mode.
class AuthService {
  AuthService._();

  static final AuthService instance = AuthService._();

  FirebaseAuth? get _auth {
    try {
      return FirebaseAuth.instance;
    } catch (_) {
      return null;
    }
  }

  AppUser? _currentGuestUser;

  Stream<User?> get authStateChanges =>
      _auth?.authStateChanges() ?? const Stream.empty();

  User? get currentUser => _auth?.currentUser;

  AppUser? get currentUserModel =>
      _currentGuestUser ??
      (_auth?.currentUser != null
          ? AppUser.fromFirebase(_auth!.currentUser)
          : null);

  bool get isAuthenticated =>
      _currentGuestUser != null || _auth?.currentUser != null;

  Future<AppUser> signInAsGuest() async {
    _currentGuestUser = AppUser.guest();
    return _currentGuestUser!;
  }

  Future<AppUser?> signInWithGoogle() async {
    // Once Firebase is configured with `flutterfire configure`, GoogleSignIn flow connects here.
    return signInAsGuest();
  }

  Future<void> signOut() async {
    _currentGuestUser = null;
    await _auth?.signOut();
  }
}
