// SPDX-FileCopyrightText: 2023-2026 Magic Lane International B.V. <info@magiclane.com>
// SPDX-License-Identifier: LicenseRef-MagicLane-Proprietary
//
// For the latest licensing terms and conditions, see https://www.magiclane.com/web/terms-and-conditions#terms-of-service.
// For further information use the contact form at https://www.magiclane.com/web/contact.

import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:flutter/foundation.dart' show Factory, kIsWeb;
import 'package:flutter/gestures.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:logging/logging.dart';
import 'package:magiclane_maps_flutter/core.dart';
import 'package:magiclane_maps_flutter/map.dart';
import 'package:magiclane_maps_flutter/src/gem_kit_platform_interface.dart';
import 'package:magiclane_maps_flutter/src/loggers/app_logger.dart';
import 'package:magiclane_maps_flutter/src/map/gem_map_linux.dart';
import 'package:magiclane_maps_flutter/src/map/open_gl_texture_widget.dart';

/// GemMap Widget
///
/// Displays the map on the screen. The map can be controlled using the [GemMapController] provided by the [_onMapCreated] callback.
///
/// {@category Maps & 3D Scenes}
class GemMap extends StatefulWidget {
  /// Create a [GemMap] widget which renders an interactive map view.
  ///
  /// The [GemMap] is the primary widget for embedding a Magic Lane map into a
  /// Flutter application. It initializes the underlying native map, handles
  /// platform-specific view composition, and provides a [GemMapController]
  /// through the [onMapCreated] callback to interact with the map programmatically.
  ///
  /// Use the [appAuthorization] parameter to pass your project token.
  /// The [initialMapStyleAsset] allows applying a custom map style from the app's
  /// assets when the map is first created.
  ///
  /// ## Example
  ///
  /// ```dart
  /// const GemMap(
  ///   appAuthorization: projectApiToken,
  ///   onMapCreated: (GemMapController controller) {
  ///     // Use controller to center, add overlays, etc.
  ///   },
  /// );
  /// ```
  ///
  /// ## Parameters
  ///
  /// - [onMapCreated]: (void Function(GemMapController)?) Optional callback invoked with a [GemMapController] once the native map has been initialized and is ready for use.
  /// - [androidViewMode]: (AndroidViewMode) Mode for embedding native Android views. Defaults to [AndroidViewMode.auto] which chooses the best mode depending on Android version.
  /// - [coordinates]: (Coordinates?) Optional initial center coordinates for the map.
  /// - [area]: (RectangleGeographicArea?) Optional geographic area to center and fit the map to on creation.
  /// - [zoomLevel]: (int?) Optional initial zoom level for the map center. Useful when [coordinates] is provided.
  /// - [appAuthorization]: (String?) Optional project token used to initialize the SDK. If the SDK is already initialized this parameter is ignored.
  /// - [initialMapStyleAsset]: (String?) Optional path to a `.style` asset declared in `pubspec.yaml`. Example: 'assets/map_styles/my_map_style.style'.
  /// - [initialMapStyleId]: (int?) Optional ContentStore style ID to apply before the first frame. Takes precedence over [initialMapStyleAsset] when both are provided.
  /// - [allowInternetConnection]: (bool) When false, prevents SDK from using network resources during native initialization. Default: `true`.
  /// - [autoUpdateSettings]: (AutoUpdateSettings?) Optional [AutoUpdateSettings] used when loading native binaries; ignored if SDK is already initialized.
  ///
  /// ## See also:
  ///
  /// - [GemMapController] - Control the map after creation.
  /// - [FollowPositionPreferences] - Preferences for following the camera during follow position mode.
  const GemMap({
    super.key,
    final void Function(GemMapController)? onMapCreated,
    final AndroidViewMode androidViewMode = AndroidViewMode.auto,
    final Coordinates? coordinates,
    final RectangleGeographicArea? area,
    final int? zoomLevel,
    final String? appAuthorization,
    final String? initialMapStyleAsset,
    final int? initialMapStyleId,
    final bool allowInternetConnection = true,
    final AutoUpdateSettings? autoUpdateSettings,
  }) : _initialMapStyleAsset = initialMapStyleAsset,
       _initialMapStyleId = initialMapStyleId,
       _appAuthorization = appAuthorization,
       _zoomLevel = zoomLevel,
       _area = area,
       _coordinates = coordinates,
       _androidViewMode = androidViewMode,
       _onMapCreated = onMapCreated,
       _autoUpdateSettings = autoUpdateSettings,
       _allowInternetConnection = allowInternetConnection;

