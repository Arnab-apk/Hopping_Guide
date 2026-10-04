import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kolkata_puja/models/place.dart';
import 'package:kolkata_puja/repositories/pandal_repository.dart';
import 'package:kolkata_puja/screens/pandal_list_screen.dart';
import 'package:kolkata_puja/utils/constants.dart';

class ControlledPlaceRepository implements PandalRepository {
  final requests = <Completer<List<Place>>>[];

  @override
  Future<List<Place>> getPlaces({
    required PlaceCategory category,
    KolkataZone? zoneFilter,
    String? searchQuery,
  }) {
    final request = Completer<List<Place>>();
    requests.add(request);
    return request.future;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

const pandal = Place(
  id: 'distant',
  name: 'Distant Pandal',
  category: PlaceCategory.pandal,
  lat: 23.5,
  lng: 89,
);

const food = Place(
  id: 'food',
  name: 'Local Kitchen',
  category: PlaceCategory.foodSpot,
  lat: 22.57,
  lng: 88.36,
);

void main() {
  testWidgets('failed directory load offers retry and recovers', (tester) async {
    final repository = ControlledPlaceRepository();
    await tester.pumpWidget(MaterialApp(
      home: PandalListScreen(repository: repository),
    ));
    repository.requests.single.completeError(StateError('Asset unavailable'));
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Try Again'), findsOneWidget);
    await tester.tap(find.text('Try Again'));
    await tester.pump();
    repository.requests.last.complete([pandal]);
    await tester.pumpAndSettle();

    expect(find.text('Distant Pandal'), findsOneWidget);
    expect(find.text('Try Again'), findsNothing);
  });

  testWidgets('late pandal response cannot replace the selected food category',
      (tester) async {
    final repository = ControlledPlaceRepository();
    await tester.pumpWidget(MaterialApp(
      home: PandalListScreen(repository: repository),
    ));
    await tester.tap(find.text('Food Spots'));
    await tester.pump();
    repository.requests.last.complete([food]);
    await tester.pumpAndSettle();
    repository.requests.first.complete([pandal]);
    await tester.pumpAndSettle();

    expect(find.text('Local Kitchen'), findsOneWidget);
    expect(find.text('Distant Pandal'), findsNothing);
    expect(find.text('All (1)'), findsOneWidget);
  });

  testWidgets('nearby filter shows no results when all places exceed 10km',
      (tester) async {
    final repository = ControlledPlaceRepository();
    await tester.pumpWidget(MaterialApp(
      home: PandalListScreen(repository: repository),
    ));
    repository.requests.single.complete([pandal]);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Nearby (10km)'));
    await tester.pumpAndSettle();

    expect(find.text('Distant Pandal'), findsNothing);
    expect(find.text('Clear Filters'), findsOneWidget);
    await tester.tap(find.text('Clear Filters'));
    await tester.pumpAndSettle();
    expect(find.text('Distant Pandal'), findsOneWidget);
  });

  testWidgets('food empty-state action clears the active search', (tester) async {
    final repository = ControlledPlaceRepository();
    await tester.pumpWidget(MaterialApp(
      home: PandalListScreen(repository: repository),
    ));
    repository.requests.single.complete([pandal]);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Food Spots'));
    await tester.pump();
    repository.requests.last.complete([food]);
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'missing kitchen');
    await tester.pumpAndSettle();
    expect(find.text('Clear Filters'), findsOneWidget);
    await tester.ensureVisible(find.text('Clear Filters'));
    await tester.tap(find.text('Clear Filters'));
    await tester.pumpAndSettle();
    expect(find.text('Local Kitchen'), findsOneWidget);
  });

  testWidgets('region filter can be selected and reset on a small phone',
      (tester) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final repository = ControlledPlaceRepository();
    await tester.pumpWidget(MaterialApp(
      home: PandalListScreen(repository: repository),
    ));
    repository.requests.single.complete([pandal]);
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Regions'));
    await tester.tap(find.text('Regions'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('North Kolkata'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('North'));
    await tester.tap(find.text('North'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.tap(find.text('Reset All'));
    await tester.pumpAndSettle();
    expect(find.text('Regions'), findsOneWidget);
    expect(find.text('Distant Pandal'), findsOneWidget);
  });
}
