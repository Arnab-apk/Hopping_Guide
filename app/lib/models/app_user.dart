import 'package:firebase_auth/firebase_auth.dart';

/// Minimal app user projection. The full users collection lives in Firestore.
class AppUser {
  AppUser({required this.uid, required this.displayName, this.photoUrl});

  final String uid;
  final String? displayName;
  final String? photoUrl;

  factory AppUser.fromFirebase(User? user) => AppUser(
        uid: user?.uid ?? '',
        displayName: user?.displayName,
        photoUrl: user?.photoURL,
      );
}
