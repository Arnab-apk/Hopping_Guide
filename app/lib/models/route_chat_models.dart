library;

/// Models for the UMA Route Assistant Chatbot.
/// Follows the specification in docs/features/ROUTE_CHATBOT_IMPLEMENTATION.md
/// and docs/features/GROUP_AND_CHAT_UI_REDESIGN.md.

/// Lightweight route summary passed from on-device routing engine (GemKit / OSRM).
class RouteSummary {
  const RouteSummary({
    required this.distanceM,
    required this.durationS,
    this.polyline,
    this.mode = 'pedestrian',
    this.originName,
    this.destinationName,
  });

  final int distanceM;
  final int durationS;
  final String? polyline;
  final String mode;
  final String? originName;
  final String? destinationName;

  int get durationMin => (durationS / 60).round();
  double get distanceKm => distanceM / 1000.0;

  Map<String, dynamic> toJson() => {
        'distance_m': distanceM,
        'duration_s': durationS,
        if (polyline != null) 'polyline': polyline,
        'mode': mode,
        if (originName != null) 'origin': originName,
        if (destinationName != null) 'destination': destinationName,
      };

  factory RouteSummary.fromJson(Map<String, dynamic> json) {
    return RouteSummary(
      distanceM: (json['distance_m'] as num?)?.toInt() ?? 0,
      durationS: (json['duration_s'] as num?)?.toInt() ?? 0,
      polyline: json['polyline'] as String?,
      mode: json['mode'] as String? ?? 'pedestrian',
      originName: json['origin'] as String?,
      destinationName: json['destination'] as String?,
    );
  }
}

/// Base sealed class for structured fact blocks that render as cards below the answer.
sealed class ChatFactBlock {
  const ChatFactBlock();

  factory ChatFactBlock.fromJson(Map<String, dynamic> json) {
    final type = json['type'] as String? ?? '';
    switch (type) {
      case 'route':
        return RouteBlock.fromJson(json);
      case 'blockage':
        return BlockageBlock.fromJson(json);
      case 'crowd':
        return CrowdBlock.fromJson(json);
      case 'station':
        return StationBlock.fromJson(json);
      default:
        return UnknownBlock(type, json);
    }
  }
}

class RouteBlock extends ChatFactBlock {
  const RouteBlock({
    required this.from,
    required this.to,
    required this.durationMin,
    required this.distanceM,
    this.issues = 0,
  });

  final String from;
  final String to;
  final int durationMin;
  final int distanceM;
  final int issues;

  double get distanceKm => distanceM / 1000.0;

  factory RouteBlock.fromJson(Map<String, dynamic> json) => RouteBlock(
        from: json['from'] as String? ?? 'Origin',
        to: json['to'] as String? ?? 'Destination',
        durationMin: (json['duration_min'] as num?)?.toInt() ?? 0,
        distanceM: (json['distance_m'] as num?)?.toInt() ?? 0,
        issues: (json['issues'] as num?)?.toInt() ?? 0,
      );
}

class BlockageBlock extends ChatFactBlock {
  const BlockageBlock({
    required this.kind,
    required this.near,
    required this.source,
    this.confirmations = 0,
    this.updatedMinAgo = 0,
    this.isStale = false,
  });

  final String kind;
  final String near;
  final String source;
  final int confirmations;
  final int updatedMinAgo;
  final bool isStale;

  factory BlockageBlock.fromJson(Map<String, dynamic> json) => BlockageBlock(
        kind: json['kind'] as String? ?? 'Barricade',
        near: json['near'] as String? ?? 'Nearby area',
        source: json['source'] as String? ?? 'Police notice',
        confirmations: (json['confirmations'] as num?)?.toInt() ?? 0,
        updatedMinAgo: (json['updated_min_ago'] as num?)?.toInt() ?? 0,
        isStale: json['stale'] as bool? ?? false,
      );
}

class CrowdBlock extends ChatFactBlock {
  const CrowdBlock({
    required this.place,
    required this.level,
    required this.source,
    this.updatedMinAgo = 0,
  });

