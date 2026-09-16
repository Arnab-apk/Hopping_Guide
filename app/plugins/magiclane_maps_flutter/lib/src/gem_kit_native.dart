// SPDX-FileCopyrightText: 2023-2026 Magic Lane International B.V. <info@magiclane.com>
// SPDX-License-Identifier: LicenseRef-MagicLane-Proprietary
//
// For the latest licensing terms and conditions, see https://www.magiclane.com/web/terms-and-conditions#terms-of-service.
// For further information use the contact form at https://www.magiclane.com/web/contact.

/// @nodoc
library;

import 'dart:async';
import 'dart:convert';
import 'dart:ffi';
import 'dart:io';
import 'dart:isolate';

import 'package:ffi/ffi.dart';
import 'package:flutter/services.dart';
import 'package:logging/logging.dart';
import 'package:magiclane_maps_flutter/core.dart';
import 'package:magiclane_maps_flutter/map.dart';
import 'package:magiclane_maps_flutter/src/_ffi/generated_binding.dart'
    as native_bindings;
import 'package:magiclane_maps_flutter/src/core/common/gem_object_interface.dart';
import 'package:magiclane_maps_flutter/src/core/common/gem_object_other.dart';
import 'package:magiclane_maps_flutter/src/gem_kit_native_utils.dart';
import 'package:magiclane_maps_flutter/src/gem_kit_platform_interface.dart';
import 'package:magiclane_maps_flutter/src/loggers/app_logger.dart';
import 'package:magiclane_maps_flutter/src/obj_type.dart';

Pointer<Uint8> passBinaryDataToC(final Uint8List binaryData) {
  // Allocate memory for the binary data
  final Pointer<Uint8> dataPointer = malloc.allocate<Uint8>(binaryData.length);

  // Copy the Uint8List data to the allocated memory
  for (int i = 0; i < binaryData.length; i++) {
    dataPointer[i] = binaryData[i];
  }
  return dataPointer;
}

typedef DeletePointerC =
    Void Function(Pointer<Void> pointerVal, Int64 pointerType);
typedef DeletePointerDart =
    void Function(Pointer<Void> pointerVal, int pointerType);

typedef GetBytesC = Pointer<Uint8> Function(Pointer<Void> pointerVal);
typedef GetBytesDart = Pointer<Uint8> Function(Pointer<Void> pointerVal);

typedef GetImageBufferC =
    Pointer<Void> Function(
      Int64 pointerId,
      Pointer<Utf8> className,
      Int32 width,
      Int32 height,
      Bool allowResize,
      Int32 imgType,
      Pointer<Utf8> arg,
      Int32 argLen,
      Int32 classNameLen,
    );
typedef GetImageBufferDart =
    Pointer<Void> Function(
      int pointerId,
      Pointer<Utf8> className,
      int width,
      int height,
      bool allowResize,
      int imgType,
      Pointer<Utf8> arg,
      int arglen,
      int classNameLen,
    );

sealed class FlutterImgInfo extends Struct {
  @Int32()
  external int width;

  @Int32()
  external int height;

  external Pointer<Void> ptr;
}

typedef CreateImgInfoC =
    FlutterImgInfo Function(
      Int64 pointerId,
      Int32 width,
      Int32 height,
      Int32 imgType,
      Pointer<Utf8> arg,
      Int32 arglen,
      Bool allowResize,
    );
typedef CreateImgInfoDart =
    FlutterImgInfo Function(
      int pointerId,
      int width,
      int height,
      int imgType,
      Pointer<Utf8> arg,
      int arglen,
      bool allowResize,
    );

sealed class CameraBuffer extends Struct {
  external Pointer<Char> buffer;

  @Int32()
  external int size;
}

typedef GetCameraBufferC = CameraBuffer Function(Int64 pointerId);
typedef GetCameraBufferDart = CameraBuffer Function(int pointerId);

