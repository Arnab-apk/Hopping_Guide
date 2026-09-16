// SPDX-FileCopyrightText: 2023-2026 Magic Lane International B.V. <info@magiclane.com>
// SPDX-License-Identifier: LicenseRef-MagicLane-Proprietary
//
// For the latest licensing terms and conditions, see https://www.magiclane.com/web/terms-and-conditions#terms-of-service.
// For further information use the contact form at https://www.magiclane.com/web/contact.

/// @nodoc
library;

import 'dart:async';
import 'dart:collection';
import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:magiclane_maps_flutter/core.dart';
import 'package:magiclane_maps_flutter/map.dart';
import 'package:magiclane_maps_flutter/src/core/common/gem_object_interface.dart';
import 'package:magiclane_maps_flutter/src/core/images/img_cache.dart';
import 'package:magiclane_maps_flutter/src/core/private/event_handler.dart';
import 'package:magiclane_maps_flutter/src/gem_kit_native.dart'
    if (dart.library.html) 'package:magiclane_maps_flutter/src/gem_kit_native_web.dart';
import 'package:magiclane_maps_flutter/src/loggers/app_logger.dart';
import 'package:magiclane_maps_flutter/src/obj_type.dart';
import 'package:meta/meta.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class _CacheEntry {
  _CacheEntry(this.image, this.timestamp);

  final Uint8List image;
  DateTime timestamp;
}

/// Platform initialization.
class GemKitPlatform extends PlatformInterface {
  GemKitPlatform() : super(token: gemToken) {
    _startPeriodicCleanup();
  }

  // Caches small UI bitmaps only: landmark icons, navigation indicators, route
  // signpost glyphs, etc. Keyed by stable imageId from the SDK, so the working
  // set is bounded by the number of distinct icons in use — not by map
  // interaction. Do NOT add map tiles, camera buffers, or anything sized by
  // viewport here; those have their own native-side caches.
  final Map<String, _CacheEntry> _cache = HashMap<String, _CacheEntry>();
  final Duration _cacheDuration = const Duration(minutes: 1);
  // ignore: unused_field, use_late_for_private_fields_and_variables
  static Timer? _cleanupTimer;

  /// Constructs a GemMapsPlatform.
  static final Object gemToken = Object();

  GemSdkNative gemKit = GemSdkNative();

  static GemKitPlatform? _gemInstance;
  static void Function(SdkEvent, String)? _onSdkExceptionCallback;

  /// The default instance of [GemKitPlatform] to use.
  static GemKitPlatform get instance {
    _gemInstance ??= GemKitPlatform();
    return _gemInstance!;
  }

  static Future<void> disposeGemSdk() async {
    _cleanupTimer?.cancel();
    SdkSettings.reset();
    SoundPlayingService.reset();

    final Map<dynamic, EventHandler> mapCopy = <dynamic, EventHandler>{
      ...instance.eventHandlerMap,
    };
    for (final MapEntry<dynamic, EventHandler> entry in mapCopy.entries) {
      final int? idAsInt = int.tryParse(entry.key);
      if (idAsInt == null) {
        continue;
      }
      // EventHandler exposes its teardown in two halves:
      //   * nativeClear()    — talks to the native side (e.g. removeListener)
      //   * clearListeners() — pure Dart, nulls callback fields
      // dispose() runs both in order. When the native object is already dead,
      // the nativeClear() call would be wasted work at best and an FFI call
      // against a freed pointer at worst — but skipping the WHOLE teardown
      // (as the original code did) leaks every captured closure on the Dart
      // side. So: full dispose() while alive, Dart-only clearListeners()
      // when dead.
      final bool isAlive = instance.gemKit.isObjectAlive(idAsInt);
      if (isAlive) {
        await entry.value.dispose();
      } else {
        entry.value.clearListeners();
      }
    }
    instance.eventHandlerMap.clear();
    instance._cache.clear();
    ImgCache.instance.clear();
    await GemKitPlatform.instance
        .getChannel(mapId: -1)
        .invokeMethod(
          'releaseEngine',
          jsonEncode(<String, dynamic>{'dummyKey': 'dummyValue'}),
        );
    _gemInstance?.gemKit.release();
    _gemInstance = null;
  }

