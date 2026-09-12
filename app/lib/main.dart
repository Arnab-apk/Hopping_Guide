import 'package:flutter/material.dart';

import 'app.dart';

// NOTE: Firebase is not wired yet. After creating a Firebase project, run:
//   dart pub global activate flutterfire_cli
//   flutterfire configure --project=<your-firebase-project-id>
// This generates lib/firebase_options.dart. Then uncomment the block below.
//
// import 'package:firebase_core/firebase_core.dart';
// import 'firebase_options.dart';
//
// void main() async {
//   WidgetsFlutterBinding.ensureInitialized();
//   await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
//   runApp(const KolkataPujaApp());
// }

void main() {
  // Running in "demo mode" (no backend) until Firebase is configured above.
  runApp(const KolkataPujaApp());
}

/// Toggle this to true once Firebase is configured (see comment above).
const bool kFirebaseConfigured = false;
