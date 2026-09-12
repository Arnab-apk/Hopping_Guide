import 'package:firebase_auth/firebase_auth.dart';

/// Minimal app user projection. The full users collection lives in Firestore.
class AppUser {
  AppUser({
    required this.uid,
    required this.displayName,
    this.photoUrl,
    this.isGuest = false,
  });

  final String uid;
  final String? displayName;
  final String? photoUrl;
  final bool isGuest;

  factory AppUser.fromFirebase(User? user) => AppUser(
        uid: user?.uid ?? '',
        displayName: user?.displayName,
        photoUrl: user?.photoURL,
        isGuest: false,
      );

  factory AppUser.guest() => AppUser(
        uid: 'guest_${DateTime.now().millisecondsSinceEpoch}',
        displayName: 'Guest Pujo Hopper',
        isGuest: true,
      );
}