  /// Platform-specific implementations should set this with their own platform-specific class that extends [GemKitPlatform] when they register themselves.
  static set instance(final GemKitPlatform instance) {
    PlatformInterface.verifyToken(instance, gemToken);
    _gemInstance = instance;
  }

  /// Initializes the platform interface with [mapId].
  ///
  /// This method is called when the plugin is first initialized.
  Future<dynamic> init(final int mapId) async {
    final MethodChannel channel = ensureChannelInitialized(mapId);
    final String? result = await channel.invokeMethod<String>('waitForViewId');
    final dynamic viewId = jsonDecode(result!);
    return viewId;
  }

  // Keep a collection of id -> channel
  // Every method call passes the int mapId
  final Map<int, MethodChannel> _channels = <int, MethodChannel>{};

  /// Returns the channel for [mapId], creating it if it doesn't already exist.
  @visibleForTesting
  MethodChannel ensureChannelInitialized(final int mapId) {
    MethodChannel? channel = _channels[mapId];
    if (channel == null) {
      if (mapId == -1) {
        channel = const MethodChannel('plugins.flutter.dev/gem_engine');
      } else {
        channel = MethodChannel('plugins.flutter.dev/gem_maps_$mapId');
      }
      channel.setMethodCallHandler(
        (final MethodCall call) => _handleMethodCall(call, mapId),
      );
      _channels[mapId] = channel;
    }
    return channel;
  }

  // Events arriving from native before the SDK signals initCompleted are
  // queued here and replayed once initialization is really done.
  final List<MethodCall> _pendingMethodCalls = <MethodCall>[];
  bool _pendingDrainScheduled = false;

  Future<dynamic> _handleMethodCall(
    final MethodCall call,
    final int mapId,
  ) async {
    // exceptionCallback is the SDK's own error channel — never queue it,
    // otherwise an init-time failure stays invisible to onSdkException.
    if (call.method != 'exceptionCallback' &&
        (!gemKit.initHasBeenDone || _pendingDrainScheduled)) {
      _pendingMethodCalls.add(call);
      _ensurePendingDrainScheduled();
      return null;
    }
    return _dispatchMethodCall(call);
  }

  void _ensurePendingDrainScheduled() {
    if (_pendingDrainScheduled) {
      return;
    }
    _pendingDrainScheduled = true;
    gemKit.initializationDone.then((final _) => _drainPendingMethodCalls());
  }

  Future<void> _drainPendingMethodCalls() async {
    try {
      // Drain until empty so events appended during dispatch (the await
      // below yields to the event loop, allowing the channel to deliver
      // more events) are also replayed in arrival order.
      while (_pendingMethodCalls.isNotEmpty) {
        final MethodCall call = _pendingMethodCalls.removeAt(0);
        try {
          await _dispatchMethodCall(call);
        } catch (e, st) {
          gemSdkLogger.warning(
            '[SdkDebug] Failed to replay queued native event '
            '"${call.method}": $e\n$st',
          );
        }
      }
    } finally {
      _pendingDrainScheduled = false;
    }
  }

  Future<dynamic> _dispatchMethodCall(final MethodCall call) async {
    if (call.method == 'sdkSettingsEvent') {
      final Map<dynamic, dynamic> payload = Map<dynamic, dynamic>.from(
        call.arguments as Map<dynamic, dynamic>,
      );
      SdkSettings.offBoardListener.handleEvent(payload);
    } else if (call.method == 'exceptionCallback') {
      _onSdkExceptionCallback?.call(
        SdkEventExtension.fromId(call.arguments['code'] as int),
        call.arguments['message'] as String,
      );
    } else {
      await gemEventsMethodHandler(call);
    }
  }

  /// Map with viewId and EventHandler
  Map<dynamic, EventHandler> eventHandlerMap = <dynamic, EventHandler>{};

  void registerEventHandler(final dynamic listenerId, final EventHandler ptr) {
    eventHandlerMap[listenerId.toString()] = ptr;
  }

  void unregisterEventHandler(final dynamic listenerId) {
    eventHandlerMap.remove(listenerId.toString());
  }

  void filterEvent(
    final dynamic listenerId,
    final String eventName,
    final bool blacklist,
  ) {
    callObjectMethod(<String, Object>{
      'id': 0,
      'class': 'EventHandlerFilter',
      'method': 'filterEvent',
      'args': <String, dynamic>{
        'listener': listenerId,
        'event': eventName,
        'isBlacklist': blacklist,
      },
    });
  }

