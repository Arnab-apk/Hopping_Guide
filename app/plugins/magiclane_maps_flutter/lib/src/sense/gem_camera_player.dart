// SPDX-FileCopyrightText: 2025-2026 Magic Lane International B.V. <info@magiclane.com>
// SPDX-License-Identifier: LicenseRef-MagicLane-Proprietary
//
// For the latest licensing terms and conditions, see https://www.magiclane.com/web/terms-and-conditions#terms-of-service.
// For further information use the contact form at https://www.magiclane.com/web/contact.

import 'dart:io' show Platform;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart' as widgets;
import 'package:magiclane_maps_flutter/sense.dart';
import 'package:magiclane_maps_flutter/src/sense/sense_data_impl/camera_impl.dart';

/// Controller for managing camera feed playback from a data source.
///
/// Manages playback of camera frames from a [DataSource] by wrapping a [ValueNotifier]
/// that tracks [GemCameraPlayerValue] state. Automatically registers a [DataSourceListener]
/// to receive new camera frames and update the playback status. Use with [GemCameraPlayer]
/// widget to render camera feed frames.
///
/// The controller validates that the data source supports camera data and sets an error
/// status if unavailable. It handles automatic state transitions between loading, playing,
/// paused, and ended states based on incoming data and playback events. The controller
/// must be disposed when no longer needed to clean up listeners and resources.
///
/// ## See also:
///
/// - [GemCameraPlayer] - Widget for rendering camera frames
/// - [GemCameraPlayerValue] - State value tracked by this controller
/// - [DataSource] - Provides camera frame data
/// - [GemCameraPlayerStatus] - Enum for playback states
///
/// {@category Sensor Data Source}
class GemCameraPlayerController extends ValueNotifier<GemCameraPlayerValue> {
  /// Creates a camera player controller from a data source.
  ///
  /// Initializes the controller with loading status and validates that the [dataSource]
  /// supports camera data (sets error status if not). Automatically registers a
  /// [DataSourceListener] to receive camera frames and playback status changes.
  /// Updates status to ended if playback is already stopped.
  ///
  /// ## Parameters
  ///
  /// - [dataSource]: The [DataSource] providing camera frame data (must support [DataType.camera])
  /// - [configurationOverride]: Optional [CameraConfiguration] to override frame width/height
  GemCameraPlayerController({
    required DataSource dataSource,
    this.configurationOverride,
  }) : super(
         GemCameraPlayerValue(
           dataSource: dataSource,
           status: GemCameraPlayerStatus.loading,
         ),
       ) {
    if (!dataSource.isDataTypeAvailable(DataType.camera)) {
      value = value.copyWith(status: GemCameraPlayerStatus.error);
    }

    final DataSourceListener listener = DataSourceListener(
      onNewData: (SenseData data) {
        if (_isDisposed) {
          return;
        }

        if (data is! CameraImpl) {
          return;
        }

        final GemCameraPlayerStatus status = value.status;
        if (status == GemCameraPlayerStatus.loading ||
            status == GemCameraPlayerStatus.playing ||
            status == GemCameraPlayerStatus.ended) {
          value = value.copyWith(
            camera: data,
            status: GemCameraPlayerStatus.playing,
          );
        }
      },
      onPlayingStatusChanged: (DataType dataType, PlayingStatus status) {
        if (_isDisposed) {
          return;
        }

        if (dataType == DataType.camera && status == PlayingStatus.stopped) {
          value = value.copyWith(status: GemCameraPlayerStatus.ended);
        }
      },
    );
    final Playback? playback = dataSource.playback;
    if (playback != null && playback.state == PlayingStatus.stopped) {
      value = value.copyWith(status: GemCameraPlayerStatus.ended);
    }

    dataSource.addListener(listener: listener, dataType: DataType.camera);

    value = value.copyWith(listener: listener);
  }

  /// Indicates whether the controller has been disposed.
  bool _isDisposed = false;
  final CameraConfiguration? configurationOverride;

  /// Pauses the camera feed playback.
  ///
  /// Sets the playback status to [GemCameraPlayerStatus.paused] if currently playing.
  /// Does not affect the underlying [DataSource] sensor playback - only pauses the
  /// visual rendering of camera frames in the player widget.
  ///
  /// ## Also see:
  ///
  /// - [Playback.pause] - Pause the underlying data source playback
  void pause() {
    if (value.status == GemCameraPlayerStatus.playing) {
      value = value.copyWith(status: GemCameraPlayerStatus.paused);
    }
  }

  /// Resumes the camera feed playback.
  ///
  /// Sets the playback status to [GemCameraPlayerStatus.playing] if currently paused.
  /// Does not affect the underlying [DataSource] sensor playback - only resumes the
  /// visual rendering of camera frames in the player widget.
  ///
  /// ## Also see:
  ///
  /// - [Playback.resume] - Resume the underlying data source playback
  void resume() {
    if (value.status == GemCameraPlayerStatus.paused) {
      value = value.copyWith(status: GemCameraPlayerStatus.playing);
    }
  }

