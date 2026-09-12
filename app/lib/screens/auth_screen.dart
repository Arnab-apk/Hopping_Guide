import 'package:flutter/material.dart';

/// P0 auth gate: Google Sign-In (with email/password fallback).
/// TODO(Week 2): call AuthService.instance.signInWithGoogle(); on success,
/// gate the rest of the app behind authStateChanges.
class AuthScreen extends StatelessWidget {
  const AuthScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sign in')),
      body: const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'Sign in — wired in Week 2.\n\n'
            'Google Sign-In via Firebase Auth.',
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