  void filterEvents(
    final dynamic listenerId,
    final List<String> eventNames,
    final bool blacklist,
  ) {
    callObjectMethod(<String, Object>{
      'id': 0,
      'class': 'EventHandlerFilter',
      'method': 'filterEvents',
      'args': <String, dynamic>{
        'listener': listenerId,
        'events': eventNames,
        'isBlacklist': blacklist,
      },
    });
  }

  EventHandler? getEventHandler(final dynamic listenerId) {
    return eventHandlerMap[listenerId.toString()];
  }

  void gemEventsMethodHandlerAndroid(final MethodCall methodCall) {
    final dynamic decodedJson = jsonDecode(methodCall.arguments);
    for (final dynamic iter in decodedJson) {
      dynamic name;
      final BigInt? parsedBigInt = BigInt.tryParse(iter['eventName']);
      if (parsedBigInt != null) {
        name = parsedBigInt.toSigned(64);
      } else {
        final int? parsedInt = int.tryParse(iter['eventName']);
        if (parsedInt != null) {
          name = parsedInt;
        } else {
          // Handle the case where the conversion failed
          // or assign a default value if desired.
        }
      }
      final Map<dynamic, dynamic> decodedArgs = jsonDecode(iter['arguments']);
      eventHandlerMap[name.toString()]?.handleEvent(decodedArgs);
    }
  }

  void nativeMethodHandler(final dynamic iter) {
    dynamic name;
    final BigInt? parsedBigInt = BigInt.tryParse(iter['eventName']);
    if (parsedBigInt != null) {
      name = parsedBigInt.toSigned(64);
    } else {
      final int? parsedInt = int.tryParse(iter['eventName']);
      if (parsedInt != null) {
        name = parsedInt;
      } else {
        // Handle the case where the conversion failed
        // or assign a default value if desired.
      }
    }
    eventHandlerMap[name.toString()]?.handleEvent(iter['arguments']);
  }

  Future<dynamic> gemEventsMethodHandler(final MethodCall methodCall) async {
    dynamic name;
    if (methodCall.method == 'notifyEvents') {
      gemEventsMethodHandlerAndroid(methodCall);
    } else {
      final BigInt? parsedBigInt = BigInt.tryParse(methodCall.method);
      if (parsedBigInt != null) {
        name = parsedBigInt.toSigned(64);
      } else {
        final int? parsedInt = int.tryParse(methodCall.method);
        if (parsedInt != null) {
          name = parsedInt;
        } else {
          // Handle the case where the conversion failed
          // or assign a default value if desired.
        }
      }
      eventHandlerMap[name.toString()]?.handleEvent(
        jsonDecode(methodCall.arguments),
      );
    }
  }

  MethodChannel getChannel({final int mapId = 0}) {
    return ensureChannelInitialized(mapId);
  }

  String callObjectMethod(
    final Map<String, Object> jsonCommand, {
    LogPrivacyLevel logPrivacyLevel = LogPrivacyLevel.printAllInfo,
  }) {
    final String result = gemKit.callObjectMethod(
      jsonCommand,
      logPrivacyLevel: logPrivacyLevel,
    );

    try {
      final dynamic json = jsonDecode(result);
      final int? error = json['gemApiError'];

      ApiErrorServiceImpl.apiErrorAsInt = error is int ? error : 0;
    } catch (e) {
      ApiErrorServiceImpl.apiErrorAsInt = 0;
    }

    return result;
  }

  String callCreateObject(final String json) {
    return gemKit.callCreateObject(json);
  }

  void callDeleteObject(final String json) {
    gemKit.callDeleteObject(json);
  }

  GemObject registerWeakRelease(
    final Object obj,
    final dynamic nativeObjectId,
    final int timestamp,
  ) {
    return gemKit.registerWeakRelease(obj, nativeObjectId, timestamp);
  }

  void registerCallbackPointer() {
    //gemKit.registerCallbackPointer();
  }

