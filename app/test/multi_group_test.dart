import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kolkata_puja/models/app_user.dart';
import 'package:kolkata_puja/models/squad_member.dart';
import 'package:kolkata_puja/repositories/squad_firestore_repository.dart';
import 'package:kolkata_puja/services/auth_service.dart';
import 'package:kolkata_puja/services/location_service.dart';
import 'package:kolkata_puja/services/squad_service.dart';
import 'package:kolkata_puja/widgets/group_manager_sheet.dart';

class _GroupsRepo extends SquadFirestoreRepository {
  final data = <String, Map<String, dynamic>>{};
  final paused = <String>[];
  final removed = <String>[];
  final updates = <String>[];
  final directory =
      StreamController<
        ({List<Map<String, dynamic>> groups, bool fromCache})
      >.broadcast();
  bool failCreate = false;
  bool failJoin = false;
  bool failPause = false;
  bool failLeave = false;
  @override
  bool get isAvailable => true;
  @override
  Stream<({List<Map<String, dynamic>> groups, bool fromCache})>
  streamUserSquads(String memberId) => directory.stream;
  @override
  Stream<List<SquadMember>> streamMembers(
    String squadId, {
    String? currentUserId,
  }) => const Stream.empty();
  @override
  Stream<Map<String, dynamic>?> streamSquad(String squadId) =>
      const Stream.empty();
  @override
  Future<Map<String, dynamic>> createSquad({
    required String name,
    required String meetupPointName,
    required double meetupLat,
    required double meetupLng,
    required int separationThresholdMeters,
    required SquadMember host,
  }) async {
    if (failCreate) throw StateError('Network unavailable');
    final id = 'group_${data.length + 1}';
    return data[id] = {
      'squadId': id,
      'squadCode': 'PUJA${data.length + 1}',
      'name': name,
      'hostId': host.id,
      'membersUid': [host.id],
      'meetupPointName': meetupPointName,
      'meetupLat': meetupLat,
      'meetupLng': meetupLng,
      'separationThresholdMeters': separationThresholdMeters,
      'chosenPandals': <Map<String, dynamic>>[],
      'isHoppingActive': false,
      'activeStopIndex': 0,
    };
  }

  @override
  Future<Map<String, dynamic>?> findSquadByCode(String code) async =>
      data.values.where((group) => group['squadCode'] == code).firstOrNull;
  @override
  Future<Map<String, dynamic>?> getSquadForMember(
    String squadId,
    String memberId,
  ) async => (data[squadId]?['membersUid'] as List? ?? []).contains(memberId)
      ? data[squadId]
      : null;
  @override
  Future<bool> joinSquad({
    required String squadId,
    required SquadMember member,
  }) async {
    if (failJoin) return false;
    (data[squadId]!['membersUid'] as List).add(member.id);
    return true;
  }

  @override
  Future<void> pauseMemberSharing(String squadId, String memberId) async {
    if (failPause) throw StateError('Offline');
    paused.add(squadId);
  }

  @override
  Future<void> leaveSquad({
    required String squadId,
    required String memberId,
    String? memberName,
  }) async {
    if (failLeave) throw StateError('Offline');
    removed.add(squadId);
    (data[squadId]!['membersUid'] as List).remove(memberId);
  }

