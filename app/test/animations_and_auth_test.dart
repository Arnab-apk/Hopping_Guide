import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kolkata_puja/config/theme.dart';
import 'package:kolkata_puja/models/app_user.dart';
import 'package:kolkata_puja/services/auth_service.dart';
import 'package:latlong2/latlong.dart';
import 'package:kolkata_puja/models/pandal.dart';
import 'package:kolkata_puja/utils/constants.dart';
import 'package:kolkata_puja/services/routing_service.dart';
import 'package:kolkata_puja/services/location_service.dart';
import 'package:kolkata_puja/services/theme_service.dart';
import 'package:kolkata_puja/models/squad_member.dart';
import 'package:kolkata_puja/services/squad_service.dart';
import 'package:kolkata_puja/widgets/animated_fade_slide.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AnimatedFadeSlide Widget Tests', () {
    testWidgets('renders child widget and animates fade and slide', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AnimatedFadeSlide(
              child: Text('Animated Pandal Card'),
            ),
          ),
        ),
      );

      // Verify child is rendered
      expect(find.text('Animated Pandal Card'), findsOneWidget);

      // Advance animation timer
      await tester.pump(const Duration(milliseconds: 200));
      expect(find.text('Animated Pandal Card'), findsOneWidget);

      await tester.pumpAndSettle();
      expect(find.text('Animated Pandal Card'), findsOneWidget);
    });

    testWidgets('respects custom delay before animating', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AnimatedFadeSlide(
              delay: Duration(milliseconds: 100),
              child: Text('Delayed Card'),
            ),
          ),
        ),
      );

      // At t=0, opacity is 0.0
      expect(find.text('Delayed Card'), findsOneWidget);

      // Advance past delay
      await tester.pump(const Duration(milliseconds: 150));
      await tester.pumpAndSettle();

      expect(find.text('Delayed Card'), findsOneWidget);
    });
  });

  group('AuthService and AuthResult Tests', () {
    test('guest sign in sets active user model correctly', () async {
      final user = await AuthService.instance.signInAsGuest();
      expect(user.isGuest, true);
      expect(user.displayName, 'Guest Pujo Hopper');
      expect(AuthService.instance.isAuthenticated, true);
      expect(AuthService.instance.currentUserModel?.isGuest, true);
    });

    test('AuthResult types instantiate correctly', () {
      final guest = AppUser.guest();
      final success = AuthResult.success(guest);
      expect(success.success, true);
      expect(success.isCancelled, false);
      expect(success.user, guest);

      const cancelled = AuthResult.cancelled();
      expect(cancelled.success, false);
      expect(cancelled.isCancelled, true);
      expect(cancelled.user, null);

      const failure = AuthResult.failure('Network timeout');
      expect(failure.success, false);
      expect(failure.isCancelled, false);
      expect(failure.errorMessage, 'Network timeout');
    });

    test('Google sign in sets Google user model, avatar, and email correctly', () async {
      final user = await AuthService.instance.signInWithGoogleProfile(
        displayName: 'Arnab Mukherjee',
        email: 'arnab.puja@gmail.com',
        photoUrl: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=200',
      );
      expect(user.isGuest, false);
      expect(user.displayName, 'Arnab Mukherjee');
      expect(user.email, 'arnab.puja@gmail.com');
      expect(AuthService.instance.isGoogleUser, true);
      expect(user.initials, 'AM');

      // Test update profile
      await AuthService.instance.updateProfile(displayName: 'Arnab M.');
      expect(AuthService.instance.currentUserModel?.displayName, 'Arnab M.');
    });
  });

  group('Theme Page Transitions Tests', () {
    test('theme includes modern PredictiveBackPageTransitionsBuilder for Android', () {
      final darkBuilders = appDarkTheme.pageTransitionsTheme.builders;
      expect(darkBuilders[TargetPlatform.android], isA<PredictiveBackPageTransitionsBuilder>());
      expect(darkBuilders[TargetPlatform.iOS], isA<CupertinoPageTransitionsBuilder>());

      final lightBuilders = appTheme.pageTransitionsTheme.builders;
      expect(lightBuilders[TargetPlatform.android], isA<PredictiveBackPageTransitionsBuilder>());
    });
  });

  group('ThemeService Tests', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('defaults to ThemeMode.dark', () async {
      final service = ThemeService();
      await service.init();
      expect(service.themeMode, ThemeMode.dark);
      expect(service.isDarkMode, true);
    });

    test('toggleTheme toggles between dark and light mode and persists', () async {
      final service = ThemeService();
      await service.init();
      expect(service.isDarkMode, true);

      await service.toggleTheme();
      expect(service.themeMode, ThemeMode.light);
      expect(service.isDarkMode, false);

      await service.toggleTheme();
      expect(service.themeMode, ThemeMode.dark);
      expect(service.isDarkMode, true);
    });

    test('loads saved light theme mode from SharedPreferences', () async {
      SharedPreferences.setMockInitialValues({'app_theme_mode': 'light'});
      final service = ThemeService();
      await service.init();
      expect(service.themeMode, ThemeMode.light);
      expect(service.isDarkMode, false);
    });
  });

  group('RoutingService & WalkingRoute Tests', () {
    final testPandal1 = Pandal(
      id: 'p1',
      name: 'Hatibagan Sarbojanin',
      zone: KolkataZone.northKolkata,
      lat: 22.5995,
      lng: 88.3725,
      theme: 'Traditional Art',
      description: 'Heritage pandal',
      imageUrl: '',
      timings: '24 Hours',
    );

    final testPandal2 = Pandal(
      id: 'p2',
      name: 'Ekdalia Evergreen',
      zone: KolkataZone.southKolkata,
      lat: 22.5185,
      lng: 88.3635,
      theme: 'Chandelier Palace',
      description: 'South Kolkata classic',
      imageUrl: '',
      timings: '24 Hours',
    );

    test('findNearestPandal finds the geographically closest pandal', () {
      // User near Hatibagan in North Kolkata (22.5990, 88.3720)
      const userPos = LatLng(22.5990, 88.3720);
      final nearest = RoutingService.instance.findNearestPandal(
        userPosition: userPos,
        pandals: [testPandal1, testPandal2],
      );

      expect(nearest, isNotNull);
      expect(nearest!.id, 'p1');
      expect(nearest.name, 'Hatibagan Sarbojanin');
    });

    test('findNearestPandal returns null for empty list', () {
      final nearest = RoutingService.instance.findNearestPandal(
        userPosition: const LatLng(22.5, 88.3),
        pandals: [],
      );
      expect(nearest, isNull);
    });

    test('WalkingRoute formatting outputs human-readable units', () {
      final shortRoute = WalkingRoute(
        targetPandal: testPandal1,
        points: const [LatLng(22.59, 88.37), LatLng(22.5995, 88.3725)],
        distanceMeters: 450,
        durationSeconds: 340,
      );
      expect(shortRoute.formattedDistance, '450 m');
      expect(shortRoute.formattedDuration, '6 mins walk');

      final longRoute = WalkingRoute(
        targetPandal: testPandal2,
        points: const [LatLng(22.59, 88.37), LatLng(22.5185, 88.3635)],
        distanceMeters: 8500,
        durationSeconds: 6600, // 110 mins = 1h 50m
      );
      expect(longRoute.formattedDistance, '8.5 km');
      expect(longRoute.formattedDuration, '1h 50m walk');

      final fiftyKmRoute = WalkingRoute(
        targetPandal: testPandal2,
        points: const [LatLng(22.88, 88.37), LatLng(22.52, 88.36)],
        distanceMeters: 50000,
        durationSeconds: 50000 / 1.25, // 40000s = 667 mins = 11h 7m
        drivingDurationSeconds: 3000, // 50 mins driving
      );
      expect(fiftyKmRoute.formattedDistance, '50.0 km');
      expect(fiftyKmRoute.formattedDuration, '50 mins drive/transit · 11h 7m walk');
    });

    test('getWalkingRoute fallback generates valid 2-point corridor when offline', () async {
      final route = await RoutingService.instance.getWalkingRoute(
        start: const LatLng(22.5900, 88.3700),
        destination: testPandal1,
      );

      expect(route.targetPandal?.id, 'p1');
      expect(route.destinationTitle, 'Hatibagan Sarbojanin');
      expect(route.points.length, greaterThanOrEqualTo(2));
      expect(route.distanceMeters, greaterThan(0));
      expect(route.durationSeconds, greaterThan(0));
    });

    test('getWalkingRouteToPoint generates route to squad member coordinates', () async {
      final route = await RoutingService.instance.getWalkingRouteToPoint(
        start: const LatLng(22.5900, 88.3700),
        destination: const LatLng(22.6035, 88.3670),
        destinationName: 'Priya Sen',
      );

      expect(route.destinationTitle, 'Priya Sen');
      expect(route.points.length, greaterThanOrEqualTo(2));
      expect(route.distanceMeters, greaterThan(0));
    });
  });

  group('LocationService Live Tracking State Tests', () {
    test('stopLiveTracking marks isLiveTracking false', () {
      LocationService.instance.stopLiveTracking();
      expect(LocationService.instance.isLiveTracking, false);
    });
  });

  group('SquadMember & SquadService Live Tracking Tests', () {
    test('SquadMember model calculates initials and serializes correctly', () {
      final member = SquadMember(
        id: 'test_1',
        name: 'Priya Sen',
        latitude: 22.6035,
        longitude: 88.3670,
        status: 'Near Bagbazar',
        lastSeen: DateTime.now(),
        batteryLevel: 88,
      );

      expect(member.initials, 'PS');
      expect(member.batteryLevel, 88);
      expect(member.avatarColor, isNotNull);

      final json = member.toJson();
      expect(json['name'], 'Priya Sen');
      expect(json['lat'], 22.6035);

      final revived = SquadMember.fromJson(json);
      expect(revived.name, member.name);
      expect(revived.latitude, member.latitude);
    });

    test('SquadMember serializes and deserializes Google photoUrl correctly', () {
      final member = SquadMember(
        id: 'member_google',
        name: 'Arnab Mukherjee',
        latitude: 22.58,
        longitude: 88.36,
        status: 'Online • Hopping',
        lastSeen: DateTime(2026, 10, 20, 20, 0),
        photoUrl: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb',
      );

      expect(member.photoUrl, 'https://images.unsplash.com/photo-1534528741775-53994a69daeb');
      final json = member.toJson();
      expect(json['photo_url'], 'https://images.unsplash.com/photo-1534528741775-53994a69daeb');

      final revived = SquadMember.fromJson(json);
      expect(revived.photoUrl, 'https://images.unsplash.com/photo-1534528741775-53994a69daeb');
    });

    test('SquadService addDemoCompanions populates companions with Google DPs', () {
      final squad = SquadService.instance;
      squad.createSquad('Bagbazar Hoppers', 'North Gate');
      expect(squad.companionMembers, isEmpty);

      squad.addDemoCompanions();
      expect(squad.companionMembers.length, 2);
      for (final companion in squad.companionMembers) {
        expect(companion.photoUrl, isNotNull);
        expect(companion.photoUrl, startsWith('http'));
      }
    });

    test('SquadService createSquad starts with only host and 0 companions', () {
      final squad = SquadService.instance;
      squad.createSquad('Bagbazar Hoppers', 'North Gate');

      expect(squad.hasActiveSquad, isTrue);
      expect(squad.squadName, 'Bagbazar Hoppers');
      expect(squad.meetupPointName, 'North Gate');
      expect(squad.squadCode, startsWith('PUJA'));
      expect(squad.members.length, 1);
      expect(squad.companionMembers, isEmpty);
    });

    test('SquadService updateUserLocation updates user member coordinates', () {
      final squad = SquadService.instance;
      squad.updateUserLocation(22.5800, 88.3600);

      final userMember = squad.members.firstWhere((m) => m.isUser);
      expect(userMember.latitude, 22.5800);
      expect(userMember.longitude, 88.3600);
    });

    test('SquadService focusMember and clearFocus manage camera target', () {
      final squad = SquadService.instance;
      squad.focusMember('member_peer_1');
      expect(squad.focusedMemberId, 'member_peer_1');

      squad.clearFocus();
      expect(squad.focusedMemberId, isNull);
    });

    test('SquadService toggleLocationSharing and toggleSquadOnMap change state', () {
      final squad = SquadService.instance;
      squad.toggleLocationSharing(false);
      expect(squad.isSharingLocation, isFalse);
      squad.toggleLocationSharing(true);
      expect(squad.isSharingLocation, isTrue);

      squad.toggleSquadOnMap(false);
      expect(squad.showSquadOnMap, isFalse);
      squad.toggleSquadOnMap(true);
      expect(squad.showSquadOnMap, isTrue);
    });

    test('SquadService leaveSquad resets all squad metadata', () {
      final squad = SquadService.instance;
      squad.leaveSquad();

      expect(squad.hasActiveSquad, isFalse);
      expect(squad.squadCode, isNull);
      expect(squad.squadName, isNull);
      expect(squad.members, isEmpty);
    });
  });
}
