/// App-wide configuration. Secrets/keys must never be committed; pass them at
/// build time via `--dart-define` (see README "Environment & secrets").
class AppConfig {
  const AppConfig._();

  /// OpenRouteService API key (P1 routing). Get one at https://openrouteservice.org
  /// Pass as: --dart-define=ORS_API_KEY=...
  static const String orsApiKey = String.fromEnvironment('ORS_API_KEY');

  /// Map tile source. OSM raster tiles are keyless and free; switch to a
  /// MapTiler vector setup if you move to maplibre_gl later.
  static const String tileUrlTemplate =
      'https://tile.openstreetmap.org/{z}/{x}/{y}.png';
  static const String tileFallback =
      'https://a.tile.openstreetmap.org/{z}/{x}/{y}.png';

  /// Default map center: central Kolkata (near Park Street / Maidan).
  static const double defaultLat = 22.5536;
  static const double defaultLng = 88.3517;
  static const double defaultZoom = 12.0;
}