  /// Whether the controller has been disposed.
  ///
  /// ## Returns
  ///
  /// - `true` if [dispose] has been called, `false` otherwise
  bool get isDisposed => _isDisposed;

  /// The data source providing camera frame data to the player.
  ///
  /// ## Returns
  ///
  /// - The [DataSource] containing camera data
  DataSource get datasource => value.dataSource;

  /// The current playback status of the camera player.
  ///
  /// ## Returns
  ///
  /// - The [GemCameraPlayerStatus] indicating loading, playing, paused, ended, or error state
  GemCameraPlayerStatus get status => value.status;

  /// The latest camera frame data received from the data source.
  ///
  /// ## Returns
  ///
  /// - The [Camera] frame with RGBA8888 pixel data, or null if no frame received yet
  Camera? get camera => value.camera;

  /// The resolution of the camera frame as (width, height).
  ///
  /// Returns the native dimensions of incoming camera frames based on the actual
  /// sensor data, not the on-screen display size. If [configurationOverride] is set,
  /// uses those dimensions. On iOS, swaps width and height to account for portrait
  /// orientation rotation.
  ///
  /// ## Returns
  ///
  /// - A tuple `(int width, int height)` of the frame resolution, or null if camera data unavailable
  (int, int)? get size {
    final int width;
    final int height;

    if (configurationOverride != null) {
      width = configurationOverride!.frameWidth;
      height = configurationOverride!.frameHeight;
    } else {
      final SenseData? camera = datasource.getLatestData(DataType.camera);
      if (camera is! CameraImpl) {
        return null;
      }

      width = camera.cameraConfiguration.frameWidth;
      height = camera.cameraConfiguration.frameHeight;
    }

    if (Platform.isIOS) {
      return (height, width);
    }

    return (width, height);
  }

  /// Disposes of the controller and cleans up resources.
  ///
  /// Removes the registered [DataSourceListener] from the data source, marks the
  /// controller as disposed, and calls the superclass dispose. After calling this
  /// method, the controller cannot be used and should not be accessed.
  @override
  void dispose() {
    if (value._listener != null) {
      value.dataSource.removeListener(
        listener: value._listener!,
        dataType: DataType.camera,
      );
    }
    _isDisposed = true;
    super.dispose();
  }
}

/// Playback status for a camera player controller.
///
/// Describes the current state of a [GemCameraPlayerController], indicating whether
/// the player is loading, playing, paused, ended, or in an error state. Not to be
/// confused with [PlayingStatus] from the sensor engine, which controls the underlying
/// data source playback.
///
/// ## See also:
///
/// - [GemCameraPlayerController] - Uses this enum to track playback state
/// - [PlayingStatus] - Sensor engine playback status (different from this enum)
///
/// {@category Sensor Data Source}
enum GemCameraPlayerStatus {
  /// The player is awaiting the first camera frame data.
  ///
  /// Initial state when the controller is created and waiting for the first
  /// frame to arrive from the data source.
  loading,

  /// The camera frames cannot be converted to RGBA8888 format.
  ///
  /// Error state indicating that the data source does not provide camera data
  /// in a format compatible with the player's RGBA8888 rendering pipeline.
  error,

  /// The player is actively playing camera feed frames.
  ///
  /// The player is receiving and rendering camera frames as they arrive from
  /// the data source.
  playing,

  /// The player is paused and not rendering new frames.
  ///
  /// The player has been paused by calling [GemCameraPlayerController.pause]
  /// and will not render new frames until resumed.
  paused,

  /// The data source has ended playback.
  ///
  /// Final state indicating that the data source has stopped providing camera
  /// data, typically when playing back recorded data that has reached the end.
  ended,
}

