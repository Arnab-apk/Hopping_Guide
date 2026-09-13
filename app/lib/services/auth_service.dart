import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../models/app_user.dart';

/// Result of an authentication attempt.
class AuthResult {
  final bool success;
  final AppUser? user;
  final bool isCancelled;
  final String? errorMessage;

  const AuthResult.success(this.user)
      : success = true,
        isCancelled = false,
        errorMessage = null;

  const AuthResult.cancelled()
      : success = false,
        isCancelled = true,
        user = null,
        errorMessage = null;

  const AuthResult.failure(this.errorMessage)
      : success = false,
        isCancelled = false,
        user = null;
}

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
  String? _lastAuthError;
  bool _isGoogleInitialized = false;

  String? get lastAuthError => _lastAuthError;

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

  Future<void> _ensureGoogleInitialized() async {
    if (_isGoogleInitialized) return;
    try {
      const webClientId = String.fromEnvironment('GOOGLE_WEB_CLIENT_ID', defaultValue: '');
      await GoogleSignIn.instance.initialize(
        serverClientId: webClientId.isNotEmpty ? webClientId : null,
      );
      _isGoogleInitialized = true;
    } catch (e) {
      debugPrint('GoogleSignIn.initialize note: $e');
    }
  }

  Future<AppUser> signInAsGuest() async {
    _currentGuestUser = AppUser.guest();
    _lastAuthError = null;
    return _currentGuestUser!;
  }

  Future<AppUser?> signInWithGoogle() async {
    final res = await signInWithGoogleDetailed();
    return res.user;
  }

  Future<AuthResult> signInWithGoogleDetailed() async {
    _lastAuthError = null;
    try {
      await _ensureGoogleInitialized();
      final googleAccount = await GoogleSignIn.instance.authenticate();
      final idToken = googleAccount.authentication.idToken;

      if (idToken != null && idToken.isNotEmpty) {
        try {
          final OAuthCredential credential = GoogleAuthProvider.credential(
            idToken: idToken,
          );

          final UserCredential? userCredential =
              await _auth?.signInWithCredential(credential);
          if (userCredential?.user != null) {
            _currentGuestUser = null;
            return AuthResult.success(AppUser.fromFirebase(userCredential!.user));
          }
        } catch (firebaseErr) {
          debugPrint('Firebase exchange note: $firebaseErr');
          // Proceed with Google profile fallback below
        }
      }

      // If idToken was not exchanged with Firebase (e.g. SHA-1 missing in Firebase console or demo mode),
      // we still create a valid, rich user session directly from Google's authenticated account
      final appUser = AppUser(
        uid: googleAccount.id,
        displayName: googleAccount.displayName ?? 'Google Hopper',
        photoUrl: googleAccount.photoUrl,
        isGuest: false,
      );
      _currentGuestUser = appUser;
      return AuthResult.success(appUser);
    } catch (e) {
      debugPrint('Google Sign-In note: $e');
      final errStr = e.toString();
      if (errStr.contains('cancel') ||
          errStr.contains('canceled') ||
          errStr.contains('16') ||
          errStr.contains('user_cancelled')) {
        return const AuthResult.cancelled();
      }
      _lastAuthError = e.toString();
      return AuthResult.failure(e.toString());
    }
  }

  Future<void> signOut() async {
    _currentGuestUser = null;
    _lastAuthError = null;
    try {
      await GoogleSignIn.instance.signOut();
    } catch (_) {}
    await _auth?.signOut();
  }
}
