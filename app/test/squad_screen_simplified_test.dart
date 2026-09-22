import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kolkata_puja/models/app_user.dart';
import 'package:kolkata_puja/models/squad_member.dart';
import 'package:kolkata_puja/screens/group_screen.dart';
import 'package:kolkata_puja/screens/squad_settings_screen.dart';
import 'package:kolkata_puja/services/auth_service.dart';
import 'package:kolkata_puja/services/location_service.dart';
import 'package:kolkata_puja/services/squad_service.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    LocationService.enableTestMode = true;
    SquadService.enableTestMode = true;
    AuthService.instance.setCurrentUserForTesting(AppUser.guest());
  });

  tearDown(() {
    LocationService.enableTestMode = false;
    SquadService.enableTestMode = false;
    AuthService.instance.setCurrentUserForTesting(null);
  });

  Widget createGroupScreenWithSquad(SquadService squadService) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<SquadService>.value(value: squadService),
        ChangeNotifierProvider<AuthService>.value(value: AuthService.instance),
      ],
      child: const MaterialApp(
        home: GroupScreen(),
      ),
    );
  }

  group('Radical Minimalism Squad Screen & Settings Tests', () {
    testWidgets('renders only daily-use elements on main squad screen and single invite button', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final squadService = SquadService.instance;
      squadService.resetForTesting();
      await tester.runAsync(() async {
        await squadService.createSquad("Arnab's squad", 'Hatibagan Gate');
      });
      squadService.cancelTimersForTesting();

      await tester.pumpWidget(createGroupScreenWithSquad(squadService));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Header: Chat & Settings action icons with tooltips
      expect(find.byTooltip('Group Chat'), findsOneWidget);
      expect(find.byTooltip('Group Settings'), findsOneWidget);

      // Verify 3-dot overflow menu is completely removed
      expect(find.byType(PopupMenuButton<String>), findsNothing);
      expect(find.byTooltip('Squad Options'), findsNothing);

      // Card 1: Squad Identity
      expect(find.text("Arnab's squad"), findsOneWidget);
      expect(find.text('1 member hopping together'), findsOneWidget);
      // Exactly ONE "Invite Companions" button exists on the entire page
      expect(find.text('Invite Companions'), findsOneWidget);
      expect(find.byTooltip('Copy Group Code'), findsOneWidget);

      // Card 2: GPS Sharing Toggle (Kept on main screen)
      expect(find.text('Share Live GPS Location'), findsOneWidget);

      // Card 3: Squad Members
      expect(find.text('Members (1 Host, 0 Others)'), findsOneWidget);
      expect(find.text('HOST'), findsOneWidget);
      expect(find.textContaining('Tap to view Profile'), findsOneWidget);
      // Empty state shows guidance message without duplicate button
      expect(find.text('No companions yet — share your group code above to get started'), findsOneWidget);

      // Card 4: Squad Chat & Media (tappable card with chevron, no duplicate button)
      expect(find.text('Group Chat & Media'), findsOneWidget);
      expect(find.byIcon(Icons.chevron_right_rounded), findsWidgets);

      // Verify configuration items are NOT cluttering the main screen
      expect(find.text('Designated Meet-up Point'), findsNothing);
      expect(find.text('Separation Alert Distance'), findsNothing);
      expect(find.byIcon(Icons.edit_outlined), findsNothing);
      expect(find.text('Hopping as Guest Hopper'), findsNothing);
    });

    testWidgets('tapping settings gear opens SquadSettingsScreen with configuration items', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final squadService = SquadService.instance;
      squadService.resetForTesting();
      await tester.runAsync(() async {
        await squadService.createSquad("Baghbazar Crawlers", 'Main Gate Entrance');
      });
      squadService.cancelTimersForTesting();

      await tester.pumpWidget(createGroupScreenWithSquad(squadService));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Tap settings gear in AppBar
      await tester.tap(find.byTooltip('Group Settings'));
      await tester.pumpAndSettle();

      // Verify SquadSettingsScreen is shown
      expect(find.byType(SquadSettingsScreen), findsOneWidget);
      expect(find.text('Group Settings'), findsOneWidget);
      expect(find.text('Group name'), findsOneWidget);
      expect(find.text('Baghbazar Crawlers'), findsOneWidget);
      expect(find.text('Designated meet-up point'), findsOneWidget);
      expect(find.text('Main Gate Entrance'), findsOneWidget);
      expect(find.text('Separation alert distance'), findsOneWidget);
      expect(find.text('500 m'), findsOneWidget);
      expect(find.text('Link Google account'), findsOneWidget);
      expect(find.text('Leave group'), findsOneWidget);
    });

    testWidgets('renders companion rows with Call button and distance when companions join', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final squadService = SquadService.instance;
      squadService.resetForTesting();
      await tester.runAsync(() async {
        await squadService.createSquad("South Kolkata Hoppers", 'Deshapriya Park');
      });
      squadService.cancelTimersForTesting();

      // Inject a companion member with phone number
      squadService.addCompanionForTesting(
        SquadMember(
          id: 'companion_rahul',
          name: 'Rahul Sen',
          latitude: 22.5200,
          longitude: 88.3500,
          status: 'At Pandal Gate',
          isHost: false,
          isUser: false,
          batteryLevel: 85,
          phoneNumber: '+91 98310 11223',
          lastSeen: DateTime.now(),
        ),
      );

      await tester.pumpWidget(createGroupScreenWithSquad(squadService));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Card 3 header updates to 1 Other
      expect(find.text('Members (1 Host, 1 Others)'), findsOneWidget);
      expect(find.text('Rahul Sen'), findsOneWidget);
      expect(find.byTooltip('Call Companion'), findsOneWidget);
    });

    testWidgets('hides Call button for companion without phone number', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final squadService = SquadService.instance;
      squadService.resetForTesting();
      await tester.runAsync(() async {
        await squadService.createSquad("North Kolkata Gang", 'Bagbazar Ghat');
      });
      squadService.cancelTimersForTesting();

      // Inject a companion member WITHOUT phone number
      squadService.addCompanionForTesting(
        SquadMember(
          id: 'companion_sourav',
          name: 'Sourav Ganguly',
          latitude: 22.6000,
          longitude: 88.3700,
          status: 'Near idol',
          isHost: false,
          isUser: false,
          batteryLevel: 92,
          phoneNumber: null,
          lastSeen: DateTime.now(),
        ),
      );

      await tester.pumpWidget(createGroupScreenWithSquad(squadService));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Sourav Ganguly'), findsOneWidget);
      // No call button since member has no phone number
      expect(find.byTooltip('Call Companion'), findsNothing);
    });

    testWidgets('renders empty state with Create New Group and Join with Group Code buttons', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final squadService = SquadService.instance;
      squadService.resetForTesting();

      await tester.pumpWidget(createGroupScreenWithSquad(squadService));
      await tester.pumpAndSettle();

      expect(find.text('Hopping Group'), findsOneWidget);
      expect(find.text('Create New Group'), findsOneWidget);
      expect(find.text('Join with Group Code'), findsOneWidget);
      expect(find.text('Hop Together, Never Get Lost'), findsOneWidget);
    });
  });
}