final DynamicLibrary libToLoad = Platform.isWindows
    ? DynamicLibrary.open('GEMWebRTC.dll')
    : Platform.isLinux
    ? DynamicLibrary.open('libGEM.so')
    : Platform.isAndroid
    ? DynamicLibrary.open('libGEM.so')
    : DynamicLibrary.process();

class GemSdkNative {
  static int? cookie;
  bool initHasBeenDone = false;
  bool loadNativeCalled = false;
  dynamic handleDartObject;
  dynamic _callGetOsVersion;
  dynamic _callGetFlutterImg;
  dynamic _callIsObjectAlive;
  dynamic _callGetAliveObjectsCount;
  dynamic _callDeletePointer;
  dynamic _callGetBytes;
  dynamic _callGetCameraBuffer;
  dynamic _callGetSizeOfBytes;
  dynamic _callGetImageBuffer;
  dynamic _callCreateGemImage;
  dynamic _callIsSdkInitialized;
  native_bindings.GEMKitFFigen? gemWebRTCNative;

  ReceivePort? _nativePort;
  StreamSubscription<dynamic>? _nativePortSubscription;
  StreamSubscription<LogRecord>? _logSubscription;

  static int androidVersion = -1;
  int get getAndroidVersion {
    return androidVersion;
  }

  Completer<void> initializationCompleter = Completer<void>();
  Future<void> get initializationDone => initializationCompleter.future;
  Future<void> loadNative() async {
    setupLogging();
    if (loadNativeCalled) {
      return;
    }

    loadNativeCalled = true;
    if (gemWebRTCNative == null) {
      final Pointer<T> Function<T extends NativeType>(String symbolName)
      lookUp = libToLoad.lookup;
      gemWebRTCNative = native_bindings.GEMKitFFigen.fromLookup(lookUp);
      handleDartObject = libToLoad
          .lookupFunction<
            Void Function(Handle, Int64, Int64),
            void Function(Object, int, int)
          >('HandleDartObject');

      _callGetOsVersion = libToLoad
          .lookupFunction<Int Function(), int Function()>('getOSVersionNumber');
      _callIsObjectAlive = libToLoad
          .lookupFunction<Bool Function(Int64), bool Function(int)>(
            'IsObjectAlive',
          );
      _callGetAliveObjectsCount = libToLoad
          .lookupFunction<Int64 Function(), int Function()>(
            'GetAliveObjectsCount',
          );

      _callGetFlutterImg = libToLoad
          .lookupFunction<CreateImgInfoC, CreateImgInfoDart>('getFlutterImg');

      _callDeletePointer = libToLoad
          .lookupFunction<DeletePointerC, DeletePointerDart>('deletePointer');
      _callGetBytes = libToLoad.lookupFunction<GetBytesC, GetBytesDart>(
        'getBytes',
      );

      _callGetCameraBuffer = libToLoad
          .lookupFunction<GetCameraBufferC, GetCameraBufferDart>(
            'getCameraBuffer',
          );

      _callGetImageBuffer = libToLoad
          .lookupFunction<GetImageBufferC, GetImageBufferDart>(
            'getImageBuffer',
          );
      _callGetSizeOfBytes = libToLoad
          .lookupFunction<
            Int Function(Pointer<Void>),
            int Function(Pointer<Void>)
          >('getBytesSize');
      _callCreateGemImage = libToLoad
          .lookupFunction<
            Int64 Function(Pointer<Uint8>, Int64, Int32),
            int Function(Pointer<Uint8>, int, int)
          >('createGemImage');
      _callIsSdkInitialized = libToLoad
          .lookupFunction<Bool Function(), bool Function()>('isSdkInitialized');

      //if(Platform.isAndroid)
      {
        cookie = gemWebRTCNative!.Dart_InitializeApiDLFunc(
          NativeApi.initializeApiDLData,
        );
        final ReceivePort pub = ReceivePort();
        _nativePort = pub;
        _nativePortSubscription = pub.listen((final dynamic message) {
          if (message.toString() == 'initCompleted') {
            if (!initHasBeenDone) {
              initHasBeenDone = true;
              gemSdkLogger.fine('GEM SDK initialized');
              initializationCompleter.complete();
            }
          } else {
            final dynamic decodedMessage = jsonDecode(message);
            if (Debug.logListenerMethod) {
              if (decodedMessage['isSensitive'] != true) {
                gemSdkLogger.finest(
                  '[SdkDebug][ListenerMethod] Received: $message',
                );
              } else {
                gemSdkLogger.finest(
                  '[SdkDebug][ListenerMethod] Received: SENSITIVE DATA HIDDEN',
                );
              }
            }
            GemKitPlatform.instance.nativeMethodHandler(decodedMessage);
          }
        });

        gemWebRTCNative!.set_dart_port(pub.sendPort.nativePort);
        androidVersion = _callGetOsVersion();
        await initializationCompleter.future;

        //
      }
    }
  }