  Future<void> loadNative({
    final String? appAuthorization,
    final bool allowInternetConnection = true,
    final AutoUpdateSettings autoUpdateSettings = const AutoUpdateSettings(),
    final void Function(SdkEvent, String)? onSdkException,
    @experimental final int? aVar,
  }) async {
    if (!gemKit.initHasBeenDone && !gemKit.loadNativeCalled) {
      _onSdkExceptionCallback = onSdkException;

      ensureChannelInitialized(-1);
      await GemKitPlatform.instance
          .getChannel(mapId: -1)
          .invokeMethod(
            'initializeGemSdk',
            jsonEncode(<String, dynamic>{
              'initializeGemSdk': 'dummyValue',
              'aVar': aVar,
            }),
          );

      await gemKit.loadNative();
      if (androidVersion > -1) {
        final dynamic response = await GemKitPlatform.instance
            .getChannel(mapId: -1)
            .invokeMethod(
              'SoundServiceGetPointer',
              jsonEncode(<String, dynamic>{'dummy': 'dummytext'}),
            );

        // Parse the JSON response
        final dynamic address = response['address'];
        final dynamic addressTtsPlayer = response['addressTtsPlayer'];
        final dynamic addressRawPlayer = response['addressRawPlayer'];

        final dynamic _ = staticMethod(
          'SoundService',
          'init',
          args: <String, dynamic>{
            'soundPlayingService': address,
            'ttsSoundPlayer': addressTtsPlayer,
            'humanVoiceSoundPlayer': addressRawPlayer,
          },
        );
      }
      if (appAuthorization != null) {
        SdkSettings.appAuthorization = appAuthorization;
      }

      gemSdkLogger.finest(
        '[SdkDebug][LoadNative] Setting allow connection (allowInternetConnection: $allowInternetConnection) (canDoAutoUpdateResources: ${autoUpdateSettings.isAutoUpdateForResourcesEnabled})',
      );

      SdkSettings.offBoardListener.autoUpdateSettings = autoUpdateSettings;
      await SdkSettings.setAllowInternetConnection(allowInternetConnection);
      SdkSettings.setTTSVoiceByLanguage(SdkSettings.language);

      //staticMethod('SoundService', 'init');
    }
  }

  bool isObjectAlive(final dynamic id) {
    return gemKit.isObjectAlive(id);
  }

  int get aliveObjectsCount => gemKit.aliveObjectsCount;

  int get androidVersion {
    return gemKit.getAndroidVersion;
  }

  void setLibLoaded() {
    gemKit.setLibLoaded();
  }

  RenderableImg? callGetFlutterImg(
    final int pointerId,
    final int width,
    final int height,
    final int imageType, {
    final String? arg,
    final int? imageId,
    required final bool allowResize,
  }) {
    return gemKit.callGetFlutterImg(
      pointerId,
      width,
      height,
      imageType,
      arg,
      allowResize,
    );
  }

  Uint8List? callGetCameraBuffer(int id) {
    return gemKit.callGetCameraBuffer(id); // All memory work done already
  }

  Uint8List? callGetImage(
    final int pointerId,
    final String className,
    final int width,
    final int height,
    final int imageType, {
    final String? arg,
    final int? imageId,
    final bool allowResize = false,
  }) {
    final DateTime now = DateTime.now(); // Store current time in a variable

    if (imageId != null) {
      final String cacheKey = _generateCacheKey(imageId, width, height);
      final _CacheEntry? cacheEntry = _cache[cacheKey];
      if (cacheEntry != null &&
          now.difference(cacheEntry.timestamp) < _cacheDuration) {
        // Return cached image if it is still valid
        cacheEntry.timestamp = now; // Update timestamp
        return cacheEntry.image;
      }
    }
    // Get new image and update cache
    final Uint8List? image = gemKit.callGetImage(
      className,
      pointerId,
      width,
      height,
      allowResize,
      imageType,
      arg: arg,
    );
    if (image == null) {
      return null;
    }
    if (imageId != null) {
      final String cacheKey = _generateCacheKey(imageId, width, height);
      _cache[cacheKey] = _CacheEntry(image, now); // Use the stored current time
    }

    return image;
  }

  void _clearStaleCacheEntries([
    final int? imageId,
    final int? width,
    final int? height,
  ]) {
    final DateTime now = DateTime.now();
    final List<String> keysToRemove = <String>[];
    _cache.forEach((final String key, final _CacheEntry entry) {
      if (now.difference(entry.timestamp) >= _cacheDuration ||
          (imageId != null &&
              key.startsWith('$imageId-') &&
              !key.endsWith('-$width-$height'))) {
        keysToRemove.add(key);
      }
    });

    keysToRemove.forEach(_cache.remove);
  }