  final MapCreatedCallback? _onMapCreated;
  final AndroidViewMode _androidViewMode;
  final Coordinates? _coordinates;
  final RectangleGeographicArea? _area;
  final int? _zoomLevel;
  final String? _appAuthorization;
  final String? _initialMapStyleAsset;
  final int? _initialMapStyleId;
  final AutoUpdateSettings? _autoUpdateSettings;
  final bool _allowInternetConnection;

  @override
  State createState() => GemMapState();
}

/// State used by [GemMap].
///
/// Responsible for native SDK initialization, creating the [GemMapController],
/// and wiring platform view events to the controller. This state handles initial
/// camera placement when `coordinates` or `area` are provided and sets up a
/// hover timer to detect hovered map labels on desktop/web platforms.
/// ## See also:
///
/// - [GemMap] - The widget this state supports.
/// - [GemMapController] - Controller used to interact with the map.
///
/// {@category Maps & 3D Scenes}
class GemMapState extends State<GemMap> {
  final Completer<GemMapController> _controller = Completer<GemMapController>();
  double? _pixelSize;
  PointerEventHandler? _pointerEventHandler;
  final Map<String, dynamic> creationParams = <String, dynamic>{};
  Point<int>? _lastHoverPosition;
  Timer? _hoverTimer;
  @override
  void initState() {
    unawaited(
      GemKitPlatform.instance
          .loadNative(
            autoUpdateSettings:
                widget._autoUpdateSettings ?? const AutoUpdateSettings(),
            allowInternetConnection: widget._allowInternetConnection,
          )
          .then((final _) {
            if (widget._appAuthorization != null &&
                widget._appAuthorization!.isNotEmpty) {
              SdkSettings.appAuthorization = widget._appAuthorization!;
            }
          }),
    );

    creationParams['mapStyleAssetPath'] = widget._initialMapStyleAsset;
    creationParams['mapStyleId'] = widget._initialMapStyleId;

    super.initState();
  }

  Widget _buildMouseRegion(final Widget child) {
    _pointerEventHandler ??= PointerEventHandler();

    return MouseRegion(
      onEnter: _pointerEventHandler!.onMouseEnter,
      onExit: _pointerEventHandler!.onMouseExit,
      onHover: _pointerEventHandler!.onPointerHover,
      child: Listener(
        onPointerDown: _pointerEventHandler!.onPointerDown,
        onPointerUp: _pointerEventHandler!.onPointerUp,
        onPointerMove: _pointerEventHandler!.onPointerMove,
        onPointerCancel: _pointerEventHandler!.onPointerCancel,
        child: AbsorbPointer(child: child),
      ),
    );
  }

  @override
  Widget build(final BuildContext context) {
    _pixelSize = MediaQuery.devicePixelRatioOf(context);
    if (kIsWeb) {
      return _buildMouseRegion(
        HtmlElementView(
          viewType: 'canvasView',
          onPlatformViewCreated: _onPlatformViewCreated,
        ),
      );
    } else if (Platform.isIOS) {
      return _buildMouseRegion(_buildNativeView(_onPlatformViewCreated));
    } else if (Platform.isAndroid) {
      // Use LayoutBuilder to get the actual widget dimensions
      return _buildMouseRegion(_buildNativeAndroidView(_onPlatformViewCreated));
    } else if (Platform.isLinux) {
      return GemTextureView(onPlatformViewCreated: _onPlatformViewCreatedLinux);
    }
    return Container();
  }

