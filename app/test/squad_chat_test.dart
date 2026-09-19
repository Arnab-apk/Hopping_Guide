import 'package:flutter_test/flutter_test.dart';
import 'package:kolkata_puja/models/chat_message.dart';
import 'package:kolkata_puja/models/squad_member.dart';
import 'package:kolkata_puja/services/squad_chat_service.dart';
import 'package:kolkata_puja/services/squad_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('ChatMessage Model Tests', () {
    test('serializes and deserializes text message correctly', () {
      final msg = ChatMessage(
        id: 'msg_101',
        squadId: 'SQUAD123',
        senderId: 'user_arnab',
        senderName: 'Arnab Saha',
        timestamp: DateTime(2026, 9, 18, 12, 0, 0),
        text: 'Meeting at Hatibagan gate in 10 mins!',
        type: ChatMessageType.text,
      );

      final json = msg.toJson();
      expect(json['id'], equals('msg_101'));
      expect(json['type'], equals('text'));
      expect(json['text'], contains('Hatibagan'));

      final parsed = ChatMessage.fromJson(json);
      expect(parsed.id, equals('msg_101'));
      expect(parsed.type, equals(ChatMessageType.text));
      expect(parsed.isVideo, isFalse);
      expect(parsed.isImage, isFalse);
      expect(parsed.senderInitials, equals('AS'));
    });

    test('serializes and deserializes image message correctly', () {
      final msg = ChatMessage(
        id: 'msg_102',
        squadId: 'SQUAD123',
        senderId: 'user_arnab',
        senderName: 'Arnab Saha',
        timestamp: DateTime(2026, 9, 18, 12, 5, 0),
        mediaUrl: 'https://res.cloudinary.com/pujoparikrama/image/upload/v1/pandal.jpg',
        type: ChatMessageType.image,
      );

      final json = msg.toJson();
      expect(json['type'], equals('image'));
      expect(json['mediaUrl'], contains('cloudinary'));

      final parsed = ChatMessage.fromJson(json);
      expect(parsed.type, equals(ChatMessageType.image));
      expect(parsed.isImage, isTrue);
      expect(parsed.isVideo, isFalse);
    });

    test('serializes and deserializes video message correctly', () {
      final msg = ChatMessage(
        id: 'msg_103',
        squadId: 'SQUAD123',
        senderId: 'user_arnab',
        senderName: 'Arnab Saha',
        timestamp: DateTime(2026, 9, 18, 12, 10, 0),
        mediaUrl: 'https://res.cloudinary.com/pujoparikrama/video/upload/v1/dhak.mp4',
        thumbnailUrl: 'https://res.cloudinary.com/pujoparikrama/video/upload/v1/dhak.jpg',
        type: ChatMessageType.video,
      );

      final json = msg.toJson();
      expect(json['type'], equals('video'));
      expect(json['thumbnailUrl'], isNotNull);

      final parsed = ChatMessage.fromJson(json);
      expect(parsed.type, equals(ChatMessageType.video));
      expect(parsed.isVideo, isTrue);
      expect(parsed.isImage, isFalse);
    });

    test('senderInitials handles single-word and empty names', () {
      final single = ChatMessage(
        id: '1',
        squadId: 'S',
        senderId: 'u1',
        senderName: 'Hopper',
        timestamp: DateTime.now(),
      );
      expect(single.senderInitials, equals('H'));

      final empty = ChatMessage(
        id: '2',
        squadId: 'S',
        senderId: 'u2',
        senderName: '',
        timestamp: DateTime.now(),
      );
      expect(empty.senderInitials, equals('H'));
    });
  });

  group('SquadChatService In-Memory Fallback Tests', () {
    test('sendText and messagesStream stream correctly in demo/fallback mode', () async {
      final chatService = SquadChatService();

      final stream = chatService.messagesStream('TEST_SQUAD');
      final futureMessage = stream.first;

      await chatService.sendText(
        'TEST_SQUAD',
        senderId: 'arnab_id',
        senderName: 'Arnab',
        text: 'Shubho Mahalaya everyone!',
      );

      final messages = await futureMessage;
      expect(messages, isNotEmpty);
      expect(messages.first.text, equals('Shubho Mahalaya everyone!'));
      expect(messages.first.senderName, equals('Arnab'));

      // Latest message accessor
      final latest = chatService.getLatestMessage('TEST_SQUAD');
      expect(latest, isNotNull);
      expect(latest?.text, equals('Shubho Mahalaya everyone!'));
    });

    test('sendMedia attaches photo with Cloudinary URL', () async {
      final chatService = SquadChatService();

      await chatService.sendMedia(
        'TEST_SQUAD_MEDIA',
        senderId: 'arnab_id',
        senderName: 'Arnab',
        mediaUrl: 'https://images.unsplash.com/photo-durga-puja.jpg',
        isVideo: false,
      );

      final latest = chatService.getLatestMessage('TEST_SQUAD_MEDIA');
      expect(latest, isNotNull);
      expect(latest?.isImage, isTrue);
      expect(latest?.mediaUrl, contains('unsplash.com'));
    });
  });

  group('SquadService Comma & Separation Threshold Tests', () {
    test('squad name comma typo is automatically sanitized to apostrophe', () async {
      final squadService = SquadService.instance;
      squadService.resetForTesting();
      await squadService.createSquad('Arnab,s squad', 'Hatibagan Crossing');

      expect(squadService.squadName, equals("Arnab's squad"));

      await squadService.updateSquadName('Kolkata Pujo,s Best');
      expect(squadService.squadName, equals("Kolkata Pujo's Best"));
    });

    test('separation alert threshold defaults to 500 m and can be updated', () async {
      final squadService = SquadService.instance;
      expect(squadService.separationThresholdMeters, equals(500));

      await squadService.setSeparationThreshold(250);
      expect(squadService.separationThresholdMeters, equals(250));

      await squadService.setSeparationThreshold(1000);
      expect(squadService.separationThresholdMeters, equals(1000));
    });

    test('squad member model preserves optional phone number', () {
      final member = SquadMember(
        id: 'member_1',
        name: 'Sayantan',
        latitude: 22.57,
        longitude: 88.36,
        status: 'Nearby',
        lastSeen: DateTime.now(),
        phoneNumber: '+91 98300 12345',
      );

      expect(member.phoneNumber, equals('+91 98300 12345'));

      final json = member.toJson();
      expect(json['phone_number'], equals('+91 98300 12345'));

      final fromJson = SquadMember.fromJson(json);
      expect(fromJson.phoneNumber, equals('+91 98300 12345'));
    });
  });
}