  void setupLogging() {
    // Drop any previous subscription before installing a new one. Without
    // this, repeated calls (notably across a hot restart, where the isolate
    // survives but [loadNative] runs again) stack listeners on the same root
    // logger and every line is printed once per accumulated subscription.
    _logSubscription?.cancel();

    _logSubscription = Logger.root.onRecord.listen((final LogRecord rec) {
      // Format the timestamp to display only Date, Hour, Minute, and Second
      final DateTime time = rec.time;
      final String formattedTime =
          '${time.year}-${time.month.toString().padLeft(2, '0')}-${time.day.toString().padLeft(2, '0')} '
          '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}:${time.second.toString().padLeft(2, '0')}';

      final String logMessage =
          '${rec.level.name}: $formattedTime: ${rec.message}';

      // Output to console
      // ignore: avoid_print
      print(logMessage);
    });
  }

  void loadNativeD() {}
  void isolateEntryPoint(final SendPort sendPort) {
    // This function runs in a separate isolate
    final ReceivePort receivePort = ReceivePort();
    sendPort.send(receivePort.sendPort);

    // Wait for messages from the main isolate
    receivePort.listen((final dynamic message) {
      if (message is Function) {
        // Register the isolate callback with the main isolate
        //final OnNotifyEventDart callback = onNotifyEventIsolate;
        //message(callback);
      }
    });
  }

  void registerCallbackPointer() {
    // final receivePort = ReceivePort();
    //Isolate.spawn(_sentryIsolate, _SentryIsolateMessage(receivePort.sendPort, isolateId, nativeLibraryPath));
    //_callbackStream = receivePort.listen((dynamic _) { _libraryExecuteCallbacks(isolateId); });
    final native_bindings.Dart_onNotifyEvent pointer = Pointer.fromFunction(
      onNotifyEvent,
    );
    gemWebRTCNative!.native_register_callback(pointer);
  }

  static void onNotifyEvent(final Pointer<Char> pChar) {
    if (pChar != nullptr) {
      // final response = pChar.cast<Utf8>().toDartString();
      // final decodeId = jsonDecode(response);
    }
  }

  void assertObjectAlive(final Map<String, dynamic> jsonStr) {
    final dynamic id = jsonStr['id'];

    if (id == 0 || id == null) {
      return;
    }

    final bool isObjAlive = isObjectAlive(id);
    if (!isObjAlive) {
      throw ObjectNotAliveException(id: id, json: jsonStr);
    }
  }

