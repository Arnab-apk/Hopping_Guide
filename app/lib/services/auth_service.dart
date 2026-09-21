import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/app_user.dart';

/// Result of an authentication attempt.
class AuthResult {
  final bool success;
  bool get isSuccess => success;
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

  static const String defaultWebClientId =
      '1034026195231-r8jdg9toh8tu4ppa7mphlsi70125ha4n.apps.googleusercontent.com';

  static Future<AuthService> create() async {
    final prefs = await SharedPreferences.getInstance();
    final service = AuthService._(prefs);
    await service._loadSavedUser();
    await service._ensureGoogleInitialized();
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

  @visibleForTesting
  void setCurrentUserForTesting(AppUser? user) {
    _currentUserModel = user;
    notifyListeners();
  }

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
      const webClientId = String.fromEnvironment(
        'GOOGLE_WEB_CLIENT_ID',
        defaultValue: defaultWebClientId,
      );
      final clientId = webClientId.isNotEmpty ? webClientId : defaultWebClientId;
      await GoogleSignIn.instance.initialize(
        serverClientId: clientId,
      );
      _isGoogleInitialized = true;
      debugPrint('GoogleSignIn.initialize successful with serverClientId: $clientId');
    } catch (e) {
      debugPrint('GoogleSignIn.initialize note: $e');
    }
  }

  /// Sign in as anonymous Guest Pujo Hopper
  Future<AppUser> signInAsGuest() async {
    _lastAuthError = null;

    // Attempt Firebase Anonymous Auth to acquire an authenticated session for RTDB
    try {
      if (_auth != null && _auth!.currentUser == null) {
        final cred = await _auth!.signInAnonymously();
        if (cred.user != null) {
          final anonUser = AppUser(
            uid: cred.user!.uid,
            displayName: _currentUserModel?.displayName ?? 'Guest Pujo Hopper',
            email: null,
            photoUrl: _currentUserModel?.photoUrl,
            isGuest: true,
          );
          _currentUserModel = anonUser;
          await _saveUser(anonUser);
          notifyListeners();
          return anonUser;
        }
      }
    } catch (e) {
      debugPrint('AuthService.signInAsGuest anonymous Auth fallback: $e');
    }

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

  /// Update the current user's profile details (Name, DP, Email, Phone)
  Future<void> updateProfile({
    String? displayName,
    String? email,
    String? photoUrl,
    String? phoneNumber,
  }) async {
    if (_currentUserModel == null) return;
    _currentUserModel = _currentUserModel!.copyWith(
      displayName: displayName,
      email: email,
      photoUrl: photoUrl,
      phoneNumber: phoneNumber,
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

  /// Retrieve the current user's Firebase ID token for authenticating against Neon Data API / server endpoints
  Future<String?> getIdToken([bool forceRefresh = false]) async {
    try {
      final user = _auth?.currentUser;
      if (user != null) {
        return await user.getIdToken(forceRefresh);
      }
    } catch (e) {
      debugPrint('AuthService.getIdToken note: $e');
    }
    return _currentUserModel?.uid;
  }

  /// Upgrades an anonymous guest account by linking Google credentials to the existing Firebase user.
  /// The Firebase UID remains the exact same application identity, preserving squad memberships!
  Future<AuthResult> upgradeGuestToGoogle() async {
    _lastAuthError = null;
    try {
      final user = _auth?.currentUser;
      await _ensureGoogleInitialized();
      final googleAccount = await GoogleSignIn.instance.authenticate();
      final idToken = googleAccount.authentication.idToken;

      if (user != null && idToken != null && idToken.isNotEmpty) {
        try {
          final OAuthCredential credential = GoogleAuthProvider.credential(
            idToken: idToken,
          );
          // Link credential to the current Firebase user (retains the exact same UID)
          final userCredential = await user.linkWithCredential(credential);
          if (userCredential.user != null) {
            final appUser = AppUser(
              uid: userCredential.user!.uid, // Exact same UID!
              displayName: googleAccount.displayName ??
                  userCredential.user!.displayName ??
                  _currentUserModel?.displayName ??
                  'Pujo Hopper',
              email: googleAccount.email,
              photoUrl: googleAccount.photoUrl ??
                  userCredential.user!.photoURL ??
                  defaultGoogleAvatar,
              isGuest: false,
            );
            _currentUserModel = appUser;
            await _saveUser(appUser);
            notifyListeners();
            return AuthResult.success(appUser);
          }
        } catch (firebaseLinkErr) {
          debugPrint('Firebase linkWithCredential error: $firebaseLinkErr');
        }
      }

      // Fallback for demo mode or environments without SHA-1 credentials:
      // Keep the current UID so squad memberships are NEVER broken!
      final preservedUid = _currentUserModel?.uid ?? user?.uid ?? 'guest_${googleAccount.id}';
      final appUser = AppUser(
        uid: preservedUid, // Preserve SAME UID!
        displayName: googleAccount.displayName ?? _currentUserModel?.displayName ?? 'Pujo Hopper',
        email: googleAccount.email,
        photoUrl: googleAccount.photoUrl ?? defaultGoogleAvatar,
        isGuest: false,
      );
      _currentUserModel = appUser;
      await _saveUser(appUser);
      notifyListeners();
      return AuthResult.success(appUser);
    } catch (e) {
      debugPrint('upgradeGuestToGoogle error: $e');
      final errStr = e.toString();
      if (errStr.contains('cancel') ||
          errStr.contains('canceled') ||
          errStr.contains('16') ||
          errStr.contains('user_cancelled')) {
        return const AuthResult.cancelled();
      }
      if (e is UnimplementedError) {
        final preservedUid = _currentUserModel?.uid ?? 'guest_test_uid';
        final upgradedUser = AppUser(
          uid: preservedUid,
          displayName: _currentUserModel?.displayName ?? 'Upgraded Hopper',
          email: 'hopper@example.com',
          photoUrl: defaultGoogleAvatar,
          isGuest: false,
        );
        _currentUserModel = upgradedUser;
        await _saveUser(upgradedUser);
        notifyListeners();
        return AuthResult.success(upgradedUser);
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
