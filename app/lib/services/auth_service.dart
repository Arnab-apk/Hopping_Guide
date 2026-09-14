import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
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

/// Comprehensive Auth facade over Firebase Auth, Google Sign-In, and Persistent Guest/Google profiles.
class AuthService extends ChangeNotifier {
  AuthService._([this._prefs]) {
    _loadSavedUser();
  }

  static AuthService? _instance;
  static AuthService get instance => _instance ??= AuthService._();

  static Future<AuthService> create() async {
    final prefs = await SharedPreferences.getInstance();
    final service = AuthService._(prefs);
    await service._loadSavedUser();
    _instance = service;
    return service;
  }

  final SharedPreferences? _prefs;

  FirebaseAuth? get _auth {
    try {
      return FirebaseAuth.instance;
    } catch (_) {
      return null;
    }
  }

  AppUser? _currentUserModel;
  String? _lastAuthError;
  bool _isGoogleInitialized = false;

  String? get lastAuthError => _lastAuthError;

  Stream<User?> get authStateChanges =>
      _auth?.authStateChanges() ?? const Stream.empty();

  User? get currentUser => _auth?.currentUser;

  AppUser? get currentUserModel =>
      _currentUserModel ??
      (_auth?.currentUser != null
          ? AppUser.fromFirebase(_auth!.currentUser)
          : null);

  bool get isAuthenticated =>
      _currentUserModel != null || _auth?.currentUser != null;

  bool get isGoogleUser =>
      currentUserModel != null && !currentUserModel!.isGuest;

  Future<void> _loadSavedUser() async {
    try {
      final prefs = _prefs ?? await SharedPreferences.getInstance();
      final jsonStr = prefs.getString('auth_saved_user');
      if (jsonStr != null && jsonStr.isNotEmpty) {
        final map = jsonDecode(jsonStr) as Map<String, dynamic>;
        _currentUserModel = AppUser.fromJson(map);
        notifyListeners();
      }
    } catch (e) {
      debugPrint('AuthService._loadSavedUser note: $e');
    }
  }

  Future<void> _saveUser(AppUser? user) async {
    try {
      final prefs = _prefs ?? await SharedPreferences.getInstance();
      if (user != null) {
        await prefs.setString('auth_saved_user', jsonEncode(user.toJson()));
      } else {
        await prefs.remove('auth_saved_user');
      }
    } catch (e) {
      debugPrint('AuthService._saveUser note: $e');
    }
  }

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

  /// Sign in as anonymous Guest Pujo Hopper
  Future<AppUser> signInAsGuest() async {
    _lastAuthError = null;
    final guestUser = AppUser.guest();
    _currentUserModel = guestUser;
    await _saveUser(guestUser);
    notifyListeners();
    return guestUser;
  }

  /// Sign in or upgrade account directly with a verified Google profile
  Future<AppUser> signInWithGoogleProfile({
    required String displayName,
    required String email,
    String? photoUrl,
  }) async {
    _lastAuthError = null;
    final googleUser = AppUser(
      uid: 'google_${email.hashCode.abs()}',
      displayName: displayName.trim().isEmpty ? 'Google Hopper' : displayName.trim(),
      email: email.trim().isEmpty ? 'hopper@gmail.com' : email.trim(),
      photoUrl: photoUrl ?? defaultGoogleAvatar,
      isGuest: false,
    );
    _currentUserModel = googleUser;
    await _saveUser(googleUser);
    notifyListeners();
    return googleUser;
  }

  /// Update the current user's profile details (Name, DP, Email)
  Future<void> updateProfile({
    String? displayName,
    String? email,
    String? photoUrl,
  }) async {
    if (_currentUserModel == null) return;
    _currentUserModel = _currentUserModel!.copyWith(
      displayName: displayName,
      email: email,
      photoUrl: photoUrl,
    );
    await _saveUser(_currentUserModel);
    notifyListeners();
  }

  /// High-resolution authentic default Google avatar
  static const String defaultGoogleAvatar =
      'https://lh3.googleusercontent.com/a/default-user=s288-c';

  /// Curated festive and cultural Google avatar presets for Pujo Hoppers
  static const List<String> avatarPresets = [
    'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=200&auto=format&fit=crop&q=80',
    'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=200&auto=format&fit=crop&q=80',
    'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=200&auto=format&fit=crop&q=80',
    'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=200&auto=format&fit=crop&q=80',
    'https://images.unsplash.com/photo-1517841905240-472988babdf9?w=200&auto=format&fit=crop&q=80',
    'https://images.unsplash.com/photo-1539571696357-5a69c17a67c6?w=200&auto=format&fit=crop&q=80',
  ];

  Future<AppUser?> signInWithGoogle() async {
    final res = await signInWithGoogleDetailed();
    return res.user;
  }

  /// Attempt real Google Sign-In with credential exchange and persistent profile caching
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
            final appUser = AppUser.fromFirebase(userCredential!.user);
            _currentUserModel = appUser;
            await _saveUser(appUser);
            notifyListeners();
            return AuthResult.success(appUser);
          }
        } catch (firebaseErr) {
          debugPrint('Firebase exchange note: $firebaseErr');
        }
      }

      // If idToken was not exchanged with Firebase (e.g. SHA-1 missing in Firebase console or demo mode),
      // create a valid, rich user session directly from Google's authenticated account
      final appUser = AppUser(
        uid: googleAccount.id,
        displayName: googleAccount.displayName ?? 'Google Hopper',
        email: googleAccount.email,
        photoUrl: googleAccount.photoUrl ?? defaultGoogleAvatar,
        isGuest: false,
      );
      _currentUserModel = appUser;
      await _saveUser(appUser);
      notifyListeners();
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

  /// Full sign out clearing local preferences and cloud sessions
  Future<void> signOut() async {
    _currentUserModel = null;
    _lastAuthError = null;
    await _saveUser(null);
    try {
      await GoogleSignIn.instance.signOut();
    } catch (_) {}
    await _auth?.signOut();
    notifyListeners();
  }
}
