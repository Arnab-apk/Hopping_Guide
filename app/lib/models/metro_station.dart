import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

/// Metro line classification in Kolkata Metro Rail network
enum KolkataMetroLine {
  blue(
    code: 'blue',
    label: 'Blue Line (Line 1)',
    corridor: 'Dakshineswar ⇄ Kavi Subhash',
    color: Color(0xFF0057B8),
  ),
  green(
    code: 'green',
    label: 'Green Line (Line 2)',
    corridor: 'Howrah Maidan ⇄ Salt Lake Sector-V',
    color: Color(0xFF2E9E4F),
  ),
  purple(
    code: 'purple',
    label: 'Purple Line (Line 3)',
    corridor: 'Joka ⇄ Majerhat',
    color: Color(0xFF7B3FA0),
  ),
  orange(
    code: 'orange',
    label: 'Orange Line (Line 6)',
    corridor: 'Kavi Subhash ⇄ Beleghata',
    color: Color(0xFFF28C1E),
  ),
  yellow(
    code: 'yellow',
    label: 'Yellow Line (Line 4)',
    corridor: 'Noapara ⇄ Jai Hind (Airport)',
    color: Color(0xFFE6B800),
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

  static KolkataMetroLine? fromCode(String code) {
    for (final line in KolkataMetroLine.values) {
      if (line.code.toLowerCase() == code.toLowerCase().trim()) return line;
    }
    return null;
  }
}

/// Represents a distinct Kolkata Metro Station entity with precise coordinates
class MetroStation {
  const MetroStation({
    required this.id,
    required this.name,
    required this.line,
    required this.latitude,
    required this.longitude,
    this.nameBn,
    this.code,
    this.layout,
    this.isInterchange = false,
    this.connectingLines = const [],
    this.popularPandalsNearby = const [],
    this.aliases = const [],
    this.opened = const {},
  });

  final String id;
  final String name;
  final String? nameBn;
  final String? code;
  final String? layout;
  final KolkataMetroLine line;
  final double latitude;
  final double longitude;
  final bool isInterchange;
  final List<KolkataMetroLine> connectingLines;
  final List<String> popularPandalsNearby;
  final List<String> aliases;
  final Map<String, String> opened;

  String get displayName => name;
  String get fullDisplayName => (nameBn != null && nameBn!.isNotEmpty) ? '$name ($nameBn)' : name;

  String get subtitle => isInterchange
      ? 'Interchange (${line.label} & ${connectingLines.map((l) => l.label).join(", ")})'
      : line.label;

  LatLng toLatLng() => LatLng(latitude, longitude);

  /// Matches either canonical id (e.g. 'shyambazar') or legacy prefix (e.g. 'm_shyambazar')
  bool matchesId(String queryId) {
    if (id == queryId) return true;
    final cleanQuery = queryId.startsWith('m_') ? queryId.substring(2) : queryId;
    final normalizedId = id.replaceAll('-', '_');
    final normalizedQuery = cleanQuery.replaceAll('-', '_');
    if (normalizedId == normalizedQuery) return true;
    return aliases.any((a) => a.toLowerCase() == queryId.toLowerCase());
  }

  factory MetroStation.fromJson(
    Map<String, dynamic> json, {
    List<String> popularPandals = const [],
    List<String> extraAliases = const [],
  }) {
    final rawLines = (json['lines'] as List<dynamic>?)?.cast<String>() ?? ['blue'];
    final lines = rawLines
        .map((l) => KolkataMetroLine.fromCode(l))
        .whereType<KolkataMetroLine>()
        .toList();

    final primaryLine = lines.isNotEmpty ? lines.first : KolkataMetroLine.blue;
    final connecting = lines.length > 1 ? lines.sublist(1) : <KolkataMetroLine>[];

    final akaList = (json['aka'] as List<dynamic>?)?.cast<String>() ?? [];
    final allAliases = {...akaList, ...extraAliases}.toList();

    final openedMap = <String, String>{};
    if (json['opened'] is Map) {
      (json['opened'] as Map).forEach((k, v) {
        openedMap[k.toString()] = v.toString();
      });
    }

    return MetroStation(
      id: json['id'] as String,
      name: json['name'] as String,
      nameBn: json['nameBn'] as String?,
      code: json['code'] as String?,
      layout: json['layout'] as String?,
      line: primaryLine,
      latitude: (json['lat'] as num).toDouble(),
      longitude: (json['lng'] as num).toDouble(),
      isInterchange: json['interchange'] as bool? ?? (lines.length > 1),
      connectingLines: connecting,
      popularPandalsNearby: popularPandals,
      aliases: allAliases,
      opened: openedMap,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'nameBn': nameBn,
    'code': code,
    'layout': layout,
    'line': line.code,
    'lat': latitude,
    'lng': longitude,
    'isInterchange': isInterchange,
    'connectingLines': connectingLines.map((l) => l.code).toList(),
    'popularPandalsNearby': popularPandalsNearby,
    'aliases': aliases,
    'opened': opened,
  };
}
