import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kolkata_puja/repositories/supplementary_repository.dart';
import 'package:kolkata_puja/screens/helplines_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Helplines & Safety data (SupplementaryRepository)', () {
    test('loads all 5 helplines with label and number', () async {
      final repo = SupplementaryRepository();
      final helplines = await repo.getHelplines();

      expect(helplines.length, 5);
      expect(helplines.any((h) => h.label == 'Police Helpline' && h.number == '100'), isTrue);
      expect(helplines.any((h) => h.label == 'Fire Department' && h.number == '101'), isTrue);
      expect(helplines.any((h) => h.number == '102'), isTrue);
      expect(helplines.any((h) => h.number == '1091'), isTrue);
      expect(helplines.any((h) => h.number == '1077'), isTrue);

      for (final h in helplines) {
        expect(h.label.isNotEmpty, true);
        expect(h.number.isNotEmpty, true);
      }
    });

    test('loads all 3 safety guides with non-empty content', () async {
      final repo = SupplementaryRepository();
      final guides = await repo.getSafetyGuides();

      expect(guides.length, 3);
      expect(guides.any((g) => g.title == 'Heat Exhaustion'), isTrue);
      expect(guides.any((g) => g.title == 'Fainting'), isTrue);
      expect(guides.any((g) => g.title == 'Minor Burns'), isTrue);
      for (final g in guides) {
        expect(g.content, isNotEmpty);
      }
    });
  });

  group('HelplinesScreen', () {
    testWidgets('renders the Emergency & Safety app bar', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: HelplinesScreen()));
      await tester.pump();

      // AppBar is rendered synchronously on the first frame, before async
      // data loading resolves, so it does not depend on pumpAndSettle.
      expect(find.text('Emergency & Safety'), findsOneWidget);
    });
  });
}
