import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:kolkata_puja/app.dart';
import 'package:kolkata_puja/screens/splash_screen.dart';

void main() {
  // Prevent google_fonts from making live network requests during tests.
  GoogleFonts.config.allowRuntimeFetching = false;

  testWidgets('App builds and shows initial splash then welcome screen', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const KolkataPujaApp());

    // Initially displays the in-app splash screen
    expect(find.byType(SplashScreen), findsOneWidget);

    // After splash delay, transitions to WelcomeScreen
    await tester.pump(const Duration(milliseconds: 4200));
    await tester.pumpAndSettle();

    expect(find.textContaining('Uma'), findsOneWidget);
  });
}
