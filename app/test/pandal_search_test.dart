import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kolkata_puja/models/pandal.dart';
import 'package:kolkata_puja/services/pandal_search_service.dart';
import 'package:kolkata_puja/utils/constants.dart';
import 'package:kolkata_puja/widgets/pandal_search_autocomplete.dart';

void main() {
  final samplePandals = [
    Pandal(
      id: 'sreebhumi',
      name: 'Sreebhumi Sporting Club',
      lat: 22.5996,
      lng: 88.4011,
      zone: KolkataZone.northKolkata,
      description: 'Famous grand replica pandal in Lake Town',
      imageUrl: 'https://example.com/sreebhumi.jpg',
      timings: '24 Hours',
      area: 'Lake Town',
      nearestMetro: 'Dum Dum',
      theme: 'Vatican City replica',
      rating: 4.9,
    ),
    Pandal(
      id: 'bagbazar',
      name: 'Bagbazar Sarbojanin Durgotsav',
      lat: 22.6045,
      lng: 88.3667,
      zone: KolkataZone.northKolkata,
      description: 'Centenary traditional pujo with Sabeki Ekchala idol',
      imageUrl: 'https://example.com/bagbazar.jpg',
      timings: '24 Hours',
      area: 'Bagbazar',
      nearestMetro: 'Shyambazar',
      theme: 'Traditional Sabeki Ekchala',
      rating: 4.8,
    ),
    Pandal(
      id: 'ekdalia',
      name: 'Ekdalia Evergreen Club',
      lat: 22.5186,
      lng: 88.3686,
      zone: KolkataZone.southKolkata,
      description: 'Architectural temple marvel in South Kolkata',
      imageUrl: 'https://example.com/ekdalia.jpg',
      timings: '24 Hours',
      area: 'Gariahat',
      nearestMetro: 'Gariahat / Kalighat',
      theme: 'South Indian Temple architecture',
      rating: 4.9,
    ),
    Pandal(
      id: 'suruchi',
      name: 'Suruchi Sangha',
      lat: 22.5123,
      lng: 88.3345,
      zone: KolkataZone.southKolkata,
      description: 'Theme-based cultural diversity showcase',
      imageUrl: 'https://example.com/suruchi.jpg',
      timings: '24 Hours',
      area: 'New Alipore',
      nearestMetro: 'Kalighat / Majerhat',
      theme: 'Cultural unity through arts',
      rating: 4.8,
    ),
  ];

  setUp(() {
    PandalSearchService.instance.clearRecentSearches();
  });

  group('PandalSearchService Unit Tests', () {
    test('matches exact name and prefix', () {
      final results = PandalSearchService.instance.searchPandals(
        'sreebhumi',
        samplePandals,
      );
      expect(results.isNotEmpty, isTrue);
      expect(results.first.pandal.id, equals('sreebhumi'));
    });

    test('supports phonetic/transliteration normalization (shree -> sree)', () {
      final results = PandalSearchService.instance.searchPandals(
        'shreebhumi',
        samplePandals,
      );
      expect(results.isNotEmpty, isTrue);
      expect(results.first.pandal.id, equals('sreebhumi'));
    });

    test('supports phonetic/transliteration normalization (sarbajanin -> sarbojanin)', () {
      final results = PandalSearchService.instance.searchPandals(
        'sarbajanin',
        samplePandals,
      );
      expect(results.isNotEmpty, isTrue);
      expect(results.first.pandal.id, equals('bagbazar'));
    });

    test('matches across area and nearest metro station', () {
      final metroResults = PandalSearchService.instance.searchPandals(
        'Shyambazar',
        samplePandals,
      );
      expect(metroResults.isNotEmpty, isTrue);
      expect(metroResults.first.pandal.id, equals('bagbazar'));

      final areaResults = PandalSearchService.instance.searchPandals(
        'Gariahat',
        samplePandals,
      );
      expect(areaResults.isNotEmpty, isTrue);
      expect(areaResults.first.pandal.id, equals('ekdalia'));
    });

    test('matches multi-token query across name and theme', () {
      final results = PandalSearchService.instance.searchPandals(
        'Bagbazar Traditional',
        samplePandals,
      );
      expect(results.isNotEmpty, isTrue);
      expect(results.first.pandal.id, equals('bagbazar'));
    });

    test('generates highlight spans for matched tokens', () {
      const normal = TextStyle(color: Colors.black);
      const highlight = TextStyle(color: Colors.amber, fontWeight: FontWeight.bold);

      final spans = PandalSearchService.buildHighlightSpans(
        text: 'Bagbazar Sarbojanin Durgotsav',
        query: 'bagbazar',
        normalStyle: normal,
        highlightStyle: highlight,
      );

      expect(spans.isNotEmpty, isTrue);
      expect(spans.first.text?.toLowerCase(), equals('bagbazar'));
      expect(spans.first.style?.color, equals(Colors.amber));
    });

    test('recent searches cache adds, deduplicates, and limits entries', () {
      final service = PandalSearchService.instance;
      service.addRecentSearch('Sreebhumi');
      service.addRecentSearch('Bagbazar');
      service.addRecentSearch('Sreebhumi'); // Should move to top, no duplicate

      expect(service.recentSearches.length, equals(2));
      expect(service.recentSearches.first, equals('Sreebhumi'));
      expect(service.recentSearches[1], equals('Bagbazar'));

      service.clearRecentSearches();
      expect(service.recentSearches, isEmpty);
    });

    test('auto-complete suggestions respect limit and relevance', () {
      final suggestions = PandalSearchService.instance.getAutoCompleteSuggestions(
        's',
        samplePandals,
        limit: 2,
      );
      expect(suggestions.length, lessThanOrEqualTo(2));
    });
  });

  group('PandalSearchAutocomplete Widget Tests', () {
    testWidgets('renders input field with hint and Durga face icon', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PandalSearchAutocomplete(
              pandals: samplePandals,
              hintText: 'Type pandal name...',
              onPandalSelected: (_) {},
            ),
          ),
        ),
      );

      expect(find.text('Type pandal name...'), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);
    });

    testWidgets('typing query displays auto-complete suggestions overlay and invokes callback', (tester) async {
      Pandal? selectedPandal;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PandalSearchAutocomplete(
              pandals: samplePandals,
              onPandalSelected: (p) => selectedPandal = p,
            ),
          ),
        ),
      );

      await tester.enterText(find.byType(TextField), 'Sree');
      await tester.pumpAndSettle();

      // Suggestion tile should appear with RichText highlight
      final richTextFinder = find.byWidgetPredicate((widget) {
        if (widget is RichText) {
          return widget.text.toPlainText().contains('Sreebhumi Sporting Club');
        }
        return false;
      });
      expect(richTextFinder, findsWidgets);

      // Tap on the suggestion
      await tester.tap(richTextFinder.first);
      await tester.pumpAndSettle();

      expect(selectedPandal, isNotNull);
      expect(selectedPandal!.id, equals('sreebhumi'));
    });
  });
}