/// Widget for rendering camera feed frames from a controller.
///
/// Displays camera frames from a [GemCameraPlayerController] by rendering RGBA8888
/// pixel data from [Camera.rgba8888]. Handles iOS-specific rotation for portrait mode
/// (applies 90-degree rotation), maintains aspect ratio, and provides flexible layout
/// options with customizable widgets for loading, error, and end states.
///
/// This widget requires that the camera data source provides frames with [Camera.rgba8888]
/// available. May not be compatible with all external camera data sources if they do not
/// support RGBA8888 conversion. Automatically updates when new frames arrive via the
/// controller's [ValueNotifier] mechanism.
///
/// ## See also:
///
/// - [GemCameraPlayerController] - Controls camera feed playback
/// - [Camera] - Provides camera frame data with RGBA8888 pixels
/// - [DataSource] - Source of camera data
///
/// {@category Sensor Data Source}
class GemCameraPlayer extends StatefulWidget {
  /// Creates a camera player widget with the specified controller.
  ///
  /// ## Parameters
  ///
  /// - [controller]: The [GemCameraPlayerController] managing camera feed playback
  /// ## Parameters
  ///
  /// - [controller]: The [GemCameraPlayerController] managing camera feed playback.
  /// - [fallbackWidget]: Optional widget displayed when [GemCameraPlayerController.status] is [GemCameraPlayerStatus.error]. If null, an empty box is shown.
  /// - [loadingWidget]: Optional widget displayed while waiting for the first camera frame ([GemCameraPlayerStatus.loading]). If null, an empty box is shown.
  /// - [endWidget]: Optional widget displayed after camera feed playback has ended ([GemCameraPlayerStatus.ended]). If null, an empty box is shown.
  /// - [fit]: Optional [BoxFit] that controls how frames are scaled within the widget bounds. Defaults to [BoxFit.cover] if not provided.
  /// - [key]: Optional widget key forwarded to the superclass.
  const GemCameraPlayer({
    required this.controller,
    this.fallbackWidget,
    this.loadingWidget,
    this.endWidget,
    this.fit,
    super.key,
  });

  /// The controller managing camera feed playback and state.
  final GemCameraPlayerController controller;

  /// Widget displayed when camera frames cannot be decoded (error state).
  ///
  /// Shown when [GemCameraPlayerController.status] is [GemCameraPlayerStatus.error], typically
  /// because the data source does not provide RGBA8888-compatible frames.
  final Widget? fallbackWidget;

  /// Widget displayed while waiting for the first camera frame (loading state).
  ///
  /// Shown when [GemCameraPlayerController.status] is [GemCameraPlayerStatus.loading], before
  /// the first frame has been received from the data source.
  final Widget? loadingWidget;

  /// Widget displayed after camera feed playback has ended.
  ///
  /// Shown when [GemCameraPlayerController.status] is [GemCameraPlayerStatus.ended], typically
  /// when playing back recorded data that has reached the end.
  final Widget? endWidget;

  /// How the camera frames should be scaled within the widget bounds.
  ///
  /// Determines the scaling behavior for camera frames. Common values include
  /// [BoxFit.cover] (fills the space, may crop), [BoxFit.contain] (shows entire
  /// frame, may letterbox), and [BoxFit.fill] (stretches to fill).
  final BoxFit? fit;

  @override
  State<GemCameraPlayer> createState() => _GemCameraPlayerState();
}

class _GemCameraPlayerState extends State<GemCameraPlayer> {
  _GemCameraPlayerState() {
    /// Listener triggered when the controller state changes.
    ///
    /// When the controller status is [GemCameraPlayerStatus.playing], a new image is rendered.
    /// Otherwise, the widget updates in response to loading/ended state.
    _vnListener = () {
      final GemCameraPlayerController controller = widget.controller;
      if (!mounted || controller.isDisposed) {
        return;
      }

      if (controller.value.status == GemCameraPlayerStatus.playing &&
          controller.value.camera != null) {
        _renderImage(controller.value.camera! as CameraImpl);
      } else {
        if (mounted) {
          setState(() {});
        }
      }
    };
  }
  ui.Image? image;

