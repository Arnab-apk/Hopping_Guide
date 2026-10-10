import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_local_notifications_platform_interface/flutter_local_notifications_platform_interface.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:kolkata_puja/services/live_tracking_enhancements.dart';
import 'package:kolkata_puja/services/location_service.dart';
import 'package:kolkata_puja/services/notification_progress_service.dart';
import 'package:kolkata_puja/services/routing_service.dart';
import 'package:kolkata_puja/services/smart_notification_service.dart';
import 'package:kolkata_puja/services/squad_chat_service.dart';
import 'package:kolkata_puja/services/squad_service.dart';
import 'package:kolkata_puja/utils/app_deep_link.dart';
import 'package:kolkata_puja/widgets/animated_fade_slide.dart';
import 'package:latlong2/latlong.dart';

class _Notifications implements FlutterLocalNotificationsPlugin {
  bool failInitialization = false;
  bool failShow = false;
  int initializations = 0;
  final shown = <({int id, NotificationDetails? details})>[];

  @override
  T? resolvePlatformSpecificImplementation<T extends FlutterLocalNotificationsPlatform>() => null;

  @override
  Future<bool?> initialize(InitializationSettings settings, {
    DidReceiveNotificationResponseCallback? onDidReceiveNotificationResponse,
    DidReceiveBackgroundNotificationResponseCallback? onDidReceiveBackgroundNotificationResponse,
  }) async {
    initializations++;
    if (failInitialization) throw StateError('Native initialization failed');
    return true;
  }

  @override
  Future<NotificationAppLaunchDetails?> getNotificationAppLaunchDetails() async => null;

  @override
  Future<void> show(int id, String? title, String? body, NotificationDetails? details, {String? payload}) async {
    if (failShow) throw StateError('Notifications unavailable');
    shown.add((id: id, details: details));
  }

  @override
  Future<void> cancel(int id, {String? tag}) async {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Position _position(double latitude, DateTime timestamp, {double accuracy = 5}) => Position(
  latitude: latitude, longitude: 88.35, timestamp: timestamp, accuracy: accuracy,
  altitude: 0, altitudeAccuracy: 0, heading: 0, headingAccuracy: 0,
  speed: 1.2, speedAccuracy: 0,
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SquadService.enableTestMode = true;
    LocationService.enableTestMode = true;
  });
  tearDown(() {
    LiveTrackingEngine.instance.stopTracking();
    LocationService.enableTestMode = false;
    SquadService.enableTestMode = false;
  });

  test('external links reject arbitrary hosts and accept registered invite formats', () {
    for (final link in ['pujoparikrama://join?code=PUJA1234', 'pujo://pandal/p1', 'https://sharodiya.com/join/PUJA1234']) {
      expect(AppDeepLink.isSupported(Uri.parse(link)), isTrue);
    }
    for (final link in ['https://attacker.example/join?code=PUJA1234', 'https://sharodiya.com/unrelated?code=x', 'javascript://join?code=x']) {
      expect(AppDeepLink.isSupported(Uri.parse(link)), isFalse);
    }
  });

  test('GPS resumes after returning to the app without an active squad', () {
    final squad = SquadService.instance..resetForTesting();
    squad.didChangeAppLifecycleState(AppLifecycleState.paused);
    expect(LocationService.instance.isPaused, isTrue);
    squad.didChangeAppLifecycleState(AppLifecycleState.resumed);
    expect(LocationService.instance.isPaused, isFalse);
  });

  testWidgets('smart notification initialization can retry and alert failures do not escape', (tester) async {
    final plugin = _Notifications()..failInitialization = true;
    final service = SmartNotificationService(notifications: plugin);
    await service.initialize();
    expect(service.isInitialized, isFalse);
    plugin.failInitialization = false;
    await service.initialize();
    expect(service.isInitialized, isTrue);
    await service.initialize();
    expect(plugin.initializations, 2);
    plugin.failShow = true;
    await service.showCustom(title: 'Arrival', body: 'At destination');
    service.dispose();
    await tester.pump(const Duration(minutes: 3));
  });

  testWidgets('arrival fires once and stopping tracking cancels every periodic timer', (tester) async {
    final plugin = _Notifications();
    final service = SmartNotificationService(notifications: plugin);
    await service.initialize();
    final engine = LiveTrackingEngine.instance;
    const route = WalkingRoute(points: [LatLng(22.55, 88.35), LatLng(22.56, 88.35)], distanceMeters: 1100, durationSeconds: 900);
    await engine.startTracking(destination: route.points.last, destinationName: 'Test Pandal', precomputedRoute: route);
    await engine.startTracking(destination: route.points.last, destinationName: 'Test Pandal', precomputedRoute: route);
    final time = DateTime(2026, 10, 10);
    LocationService.instance.emitTestPosition(_position(22.56, time, accuracy: 200));
    expect(plugin.shown, isEmpty);
    LocationService.instance.emitTestPosition(_position(22.56, time.add(const Duration(seconds: 2))));
    LocationService.instance.emitTestPosition(_position(22.56, time.add(const Duration(seconds: 4))));
    expect(plugin.shown.where((n) => n.id == 100), hasLength(1));
    engine.stopTracking();
    service.dispose();
    await tester.pump(const Duration(minutes: 2));
    expect(tester.takeException(), isNull);
  });

  testWidgets('progress is bounded and completion uses an audible separate channel', (tester) async {
    final plugin = _Notifications();
    final service = NotificationProgressService(notifications: plugin);
    await service.showTrailProgress(currentStep: 20, totalSteps: 3, currentPandalName: 'Current', nextPandalName: 'Next');
    expect(plugin.shown.single.details?.android?.progress, 3);
    expect(plugin.shown.single.details?.android?.maxProgress, 3);
    final progressChannel = plugin.shown.single.details?.android?.channelId;
    await service.showTrailCompleted(totalVisited: 3);
    expect(plugin.shown.last.details?.android?.channelId, isNot(progressChannel));
    expect(plugin.shown.last.details?.android?.ongoing, isFalse);
  });

  test('failed media upload reports failure instead of sending unrelated sample media', () async {
    final service = SquadChatService(httpClient: MockClient((_) async => http.Response('Upload denied', 403)));
    await expectLater(service.uploadSquadMedia(bytes: Uint8List.fromList([1, 2, 3]), fileName: 'photo.jpg', isVideo: false), throwsStateError);
  });

  test('successful media upload preserves the returned secure URL', () async {
    final service = SquadChatService(httpClient: MockClient((_) async => http.Response('{"secure_url":"https://res.cloudinary.com/test/photo.jpg"}', 200)));
    expect(await service.uploadSquadMedia(bytes: Uint8List.fromList([1, 2, 3]), fileName: 'photo.jpg', isVideo: false), 'https://res.cloudinary.com/test/photo.jpg');
  });

  testWidgets('reduced motion shows content immediately and delayed entrances dispose safely', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: MediaQuery(data: MediaQueryData(disableAnimations: true), child: AnimatedFadeSlide(delay: Duration(minutes: 1), child: Text('Ready')))));
    expect(find.text('Ready').hitTestable(), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(minutes: 2));
    expect(tester.takeException(), isNull);
  });

  test('walking pace rounds seconds with correct minute rollover', () {
    final metrics = LiveWalkingMetrics(currentSpeedMps: 1, averageSpeedMps: 1, paceMinPerKm: 9.999, distanceTraveledMeters: 0, etaToDestination: null, isMoving: true, bearingToDestination: null, deviationMeters: 0, isOnRoute: true);
    expect(metrics.formattedPace, '10:00 min/km');
  });
}
