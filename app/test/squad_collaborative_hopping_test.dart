import 'dart:async';

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kolkata_puja/models/app_user.dart';
import 'package:kolkata_puja/models/pandal.dart';
import 'package:kolkata_puja/models/squad_pandal_stop.dart';
import 'package:kolkata_puja/models/squad_member.dart';
import 'package:kolkata_puja/repositories/squad_firestore_repository.dart';
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
      child: const MaterialApp(home: GroupScreen()),
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
    test(
      'Add, vote, optimize, start hopping, advance stops, and end hopping',
      () async {
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
        expect(
          squadService.currentHoppingTarget?.name,
          squadService.chosenPandals[0].name,
        );
        expect(squadService.visitedPandalsCount, 0);
        expect(CustomHoppingTrailService.instance.hasActiveTrail, isTrue);

        // 5. Advance to next stop
        await squadService.advanceToNextPandalStop();
        expect(squadService.visitedPandalsCount, 1);
        expect(squadService.activeHoppingStopIndex, 1);
        expect(
          squadService.currentHoppingTarget?.name,
          squadService.chosenPandals[1].name,
        );

        // 6. Advance through remaining stops
        await squadService.advanceToNextPandalStop();
        expect(squadService.visitedPandalsCount, 2);
        expect(squadService.activeHoppingStopIndex, 2);

        await squadService.advanceToNextPandalStop();
        // All 3 stops visited -> hopping completes
        expect(squadService.isHoppingActive, isFalse);
        expect(CustomHoppingTrailService.instance.hasActiveTrail, isFalse);
      },
    );
  });

  group('GroupScreen Collaborative UI Widget Tests', () {
    testWidgets(
      'renders Pandals to Hop Together card, empty prompt, and live hopping HUD',
      (tester) async {
        tester.view.physicalSize = const Size(1080, 2400);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        final squadService = (await tester.runAsync(
          () => SquadService.create(),
        ))!;
        squadService.resetForTesting();
        await tester.runAsync(() async {
          await squadService.createSquad("Test Hoppers", "Hatibagan");
        });
        squadService.cancelTimersForTesting();

        await tester.pumpWidget(createGroupScreenWithSquad(squadService));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        // 1. Verify Trail tab is rendered
        expect(find.text('Trail'), findsOneWidget);

        // 2. Empty state prompt
        expect(find.text('No stops yet'), findsOneWidget);
        expect(find.text('Add pandals'), findsWidgets);

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
        expect(find.text('Start hopping ▶'), findsOneWidget);
        expect(find.text('Optimize order'), findsOneWidget);

        // 5. Tap "Start hopping ▶"
        await tester.runAsync(() async {
          await tester.tap(find.text('Start hopping ▶'));
          final deadline = DateTime.now().add(const Duration(seconds: 5));
          while (squadService.isPlanMutationPending &&
              DateTime.now().isBefore(deadline)) {
            await Future<void>.delayed(const Duration(milliseconds: 10));
          }
        });
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        expect(find.text('Your trail is ready'), findsOneWidget);
        await tester.tap(find.text('Later'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        // 6. Verify Live Hopping Banner activates
        expect(squadService.isHoppingActive, isTrue);
        expect(find.text('HOPPING'), findsOneWidget);
        expect(find.textContaining('NEXT STOP'), findsOneWidget);
        expect(find.text('Skip stop'), findsOneWidget);

        // 7. Skipping advances without claiming a visit.
        await tester.runAsync(() async {
          await tester.tap(find.text('Skip stop'));
          final deadline = DateTime.now().add(const Duration(seconds: 5));
          while (squadService.isPlanMutationPending &&
              DateTime.now().isBefore(deadline)) {
            await Future<void>.delayed(const Duration(milliseconds: 10));
          }
        });
        // Arrival stays disabled until the previous serialized save finishes.
        for (
          var frame = 0;
          frame < 50 && squadService.isPlanMutationPending;
          frame++
        ) {
          await tester.pump(const Duration(milliseconds: 20));
        }
        expect(squadService.isPlanMutationPending, isFalse);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        expect(squadService.visitedPandalsCount, 0);
        expect(squadService.activeHoppingStopIndex, 1);
        await tester.tap(find.text('We are here'));
        await tester.pump();
        expect(squadService.visitedPandalsCount, 1);
      },
    );
  });

  test('two members adding stops together keep both changes', () async {
    final repo = _InMemoryPlanRepository();
    final first = await SquadService.create(repo: repo);
    await first.createSquad('Friends', 'North gate');
    final second = await SquadService.create(repo: repo);
    expect(await second.joinSquad('PUJATEST'), isTrue);

    Pandal pandal(String id) => Pandal(
      id: id,
      name: id,
      lat: 22.60,
      lng: 88.36,
      zone: KolkataZone.northKolkata,
      timings: '24h',
      theme: 'Traditional',
      imageUrl: '',
      description: '',
    );

    await Future.wait([
      first.addPandalToSquad(pandal('stop_a')),
      second.addPandalToSquad(pandal('stop_b')),
    ]);
    expect(repo.stopIds, containsAll(['stop_a', 'stop_b']));
    await first.leaveSquad();
    await second.leaveSquad();
    first.dispose();
    second.dispose();
    await repo.close();
  });

  test('failed cloud creation never exposes an invite code', () async {
    final service = await SquadService.create(repo: _FailingCreateRepository());
    await service.createSquad('Friends', 'North gate');
    expect(service.hasActiveSquad, isFalse);
    expect(service.squadCode, isNull);
    expect(service.lastError, contains('Could not create'));
    service.dispose();
  });

  test(
    'permission-denied leave keeps the group and explains the actual failure',
    () async {
      final repo = _InMemoryPlanRepository()
        ..leaveError = FirebaseException(
          plugin: 'cloud_firestore',
          code: 'permission-denied',
        );
      final service = await SquadService.create(repo: repo);
      await service.createSquad('Friends', 'North gate');
      expect(await service.leaveSquad(), isFalse);
      expect(service.hasActiveSquad, isTrue);
      expect(service.lastError, contains('denied permission'));
      expect(service.lastError, isNot(contains('connection')));
      repo.leaveError = null;
      expect(await service.leaveSquad(), isTrue);
      expect(service.hasActiveSquad, isFalse);
      expect(service.lastError, isNull);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.containsKey('saved_group_id'), isFalse);
      expect(prefs.containsKey('saved_group_code'), isFalse);
      service.dispose();
      await repo.close();
    },
  );

  test(
    'unavailable leave keeps the group and reports the connection failure',
    () async {
      final repo = _InMemoryPlanRepository()
        ..leaveError = FirebaseException(
          plugin: 'cloud_firestore',
          code: 'unavailable',
        );
      final service = await SquadService.create(repo: repo);
      await service.createSquad('Friends', 'North gate');
      expect(await service.leaveSquad(), isFalse);
      expect(service.hasActiveSquad, isTrue);
      expect(service.lastError, contains('connection'));
      service.dispose();
      await repo.close();
    },
  );
}