  Future<dynamic> addList({
    required final MapViewMarkerCollections object,
    required final List<MarkerWithRenderSettings> list,
    required final MarkerCollectionRenderSettings settings,
    required final String name,
    required final dynamic parentMapId,
    final MarkerType markerType = MarkerType.point,
  }) async {
    final Map<int, Pointer<Utf8>> markersImagePointers = <int, Pointer<Utf8>>{};
    Pointer<Uint8>? toSend;
    String? retVal;
    try {
      for (final MarkerWithRenderSettings marker in list) {
        if (marker.settings.image != null) {
          Pointer<Utf8> imagePointer;
          if (markersImagePointers.containsKey(
            marker.settings.image!.hashCode,
          )) {
            imagePointer =
                markersImagePointers[marker.settings.image!.hashCode]!;
          } else {
            imagePointer = jsonEncode(marker.settings.image).toNativeUtf8();
            markersImagePointers[marker.settings.image!.hashCode] =
                imagePointer;
          }
          MarkerInfoSpecialAccess.updateImagePointerSizeRenderSettings(
            marker.settings,
            imagePointer.length,
          );
          MarkerInfoSpecialAccess.updateImagePointerValueRenderSettings(
            marker.settings,
            imagePointer.address,
          );
        }
      }
      final Uint8List pList = serializeListOfMarkers(list);
      toSend = passBinaryDataToC(pList);
      if (Platform.isAndroid) {
        retVal = await GemKitPlatform.instance
            .getChannel()
            .invokeMethod<String>(
              'callObjectMethod',
              jsonEncode(<String, dynamic>{
                'id': object.pointerId,
                'class': 'MapViewMarkerCollections',
                'method': 'addList',
                'args': <String, dynamic>{
                  'settings': settings,
                  'collectionType': markerType.id,
                  'name': name,
                  'binarylist': toSend.address,
                  'binarylistSize': pList.length,
                  'parentMapId': parentMapId,
                },
              }),
            );
      } else {
        {
          retVal = callObjectMethod(<String, Object>{
            'id': object.pointerId,
            'class': 'MapViewMarkerCollections',
            'method': 'addList',
            'args': <String, dynamic>{
              'settings': settings,
              'collectionType': markerType.id,
              'name': name,
              'binarylist': toSend.address,
              'binarylistSize': pList.length,
              'parentMapId': parentMapId,
            },
          });
        }
      }
    } finally {
      for (final MapEntry<int, Pointer<Utf8>> imagePointer
          in markersImagePointers.entries) {
        malloc.free(imagePointer.value);
      }
      if (toSend != null) {
        malloc.free(toSend);
      }
    }
    return retVal!;
  }

  RenderableImg? callGetFlutterImg(
    final int objectId,
    final int width,
    final int height,
    final int imageType,
    String? arg,
    bool allowResize,
  ) {
    if (!initHasBeenDone) {
      throw GemKitUninitializedException();
    }

    arg ??= '';
    final Pointer<Utf8> pArg = arg.toNativeUtf8();

    final dynamic result = _callGetFlutterImg(
      objectId,
      width,
      height,
      imageType,
      pArg,
      pArg.length,
      allowResize,
    );

    if (result.ptr == nullptr) {
      malloc.free(pArg);
      return null;
    }

    final Pointer<Uint8> imgBuffer = _callGetBytes(result.ptr);
    final int imgBufferSize = _callGetSizeOfBytes(result.ptr);

    final Uint8List retVal = Uint8List.fromList(
      imgBuffer.asTypedList(imgBufferSize),
    );
    malloc.free(pArg);
    _callDeletePointer(result.ptr, ObjType.gemBuffer.id);

    final RenderableImg bitmap = RenderableImg(
      result.width,
      result.height,
      retVal,
    );
    return bitmap;
  }

  Uint8List? callGetCameraBuffer(int id) {
    if (!initHasBeenDone) {
      throw GemKitUninitializedException();
    }

    final dynamic result = _callGetCameraBuffer(id);
    if (result == nullptr) {
      return null;
    }

    final Pointer<Uint8> buffer = result.buffer.cast<Uint8>();
    final int length = result.size;

    final Uint8List dartBuffer = Uint8List.fromList(buffer.asTypedList(length));

    // DO NOT call _callDeletePointer on [buffer] here.
    // GetCameraBuffer returns a raw pointer that is a direct view into the ICamera object's internal data with no separate
    // heap allocation made. The ICamera is owned by a CameraContainer and is released automatically
    return dartBuffer;
  }

