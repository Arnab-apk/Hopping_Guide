import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:kolkata_puja/app.dart';

void main() {
  // Prevent google_fonts from making live network requests during tests.
  GoogleFonts.config.allowRuntimeFetching = false;

  testWidgets('App builds and shows map screen title', (tester) async {
    await tester.pumpWidget(const KolkataPujaApp());

    // The welcome screen shows the app title.
    expect(find.text('Pujo Parikrama'), findsOneWidget);
  });
}