  @override
  Future<void> updateMemberLocation({
    required String squadId,
    required String memberId,
    required double lat,
    required double lng,
    int? batteryLevel,
    bool? isOnline,
    bool? shareLocation,
    String? status,
    String? name,
    String? photoUrl,
  }) async {
    updates.add(squadId);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late _GroupsRepo repo;
  late SquadService service;
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    LocationService.enableTestMode = true;
    SquadService.enableTestMode = true;
    AuthService.instance.setCurrentUserForTesting(
      AppUser(uid: 'member', displayName: 'Hopper', isGuest: false),
    );
    repo = _GroupsRepo();
    service = await SquadService.create(repo: repo);
  });
  tearDown(() async {
    service.dispose();
    await repo.directory.close();
    AuthService.instance.setCurrentUserForTesting(null);
    LocationService.enableTestMode = false;
    SquadService.enableTestMode = false;
  });

  test(
    'creating and switching keeps membership and pauses only the old group',
    () async {
      await service.createSquad('Family', 'Gate A');
      final family = service.squadId!;
      await service.createSquad('Friends', 'Gate B');
      final friends = service.squadId!;
      expect(service.groups.map((g) => g.name), ['Family', 'Friends']);
      expect(repo.removed, isEmpty);
      expect(repo.paused, [family]);
      expect(await service.switchGroup(family), isTrue);
      expect(service.squadName, 'Family');
      expect(service.meetupPointName, 'Gate A');
      expect(repo.paused, [family, friends]);
      expect(repo.updates.last, family);
      expect(service.groups.every((group) => group.isHost), isTrue);
    },
  );

  test(
    'failed creation or join restores the previously selected group',
    () async {
      await service.createSquad('Family', 'Gate A');
      final family = service.squadId;
      repo.failCreate = true;
      await service.createSquad('Friends', 'Gate B');
      expect(service.squadId, family);
      expect(service.groups, hasLength(1));
      expect(service.lastError, isNotNull);
      expect(await service.joinSquad('BADCODE'), isFalse);
      expect(service.squadId, family);
      expect(service.meetupPointName, 'Gate A');
      expect(repo.removed, isEmpty);
    },
  );

  test('leave an inactive group keeps selected group and failed leave keeps membership', () async {
    await service.createSquad('Family', 'Gate A');
    final family = service.squadId!;
    await service.createSquad('Friends', 'Gate B');
    final friends = service.squadId;
    repo.failLeave = true;
    expect(await service.leaveGroup(family), isFalse);
    expect(service.groups, hasLength(2));
    repo.failLeave = false;
    expect(await service.leaveGroup(family), isTrue);
    expect(service.squadId, friends);
    expect(service.groups, hasLength(1));
    expect(repo.removed, [family]);
  });

  test('all groups and selected group survive service restart without role changes', () async {
    await service.createSquad('Family', 'Gate A');
    final family = service.squadId!;
    await service.createSquad('Friends', 'Gate B');
    service.dispose();
    service = await SquadService.create(repo: repo);
    expect(service.groups, hasLength(2));
    expect(service.squadName, 'Friends');
    expect(await service.switchGroup(family), isTrue);
    expect(service.members.single.isHost, isTrue);
  });

  test('revoked membership cannot be selected and cached empty directory cannot erase groups', () async {
    await service.createSquad('Family', 'Gate A');
    final family = service.squadId!;
    await service.createSquad('Friends', 'Gate B');
    final friends = service.squadId;
    repo.directory.add((groups: [], fromCache: true));
    await Future<void>.delayed(Duration.zero);
    expect(service.groups, hasLength(2));
    (repo.data[family]!['membersUid'] as List).clear();
    expect(await service.switchGroup(family), isFalse);
    expect(service.squadId, friends);
    expect(service.groups, hasLength(1));
  });

  test('sharing preferences survive switches and another account cannot see cached groups', () async {
    await service.createSquad('Family', 'Gate A');
    final family = service.squadId!;
    service.toggleLocationSharing(false);
    await service.createSquad('Friends', 'Gate B');
    expect(await service.switchGroup(family), isTrue);
    expect(service.isSharingLocation, isFalse);
    expect(service.members.single.shareLocation, isFalse);
    AuthService.instance.setCurrentUserForTesting(AppUser(uid: 'another_member', displayName: 'Another Hopper', isGuest: false));
    await Future<void>.delayed(Duration.zero);
    expect(service.groups, isEmpty);
    expect(service.hasActiveSquad, isFalse);
  });

  test('failed sharing pause preserves selection; leaving selected group retains other memberships', () async {
    await service.createSquad('Family', 'Gate A'); final family = service.squadId!;
    await service.createSquad('Friends', 'Gate B'); final friends = service.squadId;
    repo.failPause = true;
    expect(await service.switchGroup(family), isFalse);
    expect(service.squadId, friends); expect(service.groups, hasLength(2));
    repo.failPause = false;
    expect(await service.leaveSquad(), isTrue);
    expect(service.hasActiveSquad, isFalse); expect(service.groups.single.id, family);
    expect(await service.switchGroup(family), isTrue);
    expect(service.squadName, 'Family');
  });

  testWidgets(
    'group picker switches selected group and shows create and join',
    (tester) async {
      await tester.runAsync(() async {
        await service.createSquad('Family', 'Gate A');
        await service.createSquad('Friends', 'Gate B');
      });
      await tester.pumpWidget(
        ChangeNotifierProvider<SquadService>.value(
          value: service,
          child: MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (ctx) => TextButton(
                  onPressed: () => showModalBottomSheet(
                    context: ctx,
                    builder: (_) => ChangeNotifierProvider<SquadService>.value(
                      value: service,
                      child: GroupManagerSheet(onCreate: () {}, onJoin: () {}),
                    ),
                  ),
                  child: const Text('Manage'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Manage'));
      await tester.pumpAndSettle();
      expect(find.text('Family'), findsOneWidget);
      expect(find.text('Friends'), findsOneWidget);
      expect(find.text('Create group'), findsOneWidget);
      expect(find.text('Join group'), findsOneWidget);
      await tester.runAsync(() async {
        await tester.tap(find.text('Family'));
      for (var i = 0; i < 100 && service.isGroupOperationPending; i++) {
        await Future<void>.delayed(const Duration(milliseconds: 10));
      }
      });
      await tester.pumpAndSettle();
      expect(service.squadName, 'Family');
      expect(find.text('Create group'), findsNothing);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
}
