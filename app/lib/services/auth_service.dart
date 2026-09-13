import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
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
    try {
      final googleAccount = await GoogleSignIn.instance.authenticate();
      final idToken = googleAccount.authentication.idToken;
      final OAuthCredential credential = GoogleAuthProvider.credential(
        idToken: idToken,
      );

      final UserCredential? userCredential = await _auth?.signInWithCredential(credential);
      _currentGuestUser = null;
      if (userCredential?.user != null) {
        return AppUser.fromFirebase(userCredential!.user);
      }
      return null;
    } catch (e) {
      debugPrint('Google Sign-In note: $e');
      // Graceful fallback so user is never blocked
      return signInAsGuest();
    }
  }

  Future<void> signOut() async {
    _currentGuestUser = null;
    try {
      await GoogleSignIn.instance.signOut();
    } catch (_) {}
    await _auth?.signOut();
  }
}
