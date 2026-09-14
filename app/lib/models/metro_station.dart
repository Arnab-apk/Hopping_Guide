import 'package:flutter/material.dart';

/// Metro line classification in Kolkata Metro Rail network
enum KolkataMetroLine {
  blue(
    code: 'blue',
    label: 'Blue Line (Line 1)',
    corridor: 'Dakshineswar ⇄ Kavi Subhash',
    color: Color(0xFF1976D2),
  ),
  green(
    code: 'green',
    label: 'Green Line (Line 2)',
    corridor: 'Howrah Maidan ⇄ Sector V',
    color: Color(0xFF2E7D32),
  ),
  purple(
    code: 'purple',
    label: 'Purple Line (Line 3)',
    corridor: 'Joka ⇄ Majerhat',
    color: Color(0xFF7B1FA2),
  ),
  orange(
    code: 'orange',
    label: 'Orange Line (Line 6)',
    corridor: 'Kavi Subhash ⇄ Hemanta Mukhopadhyay (Ruby)',
    color: Color(0xFFE65100),
  );

  const KolkataMetroLine({
    required this.code,
    required this.label,
    required this.corridor,
    required this.color,
  });

  final String code;
  final String label;
  final String corridor;
  final Color color;
}

/// Represents a distinct Kolkata Metro Station entity with precise coordinates
class MetroStation {
  const MetroStation({
    required this.id,
    required this.name,
    required this.line,
    required this.latitude,
    required this.longitude,
    this.isInterchange = false,
    this.connectingLines = const [],
    this.popularPandalsNearby = const [],
    this.aliases = const [],
  });

  final String id;
  final String name;
  final KolkataMetroLine line;
  final double latitude;
  final double longitude;
  final bool isInterchange;
  final List<KolkataMetroLine> connectingLines;
  final List<String> popularPandalsNearby;
  final List<String> aliases;

  String get displayName => name;
  String get subtitle => isInterchange
      ? 'Interchange (${line.label} & ${connectingLines.map((l) => l.label).join(", ")})'
      : line.label;

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'line': line.code,
    'lat': latitude,
    'lng': longitude,
    'isInterchange': isInterchange,
    'popularPandalsNearby': popularPandalsNearby,
  };
}
