enum ChatMessageType {
  text,
  image,
  video;

  static ChatMessageType fromString(String? val) {
    switch (val) {
      case 'image':
        return ChatMessageType.image;
      case 'video':
        return ChatMessageType.video;
      case 'text':
      default:
        return ChatMessageType.text;
    }
  }

  String get value {
    switch (this) {
      case ChatMessageType.image:
        return 'image';
      case ChatMessageType.video:
        return 'video';
      case ChatMessageType.text:
        return 'text';
    }
  }
}

/// Model representing a chat message in a private hopping squad.
class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.squadId,
    required this.senderId,
    required this.senderName,
    required this.timestamp,
    this.senderPhotoUrl,
    this.type = ChatMessageType.text,
    this.text,
    this.mediaUrl,
    this.thumbnailUrl,
  });

  final String id;
  final String squadId;
  final String senderId;
  final String senderName;
  final String? senderPhotoUrl;
  final ChatMessageType type;
  final String? text;
  final String? mediaUrl;
  final String? thumbnailUrl;
  final DateTime timestamp;

  bool isUser(String currentUserId) => senderId == currentUserId;
  bool get isVideo => type == ChatMessageType.video;
  bool get isImage => type == ChatMessageType.image;

  String get senderInitials {
    final parts = senderName.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return senderName.isNotEmpty ? senderName[0].toUpperCase() : 'H';
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'squadId': squadId,
        'senderId': senderId,
        'senderName': senderName,
        'senderPhotoUrl': senderPhotoUrl,
        'type': type.value,
        'text': text,
        'mediaUrl': mediaUrl,
        'media_url': mediaUrl,
        'thumbnailUrl': thumbnailUrl,
        'timestamp': timestamp.millisecondsSinceEpoch,
      };

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    DateTime ts;
    final rawTs = json['timestamp'];
    if (rawTs is int) {
      ts = DateTime.fromMillisecondsSinceEpoch(rawTs);
    } else if (rawTs is String) {
      ts = DateTime.tryParse(rawTs) ?? DateTime.now();
    } else {
      ts = DateTime.now();
    }

    return ChatMessage(
      id: json['id'] as String? ?? 'msg_${DateTime.now().millisecondsSinceEpoch}',
      squadId: json['squadId'] as String? ?? '',
      senderId: json['senderId'] as String? ?? 'unknown',
      senderName: json['senderName'] as String? ?? 'Hopper',
      senderPhotoUrl: json['senderPhotoUrl'] as String? ?? json['sender_photo_url'] as String?,
      type: ChatMessageType.fromString(json['type'] as String?),
      text: json['text'] as String?,
      mediaUrl: json['mediaUrl'] as String? ?? json['media_url'] as String?,
      thumbnailUrl: json['thumbnailUrl'] as String? ?? json['thumbnail_url'] as String?,
      timestamp: ts,
    );
  }
}
