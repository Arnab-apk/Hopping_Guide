import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kolkata_puja/models/route_chat_models.dart';
import 'package:kolkata_puja/screens/route_chat_screen.dart';
import 'package:kolkata_puja/services/chat_service.dart';

class FakeChatService extends ChatService {
  FakeChatService({this.delayMs = 0}) : super(baseUrl: 'http://mock:8080');

  final int delayMs;
  int askCount = 0;
  String? lastAskedQuestion;

  @override
  Future<ChatStatusSummary> getStatus() async {
    return const ChatStatusSummary(
      closuresCount: 6,
      updatedMinAgo: 2,
      alerts: [
        ChatAlertItem(
          type: 'blockage',
          title: 'College Street Boi Para barricade',
          subtitle: 'Police notice · 8 min ago',
        ),
      ],
    );
  }

  @override
  Future<ChatReply> ask(
    String message, {
    RouteSummary? route,
    String lang = 'auto',
  }) async {
    askCount++;
    lastAskedQuestion = message;
    if (delayMs > 0) {
      await Future.delayed(Duration(milliseconds: delayMs));
    }

    if (message.contains('Howrah') || message.contains('Kumartuli')) {
      return ChatReply(
        answer: 'Walk via Strand Road or take Baghbazar ferry.',
        factsAsOf: DateTime.now(),
        usedLlm: true,
        blocks: const [
          RouteBlock(
            from: 'Howrah Station',
            to: 'Kumartuli Park',
            durationMin: 65,
            distanceM: 5200,
            issues: 1,
          ),
          BlockageBlock(
            kind: 'Police barricade',
            near: 'Rabindra Sarani crossing',
            source: 'Police notice',
            updatedMinAgo: 12,
          ),
          CrowdBlock(
            place: 'Kumartuli Park',
            level: 'high',
            source: 'Live squad reports',
            updatedMinAgo: 9,
          ),
        ],
        actions: const ['show_on_map', 'share_with_group', 'start_walking'],
      );
    }

    return ChatReply(
      answer: 'Walk via Bidhan Sarani. Normal crowd observed.',
      factsAsOf: DateTime.now(),
      usedLlm: false,
    );
  }
}

void main() {
  testWidgets('RouteChatScreen renders redesigned empty state and sends message with cards', (tester) async {
    final fakeService = FakeChatService();

    await tester.pumpWidget(
      MaterialApp(
        home: RouteChatScreen(
          chatService: fakeService,
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Verify Title and Subtitle with real data
    expect(find.text('Route assistant'), findsOneWidget);
    expect(find.textContaining('closures tonight'), findsOneWidget);

    // Verify Empty State elements
    expect(find.text('Where to?'), findsOneWidget);
    expect(find.text('Tonight near you'), findsOneWidget);
    expect(find.text('Try asking'), findsOneWidget);
    expect(find.text('College Street Boi Para barricade'), findsOneWidget);

    // Tap a suggested question from "Try asking"
    expect(find.text('Which pandals are least crowded now?'), findsOneWidget);
    await tester.tap(find.text('Which pandals are least crowded now?'));
    await tester.pump();
    await tester.pumpAndSettle();

    // Verify message sent
    expect(find.text('Which pandals are least crowded now?'), findsOneWidget);
    expect(find.text('Walk via Bidhan Sarani. Normal crowd observed.'), findsOneWidget);
    expect(find.textContaining('Basic answer'), findsOneWidget);
    expect(fakeService.askCount, 1);

    // Test text input field
    final inputFinder = find.byType(TextField);
    expect(inputFinder, findsOneWidget);

    await tester.enterText(inputFinder, 'Howrah to Kumartuli');
    await tester.pump();

    final sendBtnFinder = find.byIcon(Icons.arrow_upward_rounded);
    expect(sendBtnFinder, findsOneWidget);
    await tester.tap(sendBtnFinder);
    await tester.pump();
    await tester.pumpAndSettle();

    // Verify structured cards rendered
    expect(find.text('Howrah Station → Kumartuli Park'), findsOneWidget);
    expect(find.textContaining('~65 min on foot'), findsOneWidget);
    expect(find.textContaining('Police barricade near Rabindra Sarani crossing'), findsOneWidget);
    expect(find.textContaining('Kumartuli Park: Busy'), findsOneWidget);

    // Verify action buttons
    expect(find.text('Show on map'), findsOneWidget);
    expect(find.text('Share with group'), findsOneWidget);
    expect(find.text('Start walking'), findsOneWidget);
    expect(fakeService.askCount, 2);

    // Test New chat button resets screen
    await tester.tap(find.text('New chat'));
    await tester.pumpAndSettle();
    expect(find.text('Where to?'), findsOneWidget);
  });

  testWidgets('RouteChatScreen automatically sends query when initialRoute is passed', (tester) async {
    final fakeService = FakeChatService();
    const route = RouteSummary(
      distanceM: 4200,
      durationS: 3100,
      originName: 'Shyambazar Five Point',
      destinationName: 'Baghbazar Sarbojanin',
    );

    await tester.pumpWidget(
      MaterialApp(
        home: RouteChatScreen(
          chatService: fakeService,
          initialRoute: route,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(fakeService.askCount, 1);
  });
}