  Widget _buildNativeAndroidView(
    final PlatformViewCreatedCallback onPlatformViewCreated,
  ) {
    // This is used in the platform side to register the view.
    const String viewType = 'plugins.flutter.dev/gem_maps';
    // Pass parameters to the platform side.
    AndroidViewMode viewMode = widget._androidViewMode;
    if (widget._androidViewMode == AndroidViewMode.auto) {
      if (GemKitPlatform.instance.androidVersion != -1 &&
          GemKitPlatform.instance.androidVersion >= 29) {
        viewMode = AndroidViewMode.hybridComposition;
        gemSdkLogger.log(
          Level.FINEST,
          'Auto selected ViewMode. AndroidViewMode.hybridComposition',
        );
      } else {
        viewMode = AndroidViewMode.virtualDisplay;
        gemSdkLogger.log(
          Level.FINEST,
          'Auto selected ViewMode. AndroidViewMode.virtualDisplay',
        );
      }
    }

    if (viewMode == AndroidViewMode.hybridComposition) {
      return PlatformViewLink(
        viewType: viewType,
        surfaceFactory:
            (
              final BuildContext context,
              final PlatformViewController controller,
            ) {
              return AndroidViewSurface(
                controller: controller as AndroidViewController,
                gestureRecognizers:
                    const <Factory<OneSequenceGestureRecognizer>>{},
                hitTestBehavior: PlatformViewHitTestBehavior.opaque,
              );
            },
        onCreatePlatformView: (final PlatformViewCreationParams params) {
          final AndroidViewController controller =
              PlatformViewsService.initExpensiveAndroidView(
                id: params.id,
                viewType: viewType,
                layoutDirection: TextDirection.ltr,
                creationParams: creationParams,
                creationParamsCodec: const StandardMessageCodec(),
                onFocus: () => params.onFocusChanged(true),
              );
          controller.addOnPlatformViewCreatedListener(
            params.onPlatformViewCreated,
          );
          controller.addOnPlatformViewCreatedListener(onPlatformViewCreated);
          unawaited(controller.create());
          return controller;
        },
      );
    } else if (viewMode == AndroidViewMode.textureView) {
      return LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) =>
            OpenGLTextureWidget(
              width: (constraints.maxWidth * _pixelSize!).toInt(),
              height: (constraints.maxHeight * _pixelSize!).toInt(),
              onPlatformViewCreated: _onPlatformViewCreated,
            ),
      );
    }

    return PlatformViewLink(
      viewType: viewType,
      surfaceFactory:
          (
            final BuildContext context,
            final PlatformViewController controller,
          ) {
            return AndroidViewSurface(
              controller: controller as AndroidViewController,
              gestureRecognizers:
                  const <Factory<OneSequenceGestureRecognizer>>{},
              hitTestBehavior: PlatformViewHitTestBehavior.opaque,
            );
          },
      onCreatePlatformView: (final PlatformViewCreationParams params) {
        final AndroidViewController controller =
            PlatformViewsService.initSurfaceAndroidView(
              id: params.id,
              viewType: viewType,
              layoutDirection: TextDirection.ltr,
              creationParams: creationParams,
              creationParamsCodec: const StandardMessageCodec(),
              onFocus: () => params.onFocusChanged(true),
            );
        controller.addOnPlatformViewCreatedListener(
          params.onPlatformViewCreated,
        );
        controller.addOnPlatformViewCreatedListener(onPlatformViewCreated);
        unawaited(controller.create());
        return controller;
      },
    );
  }

  Widget _buildNativeView(
    final PlatformViewCreatedCallback onPlatformViewCreated,
  ) {
    // This is used in the platform side to register the view.
    const String viewType = 'plugins.flutter.dev/gem_maps';

    return UiKitView(
      viewType: viewType,
      onPlatformViewCreated: onPlatformViewCreated,
      creationParams: creationParams,
      creationParamsCodec: const StandardMessageCodec(),
    );
  }

  // ignore: unused_element
  Future<void> _onPlatformViewCreatedLinux(
    final int id,
    final Rectangle<int> viewport,
  ) async {
    await GemKitPlatform.instance.initializationDone;

    final GemMapController controller = await GemMapController.init(
      id,
      this,
      pixelSize: _pixelSize,
    );
    controller.registerForEventsHandler();
    _controller.complete(controller);
    final MapCreatedCallback? onMapCreated = widget._onMapCreated;
    final Coordinates? coordinates = widget._coordinates;
    final RectangleGeographicArea? area = widget._area;
    final int zoomLevel = widget._zoomLevel ?? 16;
    if (coordinates != null) {
      final GemAnimation animation = GemAnimation.none();
      controller.centerOnCoordinates(
        coordinates,
        animation: animation,
        zoomLevel: zoomLevel,
      );
    }
    if (area != null) {
      final GemAnimation animation = GemAnimation.none();
      controller.centerOnArea(area, animation: animation);
    }
    if (onMapCreated != null) {
      onMapCreated(controller);
    }
  }

  /// @nodoc
  Future<void> _onPlatformViewCreated(final int id) async {
    await GemKitPlatform.instance.initializationDone;
    final GemMapController controller = await GemMapController.init(
      id,
      this,
      pixelSize: _pixelSize,
    );

    if (_pointerEventHandler != null) {
      _pointerEventHandler!.registerOnMouseEnterEvent((
        final PointerEnterEvent event,
      ) {
        GemKitPlatform.instance.setMouseInFocus(true, id);
      });
      _pointerEventHandler!.registerOnMouseExitEvent((
        final PointerExitEvent event,
      ) {
        GemKitPlatform.instance.setMouseInFocus(false, id);
      });
      _pointerEventHandler!.registerOnPointerMoveEvent((
        final PointerMoveEvent event,
      ) {
        controller.handleTouchEvent(
          event.device,
          1,
          (event.localPosition.dx * _pixelSize!).toInt(),
          (event.localPosition.dy * _pixelSize!).toInt(),
        );
      });
      _pointerEventHandler!.registerOnPointerDownEvent((
        final PointerDownEvent event,
      ) {
        controller.handleTouchEvent(
          event.device,
          0,
          (event.localPosition.dx * _pixelSize!).toInt(),
          (event.localPosition.dy * _pixelSize!).toInt(),
        );
      });
      _pointerEventHandler!.registerOnPointerUpEvent((
        final PointerUpEvent event,
      ) {
        controller.handleTouchEvent(
          event.device,
          2,
          (event.localPosition.dx * _pixelSize!).toInt(),
          (event.localPosition.dy * _pixelSize!).toInt(),
        );
      });
      _pointerEventHandler!.registerOnPointerCancelEvent((
        final PointerCancelEvent event,
      ) {
        controller.handleTouchEvent(
          event.device,
          3,
          (event.localPosition.dx * _pixelSize!).toInt(),
          (event.localPosition.dy * _pixelSize!).toInt(),
        );
      });
      _pointerEventHandler!.registerOnPointerHoverEvent((
        final PointerHoverEvent event,
      ) {
        final Point<int> currentPosition = Point<int>(
          (event.localPosition.dx * _pixelSize!).toInt(),
          (event.localPosition.dy * _pixelSize!).toInt(),
        );
        if (_lastHoverPosition != currentPosition) {
          _lastHoverPosition = currentPosition;
          _handleHover(currentPosition, controller);
        }
      });
    }
    controller.registerForEventsHandler();
    _controller.complete(controller);
    final MapCreatedCallback? onMapCreated = widget._onMapCreated;
    final Coordinates? coordinates = widget._coordinates;
    final RectangleGeographicArea? area = widget._area;
    final int zoomLevel = widget._zoomLevel ?? 16;
    if (coordinates != null) {
      final GemAnimation animation = GemAnimation.none();
      controller.centerOnCoordinates(
        coordinates,
        animation: animation,
        zoomLevel: zoomLevel,
        viewAngle: 0,
        mapAngle: 0,
      );
    }
    if (area != null) {
      final GemAnimation animation = GemAnimation.none();
      controller.centerOnArea(area, animation: animation);
    }
    if (kIsWeb) {
      controller.preferences.mapDetailsQualityLevel =
          MapDetailsQualityLevel.low;
    }
    if (onMapCreated != null) {
      try {
        onMapCreated(controller);
      } catch (e) {
        gemSdkLogger.log(Level.SEVERE, 'Error in onMapCreated: $e');
      }
    }
  }

  @override
  void didUpdateWidget(final GemMap oldWidget) {
    super.didUpdateWidget(oldWidget);
  }

  @override
  void dispose() {
    unawaited(_disposeController());
    super.dispose();
  }

  Future<void> _disposeController() async {
    final GemMapController controller = await _controller.future;
    final bool isAlive = GemKitPlatform.instance.gemKit.isObjectAlive(
      controller.pointerId,
    );
    if (!isAlive) {
      return;
    }
    await controller.dispose();
  }

  void _handleHover(Point<int> position, GemMapController controller) {
    // Cancel any previous timer
    _hoverTimer?.cancel();

    // Start a new 1-second timer
    _hoverTimer = Timer(const Duration(seconds: 1), () {
      controller.highlightHoveredMapLabel(position, selectMapObject: true);
    });

    // Immediate feedback while hovering
    controller.highlightHoveredMapLabel(position);
  }
}

