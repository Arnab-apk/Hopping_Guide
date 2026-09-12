import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kolkata_puja/models/pandal.dart';
import 'package:kolkata_puja/repositories/pandal_repository.dart';
import 'package:kolkata_puja/screens/pandal_list_screen.dart';
import 'package:kolkata_puja/utils/constants.dart';

class MockPandalRepository implements PandalRepository {
  final List<Pandal> mockPandals = [
    Pandal(
      id: 'hatibagan_sarbojanin',
      name: 'Hatibagan Sarbojanin',
      lat: 22.5947,
      lng: 88.3720,
      zone: KolkataZone.northKolkata,
      area: 'North Kolkata',
      region: 'North',
      rating: 4.5,
      theme: 'Traditional',
      crowdLevel: 'high',
      timings: '12:00 AM - 12:00 PM',
      imageUrl: '',
      description: 'Iconic North Kolkata puja',
      nearestMetro: 'Shyambazar (Blue)',
    ),
    Pandal(
      id: 'ekdalia_evergreen',
      name: 'Ekdalia Evergreen',
      lat: 22.5245,
      lng: 88.3688,
      zone: KolkataZone.southKolkata,
      area: 'South Kolkata',
      region: 'South',
      rating: 4.8,
      theme: 'Traditional',
      crowdLevel: 'high',
      timings: '6:00 AM - 11:00 PM',
      imageUrl: '',
      description: 'Iconic South Kolkata puja',
      nearestMetro: 'Gariahat',
    ),
  ];

  @override
  Future<List<Pandal>> all() async => mockPandals;

  @override
  Future<List<Pandal>> byZone(KolkataZone zone) async =>
      mockPandals.where((p) => p.zone == zone).toList();

  @override
  Future<Pandal?> byId(String id) async {
    try {
      return mockPandals.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Stream<List<Pandal>> watchAll() async* {
    yield mockPandals;
  }
}

void main() {
  testWidgets('PandalListScreen renders search bar and pandal cards', (tester) async {
    final mockRepo = MockPandalRepository();

    await tester.pumpWidget(
      MaterialApp(
        home: PandalListScreen(repository: mockRepo),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Kolkata Pandals'), findsOneWidget);
    expect(find.text('Hatibagan Sarbojanin'), findsOneWidget);
    expect(find.text('Ekdalia Evergreen'), findsOneWidget);

    // Test search filter
    await tester.enterText(find.byType(TextField), 'Ekdalia');
    await tester.pumpAndSettle();

    expect(find.text('Ekdalia Evergreen'), findsOneWidget);
    expect(find.text('Hatibagan Sarbojanin'), findsNothing);
  });
}
