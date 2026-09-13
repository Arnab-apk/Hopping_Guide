/// App-wide configuration. Secrets/keys must never be committed; pass them at
/// build time via `--dart-define` (see README "Environment & secrets").
class AppConfig {
  const AppConfig._();

  /// OpenRouteService API key (P1 routing). Get one at https://openrouteservice.org
  /// Pass as: --dart-define=ORS_API_KEY=...
  static const String orsApiKey = String.fromEnvironment('ORS_API_KEY');

  /// High-speed global CDN raster tiles (CartoDB Voyager & Dark Matter).
  /// Sub-millisecond Edge caching in South Asia; zero rate-limits or watermark requirements.
  static const String tileCartoVoyager =
      'https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}.png';
  static const String tileCartoDark =
      'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}.png';
  static const List<String> cartoSubdomains = ['a', 'b', 'c', 'd'];

  /// OpenStreetMap fallback raster tiles.
  static const String tileUrlTemplate =
      'https://tile.openstreetmap.org/{z}/{x}/{y}.png';
  static const String tileFallback =
      'https://a.tile.openstreetmap.org/{z}/{x}/{y}.png';

  static const List<String> osmSubdomains = ['a', 'b', 'c'];

  /// Default map center: central Kolkata (near Park Street / Maidan).
  static const double defaultLat = 22.5536;
  static const double defaultLng = 88.3517;
  static const double defaultZoom = 12.0;
}
