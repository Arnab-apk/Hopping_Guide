import 'package:flutter/foundation.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_tile_caching/flutter_map_tile_caching.dart';
import 'package:latlong2/latlong.dart';

/// Offline map tile caching service
/// Provides offline map capabilities using flutter_map_tile_caching v10
class OfflineMapService extends ChangeNotifier {
  OfflineMapService._();
  static final OfflineMapService instance = OfflineMapService._();

  static const String _storeName = 'kolkata_puja_maps';
  FMTCStore? _store;
  bool _isInitialized = false;
  bool _isDownloading = false;
  double _downloadProgress = 0.0;

  bool get isInitialized => _isInitialized;
  bool get isDownloading => _isDownloading;
  double get downloadProgress => _downloadProgress;

  /// Initialize the offline map service
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Initialize FMTC
      await FMTCObjectBoxBackend().initialise();

      // Get or create store
      _store = const FMTCStore(_storeName);
      if (!await _store!.manage.ready) {
        await _store!.manage.create();
      }

      _isInitialized = true;
      debugPrint('[OfflineMap] Initialized successfully');
      notifyListeners();
    } catch (e) {
      debugPrint('[OfflineMap] Initialization error: $e');
      _isInitialized = false;
    }
  }

  /// Download map tiles for Kolkata area
  Future<void> downloadKolkataArea() async {
    if (!_isInitialized || _store == null) {
      debugPrint('[OfflineMap] Not initialized');
      return;
    }

    if (_isDownloading) {
      debugPrint('[OfflineMap] Download already in progress');
      return;
    }

    _isDownloading = true;
    _downloadProgress = 0.0;
    notifyListeners();

    try {
      // Define Kolkata coverage area
      final region = RectangleRegion(
        LatLngBounds(
          const LatLng(22.3, 88.1), // Southwest
          const LatLng(22.8, 88.6), // Northeast
        ),
      );

      final tileLayer = TileLayer(
        urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
      );

      final downloadable = region.toDownloadable(
        minZoom: 10,
        maxZoom: 17,
        options: tileLayer,
      );

      // Download tiles for zoom levels 10-17 (good for city navigation)
      final download = _store!.download.startForeground(
        region: downloadable,
        parallelThreads: 10,
        skipExistingTiles: true,
        skipSeaTiles: true,
      );

      // Listen to progress
      await for (final progress in download.downloadProgress) {
        _downloadProgress = progress.percentageProgress / 100;
        notifyListeners();

        debugPrint(
          '[OfflineMap] Progress: ${progress.percentageProgress.toStringAsFixed(1)}% '
          '(${progress.successfulTilesCount}/${progress.maxTilesCount} tiles)',
        );

        if (progress.percentageProgress >= 100) {
          break;
        }
      }

      debugPrint('[OfflineMap] Download completed successfully');
    } catch (e) {
      debugPrint('[OfflineMap] Download error: $e');
    } finally {
      _isDownloading = false;
      _downloadProgress = 0.0;
      notifyListeners();
    }
  }

  /// Download tiles for specific pandal areas
  Future<void> downloadPandalAreas(List<LatLng> pandalLocations) async {
    if (!_isInitialized || _store == null) {
      debugPrint('[OfflineMap] Not initialized');
      return;
    }

    _isDownloading = true;
    _downloadProgress = 0.0;
    notifyListeners();

    try {
      final tileLayer = TileLayer(
        urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
      );

      // Create circular regions around each pandal (0.5km = 500m radius)
      final regions = pandalLocations.map((location) {
        return CircleRegion(
          location,
          0.5, // 0.5 km radius = 500 meters
        ).toDownloadable(
          minZoom: 14,
          maxZoom: 18, // Higher detail for pandal areas
          options: tileLayer,
        );
      }).toList();

      // Download tiles for each region
      for (int i = 0; i < regions.length; i++) {
        final download = _store!.download.startForeground(
          region: regions[i],
          parallelThreads: 5,
          skipExistingTiles: true,
        );

        await for (final progress in download.downloadProgress) {
          _downloadProgress = (i + progress.percentageProgress / 100) / regions.length;
          notifyListeners();

          if (progress.percentageProgress >= 100) {
            break;
          }
        }
      }

      debugPrint('[OfflineMap] Pandal areas downloaded successfully');
    } catch (e) {
      debugPrint('[OfflineMap] Download error: $e');
    } finally {
      _isDownloading = false;
      _downloadProgress = 0.0;
      notifyListeners();
    }
  }

  /// Get cache statistics
  Future<Map<String, dynamic>> getCacheStats() async {
    if (!_isInitialized || _store == null) {
      return {'error': 'Not initialized'};
    }

    try {
      final stats = await _store!.stats.all;

      return {
        'tileCount': stats.length,
        'sizeBytes': stats.size * 1024,
        'sizeMB': (stats.size / 1024).toStringAsFixed(2),
        'hits': stats.hits,
        'misses': stats.misses,
      };
    } catch (e) {
      debugPrint('[OfflineMap] Stats error: $e');
      return {'error': e.toString()};
    }
  }

  /// Clear cached tiles
  Future<void> clearCache() async {
    if (!_isInitialized || _store == null) {
      debugPrint('[OfflineMap] Not initialized');
      return;
    }

    try {
      await _store!.manage.reset();
      debugPrint('[OfflineMap] Cache cleared successfully');
      notifyListeners();
    } catch (e) {
      debugPrint('[OfflineMap] Clear cache error: $e');
    }
  }

  /// Get the tile provider for flutter_map
  FMTCTileProvider getTileProvider() {
    if (_store == null) {
      throw StateError('OfflineMapService not initialized');
    }

    return FMTCTileProvider(
      stores: const {_storeName: BrowseStoreStrategy.readUpdateCreate},
      loadingStrategy: BrowseLoadingStrategy.cacheFirst,
      cachedValidDuration: const Duration(days: 30),
    );
  }
}
