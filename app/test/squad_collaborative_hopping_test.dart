import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kolkata_puja/models/app_user.dart';
import 'package:kolkata_puja/models/pandal.dart';
import 'package:kolkata_puja/models/squad_pandal_stop.dart';
import 'package:kolkata_puja/screens/group_screen.dart';
import 'package:kolkata_puja/services/auth_service.dart';
import 'package:kolkata_puja/services/custom_hopping_trail_service.dart';
import 'package:kolkata_puja/services/location_service.dart';
import 'package:kolkata_puja/services/squad_service.dart';
import 'package:kolkata_puja/utils/constants.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    LocationService.enableTestMode = true;
    SquadService.enableTestMode = true;
    AuthService.instance.setCurrentUserForTesting(
      AppUser(
        uid: 'user_arnab',
        displayName: 'Arnab',
        email: 'arnab@example.com',
        isGuest: false,
      ),
    );
  });

  tearDown(() {
    LocationService.enableTestMode = false;
    SquadService.enableTestMode = false;
    AuthService.instance.setCurrentUserForTesting(null);
    CustomHoppingTrailService.instance.endTrail();
  });

  Widget createGroupScreenWithSquad(SquadService squadService) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<SquadService>.value(value: squadService),
        ChangeNotifierProvider<AuthService>.value(value: AuthService.instance),
        ChangeNotifierProvider<CustomHoppingTrailService>.value(
          value: CustomHoppingTrailService.instance,
        ),
      ],
      child: const MaterialApp(
        home: GroupScreen(),
      ),
    );
  }

  group('Squad Collaborative Pandal Stop Model Tests', () {
    test('SquadPandalStop serializes to and from JSON correctly', () {
      final stop = SquadPandalStop(
        id: 'bagbazar_sarbojanin',
        name: 'Bagbazar Sarbojanin',
        zone: 'North Kolkata',
        lat: 22.6025,
        lng: 88.3683,
        area: 'Bagbazar',
        suggestedBy: 'user_arnab',
        suggestedByName: 'Arnab',
        addedAt: DateTime(2026, 9, 27, 10, 0),
        votes: ['user_arnab', 'user_rohit'],
        isVisited: false,
      );

      final json = stop.toJson();
      expect(json['id'], 'bagbazar_sarbojanin');
      expect(json['name'], 'Bagbazar Sarbojanin');
      expect(json['suggestedByName'], 'Arnab');
      expect(json['votes'], ['user_arnab', 'user_rohit']);

      final restored = SquadPandalStop.fromJson(json);
      expect(restored.id, stop.id);
      expect(restored.pandalName, stop.name);
      expect(restored.voteCount, 2);
      expect(restored.isVotedBy('user_arnab'), isTrue);
      expect(restored.isVotedBy('user_stranger'), isFalse);
    });

    test('SquadPandalStop converts to and from Pandal correctly', () {
      final pandal = Pandal(
        id: 'college_square',
        name: 'College Square',
        lat: 22.5744,
        lng: 88.3639,
        zone: KolkataZone.centralKolkata,
        area: 'College Street',
        theme: 'Illumination',
        timings: 'Open 24 Hours',
        imageUrl: 'https://example.com/cs.jpg',
        description: 'Famous illumination pandal',
      );

      final stop = SquadPandalStop.fromPandal(
        pandal,
        suggestedBy: 'user_arnab',
        suggestedByName: 'Arnab',
      );

      expect(stop.id, 'college_square');
      expect(stop.pandalName, 'College Square');
      expect(stop.suggestedByName, 'Arnab');
      expect(stop.voteCount, 1);

      final convertedPandal = stop.toPandal();
      expect(convertedPandal.id, pandal.id);
      expect(convertedPandal.name, pandal.name);
      expect(convertedPandal.lat, pandal.lat);
      expect(convertedPandal.zone, KolkataZone.centralKolkata);
    });
  });

  group('SquadService Collaborative Hopping Logic Tests', () {
    test('Add, vote, optimize, start hopping, advance stops, and end hopping', () async {
      final squadService = SquadService.instance;
      squadService.resetForTesting();
      await squadService.createSquad("Festive Squad", "Hatibagan");
      squadService.cancelTimersForTesting();

      expect(squadService.chosenPandals, isEmpty);
      expect(squadService.isHoppingActive, isFalse);

      final p1 = Pandal(
        id: 'bagbazar',
        name: 'Bagbazar Sarbojanin',
        lat: 22.6025,
        lng: 88.3683,
        zone: KolkataZone.northKolkata,
        timings: '24h',
        theme: 'Traditional',
        imageUrl: 'https://example.com/bagbazar.jpg',
        description: 'Historic heritage pandal',
      );

      final p2 = Pandal(
        id: 'kumartuli',
        name: 'Kumartuli Park',
        lat: 22.5991,
        lng: 88.3670,
        zone: KolkataZone.northKolkata,
        timings: '24h',
        theme: 'Artistic',
        imageUrl: 'https://example.com/kumartuli.jpg',
        description: 'Potters art display',
      );

      final p3 = Pandal(
        id: 'ahiritola',
        name: 'Ahiritola Sarbojanin',
        lat: 22.5934,
        lng: 88.3615,
        zone: KolkataZone.northKolkata,
        timings: '24h',
        theme: 'Culture',
        imageUrl: 'https://example.com/ahiritola.jpg',
        description: 'Riverfront pandal',
      );

      // 1. Add pandals
      await squadService.addPandalToSquad(p1);
      await squadService.addPandalToSquad(p2);
      await squadService.addPandalToSquad(p3);

      expect(squadService.chosenPandals.length, 3);
      expect(squadService.chosenPandals[0].name, 'Bagbazar Sarbojanin');

      // 2. Voting toggle
      final initialVotes = squadService.chosenPandals[0].voteCount;
      await squadService.toggleVotePandal('bagbazar');
      // Toggling by same user who suggested removes vote
      expect(squadService.chosenPandals[0].voteCount, initialVotes - 1);
      // Toggling again adds vote back
      await squadService.toggleVotePandal('bagbazar');
      expect(squadService.chosenPandals[0].voteCount, initialVotes);

      // 3. Optimize route
      await squadService.optimizeSquadRoute();
      expect(squadService.chosenPandals.length, 3);

      // 4. Start squad hopping
      await squadService.startSquadHopping();
      expect(squadService.isHoppingActive, isTrue);
      expect(squadService.activeHoppingStopIndex, 0);
      expect(squadService.currentHoppingTarget?.name, squadService.chosenPandals[0].name);
      expect(squadService.visitedPandalsCount, 0);
      expect(CustomHoppingTrailService.instance.hasActiveTrail, isTrue);

      // 5. Advance to next stop
      await squadService.advanceToNextPandalStop();
      expect(squadService.visitedPandalsCount, 1);
      expect(squadService.activeHoppingStopIndex, 1);
      expect(squadService.currentHoppingTarget?.name, squadService.chosenPandals[1].name);

      // 6. Advance through remaining stops
      await squadService.advanceToNextPandalStop();
      expect(squadService.visitedPandalsCount, 2);
      expect(squadService.activeHoppingStopIndex, 2);

      await squadService.advanceToNextPandalStop();
      // All 3 stops visited -> hopping completes
      expect(squadService.isHoppingActive, isFalse);
      expect(CustomHoppingTrailService.instance.hasActiveTrail, isFalse);
    });
  });

  group('GroupScreen Collaborative UI Widget Tests', () {
    testWidgets('renders Pandals to Hop Together card, empty prompt, and live hopping HUD', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final squadService = SquadService.instance;
      squadService.resetForTesting();
      await tester.runAsync(() async {
        await squadService.createSquad("Test Hoppers", "Hatibagan");
      });
      squadService.cancelTimersForTesting();

      await tester.pumpWidget(createGroupScreenWithSquad(squadService));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // 1. Verify Card 4 Header is rendered
      expect(find.text('Pandals to Hop Together'), findsOneWidget);
      expect(find.text('Vote & plan group stops'), findsOneWidget);

      // 2. Empty state prompt
      expect(find.text('No pandals chosen yet'), findsOneWidget);
      expect(find.text('Choose Pandals to Visit'), findsOneWidget);

      // 3. Add pandals to squad
      final p1 = Pandal(
        id: 'suruchi_sangha',
        name: 'Suruchi Sangha',
        lat: 22.5186,
        lng: 88.3378,
        zone: KolkataZone.southKolkata,
        timings: '24h',
        theme: 'Environment',
        imageUrl: 'https://example.com/suruchi.jpg',
        description: 'New Alipore pandal',
      );

      final p2 = Pandal(
        id: 'chetla_agrani',
        name: 'Chetla Agrani Club',
        lat: 22.5165,
        lng: 88.3412,
        zone: KolkataZone.southKolkata,
        timings: '24h',
        theme: 'Heritage',
        imageUrl: 'https://example.com/chetla.jpg',
        description: 'South Kolkata popular club',
      );

      await tester.runAsync(() async {
        await squadService.addPandalToSquad(p1);
        await squadService.addPandalToSquad(p2);
      });

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // 4. Verify pandals appear in the list
      expect(find.text('Suruchi Sangha'), findsOneWidget);
      expect(find.text('Chetla Agrani Club'), findsOneWidget);
      expect(find.text('Hop Together'), findsOneWidget);
      expect(find.text('Optimize'), findsOneWidget);

      // 5. Tap "Hop Together"
      await tester.tap(find.text('Hop Together'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // 6. Verify Live Hopping Banner activates
      expect(squadService.isHoppingActive, isTrue);
      expect(find.text('HOPPING LIVE'), findsOneWidget);
      expect(find.textContaining('CURRENT DESTINATION'), findsOneWidget);
      expect(find.text('Next Stop / Visited'), findsOneWidget);

      // 7. Advance stop via "Next Stop / Visited"
      await tester.tap(find.text('Next Stop / Visited'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(squadService.visitedPandalsCount, 1);
      expect(squadService.activeHoppingStopIndex, 1);
    });
  });
}
