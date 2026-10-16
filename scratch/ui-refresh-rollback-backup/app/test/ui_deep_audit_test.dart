import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kolkata_puja/config/theme.dart';
import 'package:kolkata_puja/models/pandal.dart';
import 'package:kolkata_puja/services/auth_service.dart';
import 'package:kolkata_puja/services/custom_hopping_trail_service.dart';
import 'package:kolkata_puja/services/location_service.dart';
import 'package:kolkata_puja/services/pandal_user_state_service.dart';
import 'package:kolkata_puja/services/squad_service.dart';
import 'package:kolkata_puja/services/theme_service.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:kolkata_puja/screens/squad_settings_screen.dart';
import 'package:kolkata_puja/screens/squad_chat_screen.dart';
import 'package:kolkata_puja/screens/route_chat_screen.dart';
import 'package:kolkata_puja/screens/group_video_call_screen.dart';
import 'package:kolkata_puja/screens/pandal_detail_screen.dart';
import 'package:kolkata_puja/widgets/user_profile_sheet.dart';
import 'package:kolkata_puja/widgets/app_tutorial_dialog.dart';
import 'package:kolkata_puja/widgets/custom_trail_planner_dialog.dart';
import 'package:kolkata_puja/repositories/local_pandal_repository.dart';
import 'route_chat_screen_test.dart' show FakeChatService;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;
  late Pandal detailPandal;
  const pathProviderChannel = MethodChannel('plugins.flutter.io/path_provider');
  setUpAll(() async {
    detailPandal = (await LocalAssetPandalRepository().all()).first;
    if (const bool.fromEnvironment('CAPTURE_LAUNCH_VISUALS')) {
      final icons = FontLoader('MaterialIcons')
        ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
      await icons.load();
    }
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
    'settings': () => const SquadSettingsScreen(),
    'squad_chat': () => const SquadChatScreen(squadId: 'ui-audit', squadName: 'Friends exploring Kolkata together'),
    'assistant': () => RouteChatScreen(chatService: FakeChatService()),
    'video_lobby': () => const GroupVideoCallScreen(squadId: 'ui-audit', squadName: 'Friends exploring Kolkata together'),
    'profile': () => const Scaffold(body: UserProfileSheet()),
    'tutorial': () => const Scaffold(body: AppTutorialDialog()),
    'planner': () => const Scaffold(body: CustomTrailPlannerDialog(pandals: [])),
    'detail': () => PandalDetailScreen(pandal: detailPandal),
  };
  final displays = <String, ({Size size, double scale})>{
    'phone': (size: const Size(390, 844), scale: 1),
    'compact_large': (size: const Size(320, 640), scale: 2),
    'landscape_large': (size: const Size(844, 390), scale: 1.5),
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
                data: MediaQuery.of(context).copyWith(
                  textScaler: TextScaler.linear(display.value.scale),
                  disableAnimations: const bool.fromEnvironment('CAPTURE_LAUNCH_VISUALS'),
                ),
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
          if (const bool.fromEnvironment('CAPTURE_LAUNCH_VISUALS') && display.key == 'phone') {
            await tester.runAsync(() async {
              final boundary = key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
              final snapshot = await boundary.toImage();
              final bytes = await snapshot.toByteData(format: ui.ImageByteFormat.png);
              final directory = Directory('build/ui-audit/visuals');
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
