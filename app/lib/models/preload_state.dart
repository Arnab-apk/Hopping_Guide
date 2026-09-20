/// Immutable state representing startup and map preload progress.
class PreloadState {
  const PreloadState({
    required this.progress,
    required this.statusMessage,
  });

  /// Real progress from 0.0 to 1.0
  final double progress;

  /// User-facing descriptive status message
  final String statusMessage;

  PreloadState copyWith({
    double? progress,
    String? statusMessage,
  }) {
    return PreloadState(
      progress: progress ?? this.progress,
      statusMessage: statusMessage ?? this.statusMessage,
    );
  }
}
