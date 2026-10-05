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

  /// NVIDIA API Key for route assistant LLM (Nemotron 3 Ultra)
  /// Pass at build time: --dart-define=NVIDIA_API_KEY=your_key
  static const String nvidiaApiKey = String.fromEnvironment('NVIDIA_API_KEY');

  /// NVIDIA Model for route assistant LLM
  static const String nvidiaModel = String.fromEnvironment(
    'NVIDIA_MODEL',
    defaultValue: 'nvidia/nemotron-3-ultra-550b-a55b',
  );

  /// Google Gemini API key as secondary fallback
  static const String geminiApiKey = String.fromEnvironment('GEMINI_API_KEY');

  /// Gemini model used by the route assistant.
  static const String geminiModel = String.fromEnvironment(
    'GEMINI_MODEL',
    defaultValue: 'gemini-3.8-flash',
  );
}
