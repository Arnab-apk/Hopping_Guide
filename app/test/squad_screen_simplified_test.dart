import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kolkata_puja/models/squad_member.dart';
import 'package:kolkata_puja/screens/group_screen.dart';
import 'package:kolkata_puja/services/auth_service.dart';
import 'package:kolkata_puja/services/squad_service.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
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

  group('Simplified Squad Screen (4 Cards) Widget Tests', () {
    testWidgets('renders exactly 4 consolidated cards for active squad', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final squadService = SquadService.instance;
      squadService.resetForTesting();
      await squadService.createSquad("Arnab's squad", 'Hatibagan Gate');

      await tester.pumpWidget(createGroupScreenWithSquad(squadService));
      await tester.pumpAndSettle();

      // Card 1: Squad Identity
      expect(find.text("Arnab's squad"), findsOneWidget);
      expect(find.text('1 member hopping together'), findsOneWidget);
      expect(find.text('Invite Companions'), findsAtLeastNWidgets(1));

      // Card 2: Squad Settings
      expect(find.text('Designated Meet-up Point'), findsOneWidget);
      expect(find.text('Hatibagan Gate'), findsOneWidget);
      expect(find.text('Share Live GPS Location'), findsOneWidget);
      expect(find.text('Separation Alert Distance'), findsOneWidget);
      expect(find.textContaining('500 m'), findsOneWidget);

      // Card 3: Squad Members
      expect(find.text('Members (1 Host, 0 Others)'), findsOneWidget);
      expect(find.text('HOST'), findsOneWidget);
      expect(find.textContaining('Tap to view Profile'), findsOneWidget);
      expect(find.text('No companions have joined yet'), findsOneWidget);

      // Card 4: Squad Chat & Media
      expect(find.text('Squad Chat & Media'), findsOneWidget);
      expect(find.text('Open Chat'), findsOneWidget);

      // Verify NO duplicate standalone profile card or redundant top profile button
      expect(find.byTooltip('My Profile'), findsNothing);
      expect(find.text('Parikrama Traveler'), findsNothing);
    });

    testWidgets('renders companion rows with Call and Locate buttons when companions join', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final squadService = SquadService.instance;
      squadService.resetForTesting();
      await squadService.createSquad("South Kolkata Hoppers", 'Deshapriya Park');

      // Inject a companion member using test helper
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
      await tester.pumpAndSettle();

      // Card 3 header updates to 1 Other
      expect(find.text('Members (1 Host, 1 Others)'), findsOneWidget);
      expect(find.text('Rahul Sen'), findsOneWidget);
      expect(find.byTooltip('Call Companion'), findsOneWidget);
      expect(find.byTooltip('Locate on Map'), findsOneWidget);
    });
  });
}
