import 'package:firebase_auth/firebase_auth.dart';

/// App user model holding identity, Google profile picture, email, and guest status.
class AppUser {
  AppUser({
    required this.uid,
    required this.displayName,
    this.email,
    this.photoUrl,
    this.phoneNumber,
    this.isGuest = false,
  });

  final String uid;
  final String? displayName;
  final String? email;
  final String? photoUrl;
  final String? phoneNumber;
  final bool isGuest;

  String get initials {
    if (displayName == null || displayName!.trim().isEmpty) return 'U';
    final parts = displayName!.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return displayName![0].toUpperCase();
  }

  AppUser copyWith({
    String? uid,
    String? displayName,
    String? email,
    String? photoUrl,
    String? phoneNumber,
    bool? isGuest,
  }) {
    return AppUser(
      uid: uid ?? this.uid,
      displayName: displayName ?? this.displayName,
      email: email ?? this.email,
      photoUrl: photoUrl ?? this.photoUrl,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      isGuest: isGuest ?? this.isGuest,
    );
  }

  factory AppUser.fromFirebase(User? user) => AppUser(
        uid: user?.uid ?? '',
        displayName: user?.displayName,
        email: user?.email,
        photoUrl: user?.photoURL,
        phoneNumber: user?.phoneNumber,
        isGuest: false,
      );

  factory AppUser.guest() => AppUser(
        uid: 'guest_${DateTime.now().millisecondsSinceEpoch}',
        displayName: 'Guest Pujo Hopper',
        email: null,
        photoUrl: null,
        phoneNumber: null,
        isGuest: true,
      );

  Map<String, dynamic> toJson() => {
        'uid': uid,
        'displayName': displayName,
        'email': email,
        'photoUrl': photoUrl,
        'phoneNumber': phoneNumber,
        'isGuest': isGuest,
      };

  factory AppUser.fromJson(Map<String, dynamic> json) => AppUser(
        uid: json['uid'] as String? ?? '',
        displayName: json['displayName'] as String?,
        email: json['email'] as String?,
        photoUrl: json['photoUrl'] as String?,
        phoneNumber: json['phoneNumber'] as String? ?? json['phone_number'] as String?,
        isGuest: json['isGuest'] as bool? ?? false,
      );
}