  final String place;
  final String level; // low, moderate, high, packed
  final String source;
  final int updatedMinAgo;

  String get levelLabel {
    switch (level.toLowerCase()) {
      case 'low':
        return 'Quiet';
      case 'moderate':
        return 'Moderate';
      case 'high':
        return 'Busy';
      case 'packed':
        return 'Packed';
      default:
        return 'Normal';
    }
  }

  factory CrowdBlock.fromJson(Map<String, dynamic> json) => CrowdBlock(
        place: json['place'] as String? ?? 'Pandal',
        level: json['level'] as String? ?? 'moderate',
        source: json['source'] as String? ?? 'Live squad aggregate',
        updatedMinAgo: (json['updated_min_ago'] as num?)?.toInt() ?? 0,
      );
}

class StationBlock extends ChatFactBlock {
  const StationBlock({
    required this.name,
    required this.kind,
    required this.distanceM,
  });

  final String name;
  final String kind; // Metro, Railway
  final int distanceM;

  factory StationBlock.fromJson(Map<String, dynamic> json) => StationBlock(
        name: json['name'] as String? ?? 'Station',
        kind: json['kind'] as String? ?? 'Transit',
        distanceM: (json['distance_m'] as num?)?.toInt() ?? 0,
      );
}

class UnknownBlock extends ChatFactBlock {
  const UnknownBlock(this.rawType, this.rawJson);
  final String rawType;
  final Map<String, dynamic> rawJson;
}

/// Alert item shown in the empty state of Route Assistant.
class ChatAlertItem {
  const ChatAlertItem({
    required this.type,
    required this.title,
    required this.subtitle,
    this.level,
  });

  final String type; // blockage, crowd
  final String title;
  final String subtitle;
  final String? level;

  factory ChatAlertItem.fromJson(Map<String, dynamic> json) => ChatAlertItem(
        type: json['type'] as String? ?? 'blockage',
        title: json['title'] as String? ?? '',
        subtitle: json['subtitle'] as String? ?? '',
        level: json['level'] as String?,
      );
}

/// Live status metadata for the top header & empty state.
class ChatStatusSummary {
  const ChatStatusSummary({
    this.closuresCount = 6,
    this.updatedMinAgo = 2,
    this.alerts = const [],
  });

  final int closuresCount;
  final int updatedMinAgo;
  final List<ChatAlertItem> alerts;

  factory ChatStatusSummary.fromJson(Map<String, dynamic> json) {
    final rawAlerts = json['alerts'] as List?;
    final alerts = rawAlerts != null
        ? rawAlerts
            .map((a) => ChatAlertItem.fromJson(a as Map<String, dynamic>))
            .toList()
        : <ChatAlertItem>[];

    return ChatStatusSummary(
      closuresCount: (json['closures_count'] as num?)?.toInt() ?? 6,
      updatedMinAgo: (json['updated_min_ago'] as num?)?.toInt() ?? 2,
      alerts: alerts,
    );
  }

  static const ChatStatusSummary fallback = ChatStatusSummary(
    closuresCount: 6,
    updatedMinAgo: 2,
    alerts: [
      ChatAlertItem(
        type: 'blockage',
        title: 'College Street Boi Para barricade',
        subtitle: 'Police notice · 8 min ago',
      ),
      ChatAlertItem(
        type: 'blockage',
        title: 'Rabindra Sarani crossing barricade',
        subtitle: 'Police notice · 12 min ago',
      ),
      ChatAlertItem(
        type: 'crowd',
        title: 'Kumartuli: Busy',
        subtitle: 'Live squad reports · 9 min ago',
        level: 'high',
      ),
    ],
  );
}

/// Structured reply returned by the Route Assistant server or local fallback.
class ChatReply {
  const ChatReply({
    required this.answer,
    this.factsAsOf,
    this.usedLlm = false,
    this.isRateLimited = false,
    this.isError = false,
    this.fromCache = false,
    this.suggestions = const [],
    this.blocks = const [],
    this.actions = const [],
    this.facts,
  });