  void _startPeriodicCleanup() {
    _cleanupTimer = Timer.periodic(_cacheDuration, (final Timer timer) {
      _clearStaleCacheEntries();
    });
  }

  Future<void> get initializationDone async {
    return gemKit.initializationDone;
  }

  dynamic createGemImage(final Uint8List data, final int imageType) {
    return gemKit.createGemImage(data, imageType);
  }

  void deleteCPointer(final dynamic pointer, final ObjType objType) {
    gemKit.deleteCPointer(pointer, objType);
  }

  String _generateCacheKey(
    final int imageId,
    final int width,
    final int height,
  ) {
    return '$imageId-$width-$height';
  }

  Future<dynamic> addList({
    required final MapViewMarkerCollections object,
    required final List<MarkerWithRenderSettings> list,
    required final MarkerCollectionRenderSettings settings,
    required final String name,
    required final dynamic parentMapId,
    final MarkerType markerType = MarkerType.point,
  }) async {
    return gemKit.addList(
      object: object,
      list: list,
      settings: settings,
      name: name,
      parentMapId: parentMapId,
      markerType: markerType,
    );
  }

  dynamic toNativePointer(final Uint8List data) {
    return gemKit.toNativePointer(data);
  }

  void freeNativePointer(final dynamic pointer) {
    gemKit.freeNativePointer(pointer);
  }

  void setMouseInFocus(final bool mouseInFocus, final int viewId) {
    gemKit.setMouseInFocus(mouseInFocus, viewId);
  }

  Future<bool> askForLocationPermission() async {
    return gemKit.askForLocationPermission();
  }

  bool get is32BitSystem {
    return gemKit.is32BitSystem;
  }

  bool get isSdkInitialized {
    return gemKit.isSdkInitialized;
  }
}

class ApiErrorServiceImpl {
  static GemError _error = GemError.success;
  static void Function(GemError error)? _onErrorUpdate;

  // Private setter
  static set apiErrorAsInt(final int errorCode) {
    _error = GemErrorExtension.fromCode(errorCode);
    _onErrorUpdate?.call(GemErrorExtension.fromCode(errorCode));
  }

  // Private setter with GemError
  static set apiError(final GemError error) {
    _error = error;
    _onErrorUpdate?.call(error);
  }

  static GemError get apiError => _error;

  static void registerOnErrorUpdate(
    final void Function(GemError error)? callback,
  ) {
    _onErrorUpdate = callback;
  }
}

class OperationResult {
  OperationResult(this.data);
  final Map<String, dynamic> data;

  dynamic operator [](final String key) {
    return data[key];
  }

  bool containsKey(final String key) {
    return data.containsKey(key);
  }

  // GemError get errorCode => GemErrorExtension.fromCode(data['result']);

  // bool get isSuccess => errorCode == GemError.success;
  // bool get isNotSuccess => errorCode != GemError.success;

  @override
  String toString() {
    return data.toString();
  }
}

OperationResult staticMethod(
  final String className,
  final String method, {
  final Object? args,
  final LogPrivacyLevel logPrivacyLevel = LogPrivacyLevel.printAllInfo,
}) {
  return objectMethod(
    0,
    className,
    method,
    args: args,
    logPrivacyLevel: logPrivacyLevel,
  );
}

OperationResult objectMethod(
  final int id,
  final String className,
  final String method, {
  final Object? args,
  final int dependencyId = -1,
  final LogPrivacyLevel logPrivacyLevel = LogPrivacyLevel.printAllInfo,
}) {
  final Map<String, Object> json = <String, Object>{
    'id': id,
    'class': className,
    'method': method,
    'args': args ?? <String, dynamic>{},
    'dependencyId': dependencyId,
  };

  final String resultStr = GemKitPlatform.instance.callObjectMethod(
    json,
    logPrivacyLevel: logPrivacyLevel,
  );
  final OperationResult result = OperationResult(jsonDecode(resultStr));

  if (dependencyId != -1 &&
      result.containsKey('errorMessage') &&
      result['errorMessage'] == 'Dependency is no longer alive') {
    throw MapDisposedException(id: dependencyId, json: json);
  }

  return result;
}

/// @nodoc
enum LogPrivacyLevel { printAllInfo, hideArgumentValues, noLog }
