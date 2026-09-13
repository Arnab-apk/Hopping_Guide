/// App-wide configuration. Secrets/keys must never be committed; pass them at
/// build time via `--dart-define` (see README "Environment & secrets").
class AppConfig {
  const AppConfig._();

  /// OpenRouteService API key (P1 routing). Get one at https://openrouteservice.org
  /// Pass as: --dart-define=ORS_API_KEY=...
  static const String orsApiKey = String.fromEnvironment('ORS_API_KEY');

  /// Map tile sources.
  /// Dark mode: CartoDB Dark Matter (sleek, high contrast, keyless)
  static const String darkTileUrlTemplate =
      'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}.png';

  /// Light mode: CartoDB Voyager (warm, crisp, detailed, keyless)
  static const String lightTileUrlTemplate =
      'https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}.png';

  static const List<String> cartoSubdomains = ['a', 'b', 'c', 'd'];

  /// Default tile template (legacy fallback)
  static const String tileUrlTemplate = darkTileUrlTemplate;
  static const String tileFallback =
      'https://tile.openstreetmap.org/{z}/{x}/{y}.png';

  /// Default map center: central Kolkata (near Park Street / Maidan).
  static const double defaultLat = 22.5536;
  static const double defaultLng = 88.3517;
  static const double defaultZoom = 12.0;
}