  Uint8List? callGetImage(
    final String className,
    final int objectId,
    final int width,
    final int height,
    final bool allowResize,
    final int imageType, {
    String? arg,
  }) {
    if (!initHasBeenDone) {
      throw GemKitUninitializedException();
    }
    arg ??= '';
    final Pointer<Utf8> clsName = className.toNativeUtf8();
    final Pointer<Utf8> pArg = arg.toNativeUtf8();
    final Pointer<Utf8> buffer = _callGetImageBuffer(
      objectId,
      clsName,
      width,
      height,
      allowResize,
      imageType,
      pArg,
      pArg.length,
      clsName.length,
    );
    if (buffer == nullptr) {
      malloc.free(clsName);
      malloc.free(pArg);
      return null;
    }
    final Pointer<Uint8> imgBuffer = _callGetBytes(buffer);
    final int imgBufferSize = _callGetSizeOfBytes(buffer);
    final Uint8List retVal = Uint8List.fromList(
      imgBuffer.asTypedList(imgBufferSize),
    );
    malloc.free(clsName);
    malloc.free(pArg);
    _callDeletePointer(buffer, ObjType.gemBuffer.id);
    return retVal;
  }

  String callObjectMethod(
    final Map<String, Object> json, {
    LogPrivacyLevel logPrivacyLevel = LogPrivacyLevel.printAllInfo,
  }) {
    if (!initHasBeenDone) {
      throw GemKitUninitializedException();
    }
    if (Debug.logCallObjectMethod) {
      switch (logPrivacyLevel) {
        case LogPrivacyLevel.printAllInfo:
          gemSdkLogger.finest('[SdkDebug][CallObject] Request: $json');

        case LogPrivacyLevel.hideArgumentValues:
          final Map<String, Object> jsonWithoutArgs = Map<String, Object>.from(
            json,
          );
          if (jsonWithoutArgs.containsKey('args')) {
            jsonWithoutArgs['args'] = '"SENSITIVE DATA HIDDEN"';
          }
          gemSdkLogger.finest(
            '[SdkDebug][CallObject] Request: $jsonWithoutArgs',
          );

        case LogPrivacyLevel.noLog:
          // Do not log anything
          break;
      }
    }
    if (Debug.isObjectAliveCheckEnabled) {
      assertObjectAlive(json);
    }
    final String encodedJson = jsonEncode(json);
    final Pointer<Utf8> dataNative = encodedJson.toNativeUtf8();
    final Pointer<Char> result = gemWebRTCNative!.native_call(
      dataNative.cast<Char>(),
      dataNative.length,
    );
    malloc.free(dataNative);
    if (result == nullptr) {
      throw Exception('Failed to call object method: $json');
    }

    final String response = result.cast<Utf8>().toDartString();
    if (Debug.logCallObjectMethod) {
      switch (logPrivacyLevel) {
        case LogPrivacyLevel.printAllInfo:
          gemSdkLogger.finest('[SdkDebug][CallObject] Result: $response');

        case LogPrivacyLevel.hideArgumentValues:
          dynamic decodedResponse;
          try {
            decodedResponse = jsonDecode(response);
            if (decodedResponse is Map<String, Object> &&
                decodedResponse.containsKey('result')) {
              decodedResponse['result'] = 'SENSITIVE DATA HIDDEN';
            }
          } catch (_) {
            decodedResponse = 'Failed to decode response';
          }
          gemSdkLogger.finest(
            '[SdkDebug][CallObject] Result: $decodedResponse',
          );

        case LogPrivacyLevel.noLog:
          // Do not log anything
          break;
      }
    }

    malloc.free(result);
    return response;
  }

