import 'package:flutter_test/flutter_test.dart';

import 'package:kolkata_puja/app.dart';

void main() {
  testWidgets('App builds and shows map screen title', (tester) async {
    await tester.pumpWidget(const KolkataPujaApp());

    // The welcome screen shows the app title.
    expect(find.text('Pujo Parikrama'), findsOneWidget);
  });
}
