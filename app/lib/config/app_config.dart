/// App-wide configuration. Secrets/keys must never be committed; pass them at
/// build time via `--dart-define` (see README "Environment & secrets").
class AppConfig {
  const AppConfig._();

  /// OpenRouteService API key (P1 routing). Get one at https://openrouteservice.org
  /// Pass as: --dart-define=ORS_API_KEY=...
  static const String orsApiKey = String.fromEnvironment('ORS_API_KEY');

  /// 100% Free, keyless OpenStreetMap raster tiles.
  /// No API key or account required; never displays "API key required" watermark.
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
