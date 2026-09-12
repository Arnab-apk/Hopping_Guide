import 'package:flutter_test/flutter_test.dart';

import 'package:kolkata_puja/app.dart';

void main() {
  testWidgets('App builds and shows map screen title', (tester) async {
    await tester.pumpWidget(const KolkataPujaApp());

    // The map screen's AppBar shows the app title.
    expect(find.text('Kolkata Puja'), findsOneWidget);
  });
}
