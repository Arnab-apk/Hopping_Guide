import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kolkata_puja/config/theme.dart';
import 'package:kolkata_puja/widgets/app_notice.dart';

void main() {
  GoogleFonts.config.allowRuntimeFetching = false;
  for (final dark in [false, true]) {
    testWidgets('Notice remains readable and actionable in ${dark ? 'dark' : 'light'} mode', (tester) async {
      tester.view.physicalSize = const Size(375, 812);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      var retried = false;
      await tester.pumpWidget(MaterialApp(
        theme: dark ? appDarkTheme : appTheme,
        home: Scaffold(body: Builder(builder: (context) => FilledButton(
          onPressed: () => showAppErrorNotice(context,
            'Could not update your route. Your saved stops are still available.',
            actionLabel: 'Retry', onAction: () => retried = true),
          child: const Text('Show notice'),
        ))),
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(textScaler: const TextScaler.linear(2), disableAnimations: true),
          child: child!),
      ));
      await tester.tap(find.text('Show notice'));
      await tester.pumpAndSettle();
      final snack = tester.widget<SnackBar>(find.byType(SnackBar));
      final message = tester.widget<Text>(find.textContaining('Could not update'));
      final a = message.style!.color!.computeLuminance();
      final b = snack.backgroundColor!.computeLuminance();
      final ratio = a > b ? (a + .05) / (b + .05) : (b + .05) / (a + .05);
      expect(ratio, greaterThanOrEqualTo(4.5));
      expect(tester.takeException(), isNull);
      await tester.tap(find.text('Retry'));
      expect(retried, isTrue);
      await tester.pumpAndSettle();
    });
  }
}