  String callCreateObject(final String json) {
    if (cookie == null || !initHasBeenDone) {
      throw GemKitUninitializedException();
    }
    if (Debug.logCreateObject) {
      gemSdkLogger.finest('[SdkDebug][CreateObject] Request: $json');
    }

    final Pointer<Utf8> dataNative = json.toNativeUtf8();
    final Pointer<Char> result = gemWebRTCNative!.native_call_createObject(
      dataNative.cast<Char>(),
      dataNative.length,
    );
    malloc.free(dataNative);
    if (result == nullptr) {
      throw Exception('Failed to create object: $json');
    }

    final String response = result.cast<Utf8>().toDartString();
    if (Debug.logCreateObject) {
      gemSdkLogger.finest('[SdkDebug][CreateObject] Result: $response');
    }

    malloc.free(result);
    return response;
  }

  void callDeleteObject(final String json) {
    final Pointer<Char> dataNative = json.toNativeUtf8().cast<Char>();
    gemWebRTCNative!.native_deleteObject(dataNative, json.length);
    malloc.free(dataNative);
  }

  bool isObjectAlive(final dynamic objectId) {
    return _callIsObjectAlive(objectId);
  }

  int get aliveObjectsCount {
    if (cookie == null || !initHasBeenDone) {
      return 0;
    }
    return _callGetAliveObjectsCount();
  }

  GemObject registerWeakRelease(
    final Object obj,
    final dynamic nativePointerId,
    final int timestamp,
  ) {
    if (cookie == null) {
      throw GemKitUninitializedException();
    }
    handleDartObject(obj, nativePointerId, timestamp);
    final GemObjectImpl retVal = GemObjectImpl();
    //retVal.initBase(nativePointerId);
    return retVal;
  }

  /// Creates a native gem::Image and returns its raw pointer.
  ///
  /// The returned pointer is NOT tracked by the native object pool.
  /// Callers MUST delete it via [deleteCPointer]  in a `finally` block to guarantee cleanup.  Do not store this
  /// pointer in a field or pass it across async boundaries.
  dynamic createGemImage(final Uint8List buffer, final int imgType) {
    final Pointer<Uint8> bufferPtr = malloc.allocate<Uint8>(buffer.length);
    bufferPtr.asTypedList(buffer.length).setAll(0, buffer);
    final dynamic result = _callCreateGemImage(
      bufferPtr,
      buffer.length,
      imgType,
    );
    malloc.free(bufferPtr);
    return result;
  }

  void deleteCPointer(final dynamic address, final ObjType objType) {
    final Pointer<Utf8> pointer = Pointer<Utf8>.fromAddress(address);
    _callDeletePointer(pointer, objType.id);
  }

  void release() {
    //_callReleaseNative();
    initHasBeenDone = false;
    loadNativeCalled = false;
    gemSdkLogger.fine('GEM SDK released');

    // Tear down our native -> Dart channel. Cancelling the subscription
    // before closing the port avoids a final "port closed" message being
    // dispatched into our handler.
    _nativePortSubscription?.cancel();
    _nativePortSubscription = null;
    _nativePort?.close();
    _nativePort = null;

    // Detach only OUR log subscription. Calling Logger.root.clearListeners()
    // here would also remove listeners that the host application installed,
    // which is not ours to touch.
    _logSubscription?.cancel();
    _logSubscription = null;
  }

  void setLibLoaded() {}

  dynamic toNativePointer(final Uint8List data) {
    return passBinaryDataToC(data);
  }

  void freeNativePointer(final dynamic pointer) {
    malloc.free(pointer);
  }

  void setMouseInFocus(final bool mouseInFocus, final int viewId) {
    //Not needed for Android/IOS
  }

  //Not needed for Android/IOS
  Future<bool> askForLocationPermission() async {
    throw UnimplementedError('Not implemented for Android/IOS');
  }

  bool get is32BitSystem {
    if (sizeOf<IntPtr>() == 4) {
      return true;
    }
    return false;
  }

  bool get isSdkInitialized {
    return _callIsSdkInitialized();
  }
}
