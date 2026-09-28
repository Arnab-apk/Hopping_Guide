/// Models for the UMA Route Assistant Chatbot.
/// Follows the specification in docs/features/ROUTE_CHATBOT_IMPLEMENTATION.md.

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
    this.facts,
  });

  final String answer;
  final DateTime? factsAsOf;
  final bool usedLlm;
  final bool isRateLimited;
  final bool isError;
  final bool fromCache;
  final List<String> suggestions;
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

    return ChatReply(
      answer: json['answer'] as String? ?? 'No response available.',
      factsAsOf: asOf ?? DateTime.now(),
      usedLlm: json['used_llm'] as bool? ?? false,
      isRateLimited: json['rate_limited'] as bool? ?? false,
      fromCache: json['cached'] as bool? ?? false,
      suggestions: suggestions,
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

  factory ChatReply.fallback(String answer, {DateTime? factsAsOf, List<String>? suggestions}) {
    return ChatReply(
      answer: answer,
      factsAsOf: factsAsOf ?? DateTime.now(),
      usedLlm: false,
      suggestions: suggestions ?? const [],
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
