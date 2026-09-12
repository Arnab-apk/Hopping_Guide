import 'package:firebase_auth/firebase_auth.dart';
// google_sign_in is re-added here once signInWithGoogle() is implemented.

import '../models/app_user.dart';

/// Thin auth facade over Firebase Auth + Google Sign-In (P0).
/// Swap implementations here without touching the UI.
class AuthService {
  AuthService._();

  static final AuthService instance = AuthService._();

  final FirebaseAuth _auth = FirebaseAuth.instance;

  // google_sign_in v7+ uses a singleton: call GoogleSignIn.instance.initialize()
  // before signInWithGoogle(), then GoogleSignIn.instance.authenticate().
  Stream<User?> get authStateChanges => _auth.authStateChanges();
  User? get currentUser => _auth.currentUser;

  Future<AppUser?> signInWithGoogle() async {
    // TODO(P0): implement Google Sign-In flow once Firebase is configured.
    // await GoogleSignIn.instance.initialize();
    // await GoogleSignIn.instance.authenticate();
    // final credential = GoogleAuthProvider.credential(
    //   idToken: GoogleSignIn.instance.authenticationTokens.idToken,
    //   accessToken: GoogleSignIn.instance.authenticationTokens.accessToken,
    // );
    // final user = await _auth.signInWithCredential(credential);
    // return AppUser.fromFirebase(user.user);
    throw UnimplementedError();
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }
}
