import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:latlong2/latlong.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;

/// Service for managing offline map tiles (MBTiles format)
/// Provides zero-network map rendering for core Kolkata zones
class OfflineMapService extends ChangeNotifier {
  OfflineMapService._();
  static final OfflineMapService instance = OfflineMapService._();

  Database? _db;
  bool _initialized = false;

  // Kolkata bounding box for tile coverage
  static const double _kolkataMinLat = 22.45;
  static const double _kolkataMaxLat = 22.70;
  static const double _kolkataMinLng = 88.25;
  static const double _kolkataMaxLng = 88.55;

  /// Tile coverage info for UI
  static const Map<int, TileCoverageInfo> _coverageByZoom = {
    10: TileCoverageInfo(zoom: 10, tileCount: 4, approxSizeMB: 0.5),
    11: TileCoverageInfo(zoom: 11, tileCount: 16, approxSizeMB: 1.5),
    12: TileCoverageInfo(zoom: 12, tileCount: 64, approxSizeMB: 5),
    13: TileCoverageInfo(zoom: 13, tileCount: 256, approxSizeMB: 18),
    14: TileCoverageInfo(zoom: 14, tileCount: 1024, approxSizeMB: 60),
    15: TileCoverageInfo(zoom: 15, tileCount: 4096, approxSizeMB: 200),
    16: TileCoverageInfo(zoom: 16, tileCount: 16384, approxSizeMB: 700),
    17: TileCoverageInfo(zoom: 17, tileCount: 65536, approxSizeMB: 2500),
    18: TileCoverageInfo(zoom: 18, tileCount: 262144, approxSizeMB: 9000),
  };

  /// Initialize the service and open database
  Future<void> initialize() async {
    if (_initialized) return;

    final dir = await getApplicationDocumentsDirectory();
    final dbPath = p.join(dir.path, 'offline_maps', 'kolkata.mbtiles');

    // Ensure directory exists
    await Directory(p.dirname(dbPath)).create(recursive: true);

    _db = await openDatabase(dbPath, version: 1, onCreate: _onCreate);

    _initialized = true;
    debugPrint('[OfflineMapService] ✅ Initialized at $dbPath');
  }

  Future<void> _onCreate(Database db, int version) async {
    // MBTiles schema (based on MBTiles 1.3 spec)
    await db.execute('''
      CREATE TABLE tiles (
        zoom_level INTEGER NOT NULL,
        tile_column INTEGER NOT NULL,
        tile_row INTEGER NOT NULL,
        tile_data BLOB NOT NULL,
        PRIMARY KEY (zoom_level, tile_column, tile_row)
      )
    ''');

    await db.execute('''
      CREATE TABLE metadata (
        name TEXT PRIMARY KEY,
        value TEXT NOT NULL
      )
    ''');

    // Default metadata
    await db.insert('metadata', {
      'name': 'name',
      'value': 'Kolkata Offline Map',
    });
    await db.insert('metadata', {'name': 'type', 'value': 'baselayer'});
    await db.insert('metadata', {'name': 'version', 'value': '1.0'});
    await db.insert('metadata', {'name': 'format', 'value': 'png'});
    await db.insert('metadata', {
      'name': 'bounds',
      'value':
          '$_kolkataMinLng,$_kolkataMinLat,$_kolkataMaxLng,$_kolkataMaxLat',
    });
    await db.insert('metadata', {'name': 'minzoom', 'value': '10'});
    await db.insert('metadata', {'name': 'maxzoom', 'value': '18'});
  }

  /// Check if tiles exist for a given zoom level and bounds
  Future<bool> hasTilesForBounds({
    required int zoom,
    required double minLat,
    required double maxLat,
    required double minLng,
    required double maxLng,
  }) async {
    await initialize();

    final minTile = _latLngToTile(minLat, minLng, zoom);
    final maxTile = _latLngToTile(maxLat, maxLng, zoom);

    final count =
        Sqflite.firstIntValue(
          await _db!.rawQuery(
            '''
      SELECT COUNT(*) FROM tiles
      WHERE zoom_level = ?
        AND tile_column BETWEEN ? AND ?
        AND tile_row BETWEEN ? AND ?
    ''',
            [zoom, minTile.x, maxTile.x, maxTile.y, minTile.y],
          ),
        ) ??
        0;

    final expected = (maxTile.x - minTile.x + 1) * (maxTile.y - minTile.y + 1);
    return count >= (expected * 0.8); // 80% coverage threshold
  }

