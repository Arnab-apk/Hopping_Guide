import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';

/// Voice guidance service for turn-by-turn navigation
/// Provides Magic Lane-like voice instructions
class VoiceNavigationService {
  VoiceNavigationService._();
  static final VoiceNavigationService instance = VoiceNavigationService._();

  final FlutterTts _tts = FlutterTts();
  bool _isInitialized = false;
  bool _isEnabled = true;
  String? _lastSpokenInstruction;

  bool get isEnabled => _isEnabled;
  bool get isInitialized => _isInitialized;

  /// Initialize text-to-speech
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Configure TTS
      await _tts.setLanguage('en-IN'); // Indian English for better local pronunciation
      await _tts.setSpeechRate(0.5); // Slightly slower for clarity
      await _tts.setVolume(1.0);
      await _tts.setPitch(1.0);

      // Set up callbacks
      _tts.setStartHandler(() {
        debugPrint('[VoiceNav] Started speaking');
      });

      _tts.setCompletionHandler(() {
        debugPrint('[VoiceNav] Finished speaking');
      });

      _tts.setErrorHandler((msg) {
        debugPrint('[VoiceNav] Error: $msg');
      });

      _isInitialized = true;
      debugPrint('[VoiceNav] Initialized successfully');
    } catch (e) {
      debugPrint('[VoiceNav] Initialization error: $e');
      _isInitialized = false;
    }
  }

  /// Speak a navigation instruction
  Future<void> speak(String instruction) async {
    if (!_isInitialized || !_isEnabled) return;

    // Avoid repeating the same instruction
    if (instruction == _lastSpokenInstruction) return;

    try {
      // Stop any ongoing speech
      await _tts.stop();

      // Speak the instruction
      await _tts.speak(instruction);

      _lastSpokenInstruction = instruction;
      debugPrint('[VoiceNav] Speaking: $instruction');
    } catch (e) {
      debugPrint('[VoiceNav] Speak error: $e');
    }
  }

  /// Enable or disable voice guidance
  void setEnabled(bool enabled) {
    _isEnabled = enabled;
    if (!enabled) {
      stop();
    }
    debugPrint('[VoiceNav] ${enabled ? 'Enabled' : 'Disabled'}');
  }

  /// Stop current speech
  Future<void> stop() async {
    try {
      await _tts.stop();
      _lastSpokenInstruction = null;
    } catch (e) {
      debugPrint('[VoiceNav] Stop error: $e');
    }
  }

  /// Announce destination arrival
  Future<void> announceArrival(String destinationName) async {
    await speak('You have arrived at $destinationName');
  }

  /// Announce off-route situation
  Future<void> announceOffRoute() async {
    await speak('Recalculating route');
  }

  /// Announce turn instruction with distance
  Future<void> announceTurn(String turnDirection, double distanceInMeters) async {
    String distance;
    if (distanceInMeters < 20) {
      distance = 'now';
    } else if (distanceInMeters < 50) {
      distance = 'in ${distanceInMeters.round()} meters';
    } else if (distanceInMeters < 1000) {
      distance = 'in ${distanceInMeters.round()} meters';
    } else {
      distance = 'in ${(distanceInMeters / 1000).toStringAsFixed(1)} kilometers';
    }

    await speak('$turnDirection $distance');
  }

  /// Clean up resources
  Future<void> dispose() async {
    await _tts.stop();
  }
}