  late VoidCallback _vnListener;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_vnListener);
  }

  @override
  void didUpdateWidget(covariant GemCameraPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);

    oldWidget.controller.removeListener(_vnListener);
    widget.controller.addListener(_vnListener);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_vnListener);
    super.dispose();
  }

  /// Converts RGBA8888 bytes from [CameraImpl] to a [ui.Image] and stores it.
  ///
  /// Handles raw image decoding and uses Flutter's low-level image pipeline
  /// to prepare a renderable frame for display.
  Future<void> _renderImage(CameraImpl camera) async {
    if (!mounted || widget.controller.isDisposed) {
      return;
    }

    final Uint8List? rgbaPixels = camera.rgba8888;
    final CameraConfiguration config = camera.cameraConfiguration;
    final int width =
        widget.controller.configurationOverride?.frameWidth ??
        config.frameWidth;
    final int height =
        widget.controller.configurationOverride?.frameHeight ??
        config.frameHeight;

    final ui.ImmutableBuffer imgBuffer = await ui.ImmutableBuffer.fromUint8List(
      rgbaPixels!,
    );

    final ui.ImageDescriptor descriptor = ui.ImageDescriptor.raw(
      imgBuffer,
      width: width,
      height: height,
      pixelFormat: ui.PixelFormat.rgba8888,
    );

    final ui.Codec codec = await descriptor.instantiateCodec(
      targetWidth: width,
      targetHeight: height,
    );

    final ui.FrameInfo frame = await codec.getNextFrame();

    if (mounted) {
      setState(() {
        image = frame.image;
      });
    }
  }

  /// Displays a camera frame from [Camera.rgba8888] as a [RawImage].
  ///
  /// Rotates the image on iOS if needed (portrait mode only),
  /// maintains aspect ratio, and updates when new frames arrive.
  @override
  Widget build(BuildContext context) {
    if (widget.controller.isDisposed) {
      return const SizedBox();
    }

    if (widget.controller.value.status == GemCameraPlayerStatus.loading) {
      return widget.loadingWidget ?? const SizedBox();
    }

    if (widget.controller.value.status == GemCameraPlayerStatus.error) {
      return widget.fallbackWidget ?? const SizedBox();
    }

    if (widget.controller.value.status == GemCameraPlayerStatus.ended) {
      return widget.endWidget ?? const SizedBox();
    }

    if (image == null) {
      return const SizedBox();
    }

    final bool isIOSPortrait =
        Platform.isIOS &&
        MediaQuery.of(context).orientation == widgets.Orientation.portrait;

    final double width = image!.width.toDouble();
    final double height = image!.height.toDouble();

    final double aspectRatio = isIOSPortrait ? height / width : width / height;

    final Widget displayImage = isIOSPortrait
        ? RotatedBox(
            quarterTurns: 1,
            child: RawImage(image: image, fit: widget.fit ?? BoxFit.cover),
          )
        : RawImage(image: image, fit: widget.fit ?? BoxFit.cover);

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        return Center(
          child: AspectRatio(aspectRatio: aspectRatio, child: displayImage),
        );
      },
    );
  }
}

/// Immutable state container for a camera player controller.
///
/// Holds the current [DataSource] providing camera frames, the playback [status],
/// and optionally the latest [Camera] frame data and its associated listener.
/// This value object is used by [GemCameraPlayerController] to track and notify
/// state changes during camera feed playback. Create instances using the constructor
/// or [copyWith] method to produce new values with updated fields.
///
/// ## See also:
///
/// - [GemCameraPlayerController] - Uses this value to manage camera playback state
/// - [GemCameraPlayer] - Widget that renders camera frames based on this value
/// - [DataSource] - Provides camera data to the player
///
/// {@category Sensor Data Source}
class GemCameraPlayerValue {
  /// Creates a new immutable camera player value with the specified state.
  ///
  /// Immutable container used by [GemCameraPlayerController] to represent the
  /// current playback state, latest frame, and optional internal listener.
  /// Use [copyWith] to produce modified instances rather than mutating this one.
  ///
  /// ## Parameters
  ///
  /// - [dataSource]: The [DataSource] that supplies camera frames for this player.
  /// - [status]: The current [GemCameraPlayerStatus] indicating playback state.
  /// - [camera]: Optional latest [Camera] frame data; `null` if no frame has been received yet.
  /// - [listener]: Optional internal [DataSourceListener] registered on [dataSource] for updates. Stored for cleanup and should not be used directly.
  GemCameraPlayerValue({
    required this.dataSource,
    required this.status,
    this.camera,
    DataSourceListener? listener,
  }) : _listener = listener;

  /// The data source providing camera frame data to the player.
  final DataSource dataSource;

  /// The current playback status of the camera player.
  ///
  /// Indicates whether the player is loading, playing, paused, ended, or in an error state.
  final GemCameraPlayerStatus status;

  /// The latest camera frame data received from the data source.
  ///
  /// Contains the current frame's RGBA8888 pixel data, camera configuration,
  /// and acquisition timestamp. Returns null if no frame has been received yet.
  final Camera? camera;

  /// The data source listener receiving camera frame updates.
  ///
  /// Internal listener registered with the [dataSource] to receive new camera
  /// frames and playback status changes. Used for automatic cleanup on disposal.
  final DataSourceListener? _listener;

  /// Creates a copy of this value with optionally updated fields.
  ///
  /// Produces a new [GemCameraPlayerValue] instance with specified fields replaced.
  /// Any parameter not provided retains its value from the current instance.
  ///
  /// ## Parameters
  ///
  /// - **dataSource** - Optional new [DataSource] for the camera feed
  /// - **status** - Optional new [GemCameraPlayerStatus] playback state
  /// - **camera** - Optional new [Camera] frame data
  /// - **listener** - Optional new [DataSourceListener] for updates
  ///
  /// ## Returns
  ///
  /// - A new [GemCameraPlayerValue] with the specified fields updated
  GemCameraPlayerValue copyWith({
    DataSource? dataSource,
    GemCameraPlayerStatus? status,
    Camera? camera,
    DataSourceListener? listener,
  }) {
    return GemCameraPlayerValue(
      dataSource: dataSource ?? this.dataSource,
      status: status ?? this.status,
      camera: camera ?? this.camera,
      listener: listener ?? _listener,
    );
  }
}