/// A helper that centralizes mouse and pointer event handling for the map widget.
///
/// This class is used internally and should not be used directly by the API user.
/// See the `register...` methods to register callbacks for various events in the
/// [GemMapController] class.
///
/// @ndoc
class PointerEventHandler {
  /// Creates a new [PointerEventHandler].
  ///
  /// The handler does not attach itself to any widget directly. Instead the
  /// owning [GemMapState] will register callbacks by calling the `register...`
  /// methods and forward framework pointer events into this handler. This
  /// indirection keeps pointer-related logic decoupled and testable.
  PointerEventHandler();

  void Function(PointerEnterEvent)? _mouseEnteredCallback;
  void Function(PointerExitEvent)? _mouseExitedCallback;
  void Function(PointerHoverEvent)? _pointerHoverEventCallback;
  void Function(PointerDownEvent)? _pointerDownEventCallback;
  void Function(PointerMoveEvent)? _pointerMoveEventCallback;
  void Function(PointerUpEvent)? _pointerUpEventCallback;
  void Function(PointerCancelEvent)? _pointerCancelEventCallback;

  /// Registers a callback for mouse enter events.
  ///
  /// The provided callback will be invoked with the original Flutter
  /// [PointerEnterEvent] when the mouse enters the map widget bounds.
  void registerOnMouseEnterEvent(final void Function(PointerEnterEvent) pFunc) {
    _mouseEnteredCallback = pFunc;
  }

