import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:kolkata_puja/config/theme.dart';
import 'package:kolkata_puja/models/pandal.dart';
import 'package:kolkata_puja/models/place.dart';
import 'package:kolkata_puja/services/pandal_user_state_service.dart';
import 'package:kolkata_puja/widgets/pandal_card.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

const food = Place(
  id: 'long_food',
  name: 'A heritage restaurant with a long descriptive neighbourhood name',
  category: PlaceCategory.foodSpot,
  lat: 22.6,
  lng: 88.37,
  type: 'Traditional Bengali cuisine and heritage sweets',
  nearbyPandal: 'A very long neighbourhood pandal name and its nearby landmark',
  mustTry: 'Kosha mangsho, paratha and traditional Bengali desserts',
  rating: 4.5,
);

void main() {
  for (final dark in [false, true]) {
    for (final size in [const Size(375, 812), const Size(812, 375)]) {
      testWidgets('long card labels reflow at 2x text: $dark $size', (
        tester,
      ) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        await tester.pumpWidget(
          MaterialApp(
            theme: dark ? appDarkTheme : appTheme,
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context).copyWith(
                textScaler: const TextScaler.linear(2),
                disableAnimations: true,
              ),
              child: child!,
            ),
            home: Scaffold(
              body: SingleChildScrollView(
                child: PlaceCard(place: food, onTap: () {}, distanceKm: 1.2),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(find.text(food.name), findsOneWidget);
        expect(find.text(food.type!), findsOneWidget);
        expect(find.text('Near ${food.nearbyPandal}'), findsOneWidget);
        final bookmark = find.byType(IconButton);
        expect(tester.getSize(bookmark).width, greaterThanOrEqualTo(48));
        expect(tester.getSize(bookmark).height, greaterThanOrEqualTo(48));
        final map = find.byWidgetPredicate((widget) => widget is TextButton);
        expect(tester.getSize(map).height, greaterThanOrEqualTo(48));
      });
    }
  }

  testWidgets(
    'long metro metadata fits and reduced motion exposes content immediately',
    (tester) async {
      tester.view.physicalSize = const Size(375, 812);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final pandal = Pandal.fromMap('test_pandal', {
        'name': food.name,
        'nearest_metro': food.nearbyPandal,
        'zone': 'northKolkata',
      });
      await tester.pumpWidget(
        MaterialApp(
          theme: appDarkTheme,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(
              textScaler: const TextScaler.linear(2),
              disableAnimations: true,
            ),
            child: child!,
          ),
          home: Scaffold(
            body: SingleChildScrollView(
              child: PandalCard(pandal: pandal, onTap: () {}, distanceKm: 1.2),
            ),
          ),
        ),
      );
      expect(find.byType(Animate), findsNothing);
      expect(find.text(food.name), findsOneWidget);
      expect(find.text(food.nearbyPandal!), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('bookmark and map actions do not open the parent card', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final userState = await PandalUserStateService.create();
    addTearDown(userState.dispose);
    var details = 0;
    var maps = 0;
    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: userState,
        child: MaterialApp(
          theme: appTheme,
          home: Scaffold(
            body: SingleChildScrollView(
              child: PlaceCard(
                place: food,
                onTap: () => details++,
                onMapTap: () => maps++,
                distanceKm: 1.2,
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Add to favorites'));
    await tester.pumpAndSettle();
    expect(userState.isFavorite(food.id), isTrue);
    expect(find.byTooltip('Remove from favorites'), findsOneWidget);
    expect(details, 0);
    await tester.tap(find.text('Map'));
    expect(maps, 1);
    expect(details, 0);
    await tester.tap(find.text(food.name));
    expect(details, 1);
  });
}
