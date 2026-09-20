import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:kolkata_puja/app.dart';
import 'package:kolkata_puja/screens/splash_screen.dart';
import 'package:kolkata_puja/screens/welcome_screen.dart';

void main() {
  // Prevent google_fonts from making live network requests during tests.
  GoogleFonts.config.allowRuntimeFetching = false;

  testWidgets('App builds and shows welcome screen directly on first open without splash screen', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const KolkataPujaApp());

    // Does NOT display the in-app splash screen before login
    expect(find.byType(SplashScreen), findsNothing);

    // Displays WelcomeScreen directly
    expect(find.byType(WelcomeScreen), findsOneWidget);
    expect(find.textContaining('Uma'), findsOneWidget);
  });
}