class _FailingCreateRepository extends SquadFirestoreRepository {
  @override
  bool get isAvailable => true;

  @override
  Future<Map<String, dynamic>> createSquad({
    required String name,
    required String meetupPointName,
    required double meetupLat,
    required double meetupLng,
    required int separationThresholdMeters,
    required SquadMember host,
  }) async {
    throw StateError('Network unavailable');
  }
}

class _InMemoryPlanRepository extends SquadFirestoreRepository {
  FirebaseException? leaveError;
  @override
  Future<void> leaveSquad({
    required String squadId,
    required String memberId,
    String? memberName,
  }) async {
    if (leaveError != null) throw leaveError!;
  }

  final _events = StreamController<Map<String, dynamic>>.broadcast();
  Map<String, dynamic> _plan = {
    'squadId': 'sq_shared',
    'squadCode': 'PUJATEST',
    'name': 'Friends',
    'meetupPointName': 'North gate',
    'meetupLat': 22.60,
    'meetupLng': 88.36,
    'membersUid': <String>[],
    'chosenPandals': <Map<String, dynamic>>[],
    'isHoppingActive': false,
    'activeStopIndex': 0,
    'planRevision': 0,
  };

  @override
  bool get isAvailable => true;

  List<String> get stopIds => (_plan['chosenPandals'] as List)
      .map((item) => (item as Map)['id'] as String)
      .toList();

  @override
  Future<Map<String, dynamic>> createSquad({
    required String name,
    required String meetupPointName,
    required double meetupLat,
    required double meetupLng,
    required int separationThresholdMeters,
    required SquadMember host,
  }) async => _plan;

  @override
  Future<Map<String, dynamic>?> findSquadByCode(String code) async => _plan;

  @override
  Future<bool> joinSquad({
    required String squadId,
    required SquadMember member,
  }) async => true;

  @override
  Stream<Map<String, dynamic>?> streamSquad(String squadId) async* {
    yield {..._plan};
    yield* _events.stream;
  }

  @override
  Future<Map<String, dynamic>> mutateSquadPlan({
    required String squadId,
    required Map<String, dynamic> Function(Map<String, dynamic>) change,
  }) async {
    await Future<void>.delayed(Duration.zero);
    _plan = {
      ..._plan,
      ...change({..._plan}),
      'planRevision': (_plan['planRevision'] as int) + 1,
    };
    _events.add({..._plan});
    return {..._plan};
  }

  Future<void> close() => _events.close();
}
