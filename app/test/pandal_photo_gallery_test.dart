import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kolkata_puja/models/pandal.dart';
import 'package:kolkata_puja/models/pandal_photo.dart';
import 'package:kolkata_puja/widgets/pandal_photo_gallery.dart';

void main() {
  testWidgets('empty galleries show an honest state with no inactive button', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(body: PandalPhotoGallery(pandal: Pandal.fromMap('empty', {}))),
    ));
    expect(find.text('Photos are not available for this pandal yet.'), findsOneWidget);
    expect(find.byType(TextButton), findsNothing);
  });

  for (final dark in [false, true]) {
    for (final size in [const Size(375, 812), const Size(812, 375)]) {
      testWidgets('viewer navigation and credits fit at 2x text: $dark $size', (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        await tester.pumpWidget(MaterialApp(
          theme: ThemeData(brightness: dark ? Brightness.dark : Brightness.light),
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(
              textScaler: const TextScaler.linear(2), disableAnimations: true,
            ),
            child: child!,
          ),
          home: PandalPhotoViewer(pandalName: 'Example Pandal', photos: const [
            PandalPhoto(url: 'https://example.com/one.jpg',
                caption: 'Architecture photographed during the previous Puja',
                credit: 'A photographer with a long credited name', year: 2025),
            PandalPhoto(url: 'https://example.com/two.jpg', credit: 'Second photographer'),
          ]),
        ));
        await tester.pump();
        expect(tester.takeException(), isNull);
        expect(find.text('Photo 1 of 2'), findsOneWidget);
        expect(find.text('Puja 2025'), findsOneWidget);
        expect(tester.widget<IconButton>(find.ancestor(of: find.byTooltip('Previous photo'), matching: find.byType(IconButton))).onPressed, isNull);
        expect(tester.getSize(find.byTooltip('Next photo')).height, greaterThanOrEqualTo(48));
        await tester.tap(find.byTooltip('Next photo'));
        await tester.pump();
        expect(find.text('Photo 2 of 2'), findsOneWidget);
        expect(find.text('Photo: Second photographer'), findsOneWidget);
        expect(tester.widget<IconButton>(find.ancestor(of: find.byTooltip('Next photo'), matching: find.byType(IconButton))).onPressed, isNull);
        await tester.tap(find.byTooltip('Previous photo'));
        await tester.pump();
        expect(find.text('Photo 1 of 2'), findsOneWidget);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
        await tester.pump(const Duration(seconds: 1));
      });
    }
  }
}
