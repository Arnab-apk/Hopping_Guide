import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kolkata_puja/config/theme.dart';
import 'package:kolkata_puja/screens/group_screen.dart';
import 'package:kolkata_puja/screens/helplines_screen.dart';
import 'package:kolkata_puja/screens/map_screen.dart';
import 'package:kolkata_puja/screens/pandal_list_screen.dart';
import 'package:kolkata_puja/screens/routes_screen.dart';
import 'package:kolkata_puja/screens/welcome_screen.dart';
import 'package:kolkata_puja/services/auth_service.dart';
import 'package:kolkata_puja/services/custom_hopping_trail_service.dart';
import 'package:kolkata_puja/services/location_service.dart';
import 'package:kolkata_puja/services/pandal_user_state_service.dart';
import 'package:kolkata_puja/services/squad_service.dart';
import 'package:kolkata_puja/services/theme_service.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;
  const pathProviderChannel = MethodChannel('plugins.flutter.io/path_provider');
  setUpAll(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(pathProviderChannel, (call) async {
      if (call.method == 'getApplicationCacheDirectory') {
        return Directory('build/launch-audit/tile-cache').absolute.path;
      }
      throw MissingPluginException('Unexpected path provider call: ${call.method}');
    });
  });
  tearDownAll(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(pathProviderChannel, null);
  });
  final screens = <String, Widget Function()>{
    'welcome': () => const WelcomeScreen(),
    'map': () => const MapScreen(),
    'pandals': () => const PandalListScreen(),
    'routes': () => const RoutesScreen(),
    'group': () => const GroupScreen(),
    'helplines': () => const HelplinesScreen(),
  };
  final displays = <String, ({Size size, double scale})>{
    'phone': (size: const Size(390, 844), scale: 1),
    'compact': (size: const Size(320, 640), scale: 1),
    'large_text': (size: const Size(390, 844), scale: 2),
    'landscape': (size: const Size(844, 390), scale: 1),
  };
  for (final dark in [true, false]) {
    for (final display in displays.entries) {
      for (final screen in screens.entries) {
        testWidgets('${screen.key} ${display.key} ${dark ? 'dark' : 'light'} has no layout errors', (tester) async {
          final layoutErrors = <FlutterErrorDetails>[];
          final previousErrorHandler = FlutterError.onError;
          FlutterError.onError = (details) {
            layoutErrors.add(details);
            previousErrorHandler?.call(details);
          };
          addTearDown(() => FlutterError.onError = previousErrorHandler);
          SharedPreferences.setMockInitialValues({'has_seen_app_tutorial': true});
          LocationService.enableTestMode = true;
          SquadService.enableTestMode = true;
          final squad = SquadService.instance..resetForTesting();
          final auth = AuthService.instance..setCurrentUserForTesting(null);
          final theme = ThemeService();
          final userState = await PandalUserStateService.create();
          tester.view.physicalSize = display.value.size;
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          final key = GlobalKey();
          await tester.pumpWidget(MultiProvider(
            providers: [
              ChangeNotifierProvider<AuthService>.value(value: auth),
              ChangeNotifierProvider<SquadService>.value(value: squad),
              ChangeNotifierProvider<ThemeService>.value(value: theme),
              ChangeNotifierProvider<LocationService>.value(value: LocationService.instance),
              ChangeNotifierProvider<PandalUserStateService>.value(value: userState),
              ChangeNotifierProvider<CustomHoppingTrailService>.value(value: CustomHoppingTrailService.instance),
            ],
            child: MaterialApp(
              theme: dark ? appDarkTheme : appTheme,
              builder: (context, child) => MediaQuery(
                data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(display.value.scale)),
                child: child!,
              ),
              home: RepaintBoundary(key: key, child: screen.value()),
            ),
          ));
          await tester.runAsync(() async {
            await GoogleFonts.pendingFonts();
            await Future<void>.delayed(const Duration(milliseconds: 100));
          });
          await tester.pump(const Duration(seconds: 2));
          await tester.pump();
          expect(tester.takeException(), isNull,
              reason: layoutErrors.map((details) => details.toString()).join('\n'));
          if (screen.key == 'map' && display.key == 'phone' && dark) {
            final originalCamera = MapCamera.of(tester.element(find.byType(TileLayer)));
            await tester.tap(find.byTooltip('Map Tools & Settings'));
            await tester.pump();
            await tester.pump(const Duration(milliseconds: 350));
            expect(find.text('More map names'), findsOneWidget);
            await tester.tap(find.text('More map names'));
            await tester.runAsync(() async {
              final prefs = await SharedPreferences.getInstance();
              await Future<void>.delayed(Duration.zero);
              expect(prefs.getBool('map_more_place_names'), isFalse);
            });
            await tester.pump();
            await tester.pump(const Duration(milliseconds: 350));
            final switchedCamera = MapCamera.of(tester.element(find.byType(TileLayer)));
            expect(switchedCamera.center, originalCamera.center);
            expect(switchedCamera.zoom, originalCamera.zoom);
            expect(tester.takeException(), isNull);
          }
          if (const bool.fromEnvironment('CAPTURE_LAUNCH_VISUALS') && display.key == 'phone') {
            await tester.runAsync(() async {
              final boundary = key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
              final snapshot = await boundary.toImage();
              final bytes = await snapshot.toByteData(format: ui.ImageByteFormat.png);
              final directory = Directory('build/launch-audit/visuals');
              await directory.create(recursive: true);
              await File('${directory.path}/${screen.key}_${dark ? 'dark' : 'light'}.png').writeAsBytes(bytes!.buffer.asUint8List());
              snapshot.dispose();
            });
          }
          await tester.pumpWidget(const SizedBox());
          // Drain delayed animation starts after disposing the audited screen.
          await tester.pump(const Duration(seconds: 1));
          userState.dispose();
          theme.dispose();
          LocationService.enableTestMode = false;
          SquadService.enableTestMode = false;
        });
      }
    }
  }
}
