import 'package:magiclane_maps_flutter/core.dart';
import 'package:magiclane_maps_flutter/projections.dart';
import 'package:magiclane_maps_flutter/src/core/common/task_handler.dart';
import 'package:magiclane_maps_flutter/src/gem_kit_platform_interface.dart';

/// Projection service utilities.
///
/// Provides helpers to convert projection instances between coordinate
/// systems. Conversions are performed asynchronously and return a
/// [TaskHandler] to monitor progress; the converted projection is delivered
/// via the completion callback.
///
/// {@category Projections}
abstract class ProjectionService {
  /// Convert a projection to a different projection type asynchronously.
  ///
  /// The conversion runs on the engine and reports progress through a
  /// returned [TaskHandler]. When the operation completes the provided
  /// [onComplete] callback is invoked with the resulting [Projection] or an
  /// error code.
  ///
  /// ## Parameters
  ///
  /// - [from]: (Projection) The input projection instance to convert.
  /// - [toType]: (ProjectionType) The desired target projection type.
  /// - [onComplete]: (void Function(GemError, Projection?)) Callback invoked when conversion completes. The callback receives:
  ///   - [GemError.success] and a non-null [Projection] when conversion succeeded.
  ///   - [GemError.notSupported] and null when the conversion cannot be performed.
  ///   - [GemError.internalAbort] and null if parsing or internal errors occur.
  ///
  /// ## Returns
  ///
  /// - (TaskHandler?) A task handle to monitor progress, or `null` if the
  ///   conversion request failed immediately.
  static TaskHandler? convert({
    required Projection from,
    required ProjectionType toType,
    final void Function(GemError err, Projection? result)? onComplete,
  }) {
    final EventDrivenProgressListener progListener =
        EventDrivenProgressListener();

    late Projection result;

    switch (toType) {
      case ProjectionType.bng:
        result = BNGProjection(easting: 0, northing: 0);
      case ProjectionType.lam:
        result = LAMProjection(x: 0, y: 0);
      case ProjectionType.utm:
        result = UTMProjection(
          x: 0,
          y: 0,
          zone: 0,
          hemisphere: Hemisphere.north,
        );
      case ProjectionType.mgrs:
        result = MGRSProjection(easting: 0, northing: 0, zone: '', letters: '');
      case ProjectionType.gk:
        result = GKProjection(x: 0, y: 0, zone: 0);
      case ProjectionType.wgs84:
        result = WGS84Projection(Coordinates());
      case ProjectionType.w3w:
        result = W3WProjection('');
      case ProjectionType.undefined:
        throw UnimplementedError();
    }

    GemKitPlatform.instance.registerEventHandler(progListener.id, progListener);

    progListener.registerOnCompleteWithData((
      final int err,
      final String hint,
      final Map<dynamic, dynamic> json,
    ) {
      GemKitPlatform.instance.unregisterEventHandler(progListener.id);

      if (err == GemError.success.code) {
        onComplete?.call(GemErrorExtension.fromCode(err), result);
      } else {
        onComplete?.call(GemErrorExtension.fromCode(err), null);
      }
    });

    final OperationResult resultString = staticMethod(
      'ProjectionService',
      'convert',
      args: <String, dynamic>{
        'from': from.pointerId,
        'to': result.pointerId,
        'listener': progListener.id,
      },
    );

    final GemError errorCode = GemErrorExtension.fromCode(
      resultString['result'],
    );

    if (errorCode != GemError.success) {
      onComplete?.call(errorCode, null);
      return null;
    }

    return TaskHandlerImpl(progListener.id);
  }
}