  /// Get tile data for rendering (for flutter_map TileProvider)
  Future<Uint8List?> getTile(int zoom, int x, int y) async {
    await initialize();

    // MBTiles uses TMS (flipped Y) coordinate system
    final tmsY = (1 << zoom) - 1 - y;

    final result = await _db!.rawQuery(
      'SELECT tile_data FROM tiles WHERE zoom_level = ? AND tile_column = ? AND tile_row = ?',
      [zoom, x, tmsY],
    );

    if (result.isNotEmpty) {
      return result.first['tile_data'] as Uint8List?;
    }
    return null;
  }

  /// Get metadata value
  Future<String?> getMetadata(String name) async {
    await initialize();
    final result = await _db!.rawQuery(
      'SELECT value FROM metadata WHERE name = ?',
      [name],
    );
    return result.isNotEmpty ? result.first['value'] as String? : null;
  }

  /// Get all metadata
  Future<Map<String, String>> getAllMetadata() async {
    await initialize();
    final result = await _db!.rawQuery('SELECT name, value FROM metadata');
    return {
      for (final row in result) row['name'] as String: row['value'] as String,
    };
  }

  /// Get coverage statistics for UI
  Future<Map<int, TileCoverageInfo>> getCoverageStats() async {
    await initialize();

    final stats = <int, TileCoverageInfo>{};
    for (final entry in _coverageByZoom.entries) {
      final zoom = entry.key;
      final info = entry.value;

      final count =
          Sqflite.firstIntValue(
            await _db!.rawQuery(
              'SELECT COUNT(*) FROM tiles WHERE zoom_level = ?',
              [zoom],
            ),
          ) ??
          0;

      stats[zoom] = TileCoverageInfo(
        zoom: zoom,
        tileCount: info.tileCount,
        approxSizeMB: info.approxSizeMB,
        downloadedTiles: count,
      );
    }
    return stats;
  }

  /// Total downloaded size in MB
  Future<double> getTotalSizeMB() async {
    await initialize();
    final result = await _db!.rawQuery(
      'SELECT SUM(LENGTH(tile_data)) as total FROM tiles',
    );
    final bytes = result.first['total'] as int? ?? 0;
    return bytes / (1024 * 1024);
  }

  /// Delete all tiles (for re-download)
  Future<void> clearAllTiles() async {
    await initialize();
    await _db!.delete('tiles');
    debugPrint('[OfflineMapService] 🗑️ Cleared all tiles');
  }

  /// Check if offline map is usable for current viewport
  Future<bool> isUsableForViewport(LatLng center, double zoom) async {
    await initialize();
    // Check if we have tiles at this zoom level around center
    final radiusDeg = 0.01 * (18 - zoom.toInt()).clamp(0, 8).toDouble();
    return hasTilesForBounds(
      zoom: zoom.toInt(),
      minLat: center.latitude - radiusDeg,
      maxLat: center.latitude + radiusDeg,
      minLng: center.longitude - radiusDeg,
      maxLng: center.longitude + radiusDeg,
    );
  }

  /// Convert lat/lng to tile coordinates (XYZ/TMS)
  _TileCoord _latLngToTile(double lat, double lng, int zoom) {
    final n = 1 << zoom;
    final x = ((lng + 180) / 360 * n).floor().clamp(0, n - 1);
    final latRad = lat * 3.141592653589793 / 180;
    final y =
        ((1 -
                    (math.log(math.tan(latRad) + 1 / math.cos(latRad)) /
                            3.141592653589793) /
                        2) *
                n)
            .floor()
            .clamp(0, n - 1);
    return _TileCoord(x, y);
  }

  void disposeService() {
    _db?.close();
    _initialized = false;
    notifyListeners();
  }
}

/// Tile coordinate helper
class _TileCoord {
  const _TileCoord(this.x, this.y);
  final int x;
  final int y;
}

/// Coverage info for a zoom level
class TileCoverageInfo {
  const TileCoverageInfo({
    required this.zoom,
    required this.tileCount,
    required this.approxSizeMB,
    this.downloadedTiles = 0,
  });

  final int zoom;
  final int tileCount;
  final double approxSizeMB;
  final int downloadedTiles;

  double get coveragePercent =>
      tileCount > 0 ? (downloadedTiles / tileCount * 100) : 0;
  double get downloadedSizeMB => approxSizeMB * (downloadedTiles / tileCount);

  String get formattedSize {
    if (approxSizeMB < 1) return '${(approxSizeMB * 1024).round()} KB';
    if (approxSizeMB < 1024) return '${approxSizeMB.toStringAsFixed(1)} MB';
    return '${(approxSizeMB / 1024).toStringAsFixed(1)} GB';
  }
}

/// Tile provider for flutter_map that reads from MBTiles
class MbTilesTileProvider extends ChangeNotifier {
  MbTilesTileProvider({required this.offlineMapService});

  final OfflineMapService offlineMapService;

  Future<Uint8List?> getTile(int zoom, int x, int y) {
    return offlineMapService.getTile(zoom, x, y);
  }
}