  /// Registers a callback for mouse exit events.
  ///
  /// The provided callback is invoked when the mouse leaves the map widget
  /// bounds.
  void registerOnMouseExitEvent(final void Function(PointerExitEvent) pFunc) {
    _mouseExitedCallback = pFunc;
  }

  /// Registers a callback for pointer hover events.
  ///
  /// Hover events are typically used on desktop/web to provide tooltip-like
  /// interactions for map labels. The handler will forward [PointerHoverEvent]
  /// instances directly to the registered callback.
  void registerOnPointerHoverEvent(
    final void Function(PointerHoverEvent) pFunc,
  ) {
    _pointerHoverEventCallback = pFunc;
  }

  /// Invokes the mouse enter callback.
  void onMouseEnter(final PointerEnterEvent event) {
    _mouseEnteredCallback?.call(event);
  }

  /// Invokes the mouse exit callback.
  void onMouseExit(final PointerExitEvent event) {
    _mouseExitedCallback?.call(event);
  }

  /// Invokes the pointer hover callback.
  void onPointerHover(final PointerHoverEvent event) {
    _pointerHoverEventCallback?.call(event);
  }

  /// Registers a callback for pointer down events.
  void registerOnPointerDownEvent(final void Function(PointerDownEvent) pFunc) {
    _pointerDownEventCallback = pFunc;
  }

  /// Registers a callback for pointer move events.
  void registerOnPointerMoveEvent(final void Function(PointerMoveEvent) pFunc) {
    _pointerMoveEventCallback = pFunc;
  }

  /// Registers a callback for pointer up events.
  void registerOnPointerUpEvent(final void Function(PointerUpEvent) pFunc) {
    _pointerUpEventCallback = pFunc;
  }

  /// Registers a callback for pointer cancel events.
  void registerOnPointerCancelEvent(
    final void Function(PointerCancelEvent) pFunc,
  ) {
    _pointerCancelEventCallback = pFunc;
  }

  /// Invokes the pointer down callback.
  void onPointerDown(final PointerDownEvent event) {
    _pointerDownEventCallback?.call(event);
  }

  /// Invokes the pointer move callback.
  void onPointerMove(final PointerMoveEvent event) {
    _pointerMoveEventCallback?.call(event);
  }

  /// Invokes the pointer up callback.
  void onPointerUp(final PointerUpEvent event) {
    _pointerUpEventCallback?.call(event);
  }

  /// Invokes the pointer cancel callback.
  void onPointerCancel(final PointerCancelEvent event) {
    _pointerCancelEventCallback?.call(event);
  }
}

/// Mode of hosting native Android view in Flutter
///
/// {@category Maps & 3D Scenes}
enum AndroidViewMode {
  /// Automatically select the most appropriate view mode based on Android version.
  auto,

  /// Use hybrid composition (recommended for modern Android versions).
  ///
  /// When the host app sets `io.flutter.embedding.android.EnableHcpp=true` in
  /// its AndroidManifest, the Flutter engine transparently upgrades this path
  /// to Hybrid Composition++ (HCPP) on Android 34+ with Vulkan + Impeller. The
  /// widget tree below stays unchanged; on non-qualifying devices the engine
  /// silently keeps classic HC.
  hybridComposition,

  /// Use a virtual display to host the native view. Compatibility fallback for
  /// older devices or special cases.
  virtualDisplay,

  /// Render the native map using a TextureView. Useful when OpenGL texture
  /// rendering is required.
  textureView,
}

/// Callback method for when the map is ready to be used.
///
/// Pass to [GemMap._onMapCreated] to receive a [GemMapController] when the map is created.
///
/// {@category Maps & 3D Scenes}
typedef MapCreatedCallback = void Function(GemMapController controller);