  final String answer;
  final DateTime? factsAsOf;
  final bool usedLlm;
  final bool isRateLimited;
  final bool isError;
  final bool fromCache;
  final List<String> suggestions;
  final List<ChatFactBlock> blocks;
  final List<String> actions;
  final Map<String, dynamic>? facts;

  factory ChatReply.fromJson(Map<String, dynamic> json) {
    DateTime? asOf;
    final rawAsOf = json['facts_as_of'] ?? json['generated_at'];
    if (rawAsOf is String) {
      asOf = DateTime.tryParse(rawAsOf);
    }

    final rawSuggestions = json['suggestions'] as List?;
    final suggestions = rawSuggestions != null
        ? rawSuggestions.map((s) => s.toString()).toList()
        : <String>[];

    final rawBlocks = json['blocks'] as List?;
    final blocks = rawBlocks != null
        ? rawBlocks
            .whereType<Map<String, dynamic>>()
            .map(ChatFactBlock.fromJson)
            .toList()
        : <ChatFactBlock>[];

    final rawActions = json['actions'] as List?;
    final actions = rawActions != null
        ? rawActions.map((a) => a.toString()).toList()
        : <String>[];

    return ChatReply(
      answer: json['answer'] as String? ?? 'No response available.',
      factsAsOf: asOf ?? DateTime.now(),
      usedLlm: json['used_llm'] as bool? ?? false,
      isRateLimited: json['rate_limited'] as bool? ?? false,
      fromCache: json['cached'] as bool? ?? false,
      suggestions: suggestions,
      blocks: blocks,
      actions: actions,
      facts: json['facts'] as Map<String, dynamic>?,
    );
  }

  factory ChatReply.rateLimited({String? message}) {
    return ChatReply(
      answer: message ??
          'Hourly question limit reached (to keep UMA free for everyone). '
              'Please try again shortly or use quick routes on the map!',
      factsAsOf: DateTime.now(),
      usedLlm: false,
      isRateLimited: true,
    );
  }

  factory ChatReply.error({String? message}) {
    return ChatReply(
      answer: message ??
          'Unable to reach UMA Route Assistant server right now. '
              'Showing local verified station & pandal data.',
      factsAsOf: DateTime.now(),
      usedLlm: false,
      isError: true,
    );
  }

  factory ChatReply.fallback(
    String answer, {
    DateTime? factsAsOf,
    List<String>? suggestions,
    List<ChatFactBlock>? blocks,
    List<String>? actions,
  }) {
    return ChatReply(
      answer: answer,
      factsAsOf: factsAsOf ?? DateTime.now(),
      usedLlm: false,
      suggestions: suggestions ?? const [],
      blocks: blocks ?? const [],
      actions: actions ?? const [],
    );
  }
}

/// Message element rendered inside the Route Assistant chat interface.
class RouteChatMessage {
  RouteChatMessage({
    required this.id,
    required this.text,
    required this.isUser,
    required this.timestamp,
    this.factsAsOf,
    this.usedLlm = false,
    this.isRateLimited = false,
    this.isError = false,
    this.suggestions = const [],
    this.blocks = const [],
    this.actions = const [],
    this.routeSummary,
  });

  final String id;
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final DateTime? factsAsOf;
  final bool usedLlm;
  final bool isRateLimited;
  final bool isError;
  final List<String> suggestions;
  final List<ChatFactBlock> blocks;
  final List<String> actions;
  final RouteSummary? routeSummary;

  String get formattedTime {
    final hour = timestamp.hour.toString().padLeft(2, '0');
    final minute = timestamp.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  String? get freshnessText {
    if (factsAsOf == null) return null;
    final diff = DateTime.now().difference(factsAsOf!);
    final min = diff.inMinutes;
    if (min <= 1) return 'Updated just now';
    if (min < 60) return 'Updated $min min ago';
    final hr = diff.inHours;
    return 'Updated $hr hr ago';
  }
}
