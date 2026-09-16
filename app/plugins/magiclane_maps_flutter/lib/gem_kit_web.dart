// SPDX-FileCopyrightText: 2023-2026 Magic Lane International B.V. <info@magiclane.com>
// SPDX-License-Identifier: LicenseRef-MagicLane-Proprietary
//
// For the latest licensing terms and conditions, see https://www.magiclane.com/web/terms-and-conditions#terms-of-service.
// For further information use the contact form at https://www.magiclane.com/web/contact.

/// @nodoc
library;

import 'dart:async';
import 'dart:convert';
// ignore: deprecated_member_use
import 'dart:html' as html;
// ignore: deprecated_member_use
import 'dart:js';
import 'dart:ui_web' show platformViewRegistry;

import 'package:flutter/services.dart';
import 'package:flutter_web_plugins/flutter_web_plugins.dart';
import 'package:logging/logging.dart';
// ignore_for_file: avoid_print

import 'package:magiclane_maps_flutter/src/gem_kit_platform_interface.dart';
import 'package:magiclane_maps_flutter/src/loggers/app_logger.dart';

// Base URL of the hosted web SDK payload (gemkitloader.js, FlutterPluginWASM.js,
// FlutterPluginWASM.wasm). Must match `sourceWebsite` in gemkitloader.js and end
// with a trailing slash. Bump the version segment on each plugin release.
// To load gemkitloader.js from bundled Flutter assets instead, set this to
// 'assets/packages/magiclane_maps_flutter/assets/'.
const String sdkWebBase =
    'https://developer.magiclane.com/packages/web/flutter/3.1.9/';

final Completer<void> _completer = Completer<void>();
final Map<int, MethodChannel> _channels = <int, MethodChannel>{};
final Map<int, Completer<void>> _completersCanvasInit =
    <int, Completer<void>>{};
Future<void> createScreen(final String canvasId) async {
  await _completer.future;
  final JsObject pWebRTCModule = context['Module'];
  final dynamic canvasNameNative = pWebRTCModule.callMethod(
    'allocateUTF8',
    <String>[canvasId],
  );
  pWebRTCModule.callMethod('_createScreen', <dynamic>[canvasNameNative]);
  pWebRTCModule.callMethod('_gemFree', <dynamic>[canvasNameNative]);
}

/// Routes a pointer/touch event to the dedicated WASM export
/// (Module._handleTouchEvent) for the given view's canvas.
///
/// [rawArgs] is the method-channel argument from GemView.handleTouchEvent — a
/// map (or its JSON string) with keys x, y, touchType, pointerIndex.
void _handleTouchEventWeb(final int viewId, final dynamic rawArgs) {
  final Map<dynamic, dynamic> a = rawArgs is String
      ? jsonDecode(rawArgs) as Map<dynamic, dynamic>
      : rawArgs as Map<dynamic, dynamic>;
  final JsObject module = context['Module'];
  final dynamic canvasNative = module.callMethod('allocateUTF8', <String>[
    'canvas$viewId',
  ]);
  // Export signature: handleTouchEvent(canvasId, eventType, pointerIndex, x, y)
  module.callMethod('_handleTouchEvent', <dynamic>[
    canvasNative,
    a['touchType'],
    a['pointerIndex'],
    a['x'],
    a['y'],
  ]);
  module.callMethod('_gemFree', <dynamic>[canvasNative]);
}

html.DivElement createCanvas(final int viewId) {
  final html.DivElement wrapper = html.DivElement()
    ..style.width = '100%'
    ..style.height = '100%'
    ..style.position = 'absolute'
    ..tabIndex = 0
    ..id = 'canvasWrapper$viewId'
    ..onContextMenu.listen(
      (final html.MouseEvent event) => event.preventDefault(),
    );

  final String canvasName = 'canvas$viewId';

  final html.CanvasElement canvas = html.CanvasElement()
    ..style.width = '100%'
    ..style.height = '100%'
    ..className = 'emscripten'
    ..tabIndex = 0
    ..id = canvasName;

  wrapper.children.add(canvas);
  _completersCanvasInit[viewId] = Completer<void>();
  // Ensure WebGL is ready before calling createScreen
  Future<dynamic>.delayed(Duration.zero, () async {
    final html.Element? element = html.document.getElementById(canvasName);
    if (element != null) {
      await createScreen(canvasName);
      _completersCanvasInit[viewId]?.complete();
    } else {
      gemSdkLogger.log(Level.FINE, 'Canvas not found in DOM, retrying...');
      Future<dynamic>.delayed(const Duration(milliseconds: 10), () async {
        await createScreen(canvasName);
        _completersCanvasInit[viewId]?.complete();
      });
    }
  });

  // Create communication channel
  GemKitWeb.createChannelWithId(viewId);

  return wrapper;
}

void loadWasmModule() {
  //document.body = BodyElement();
  if (html.document.head == null) {
    html.document.body?.insertAdjacentElement(
      'beforebegin',
      html.HeadElement(),
    );
  }
  final html.StyleElement style = html.StyleElement();
  style.innerHtml = '''
  .emscripten {
    position: relative;
    top: 0px;
    left: 0px;
    margin: 0px;
    border: 0;
    width: 100%;
    height: 100%;
    overflow: hidden;
    display: block;
    image-rendering: optimizeSpeed;
    image-rendering: -moz-crisp-edges;
    image-rendering: -o-crisp-edges;
    image-rendering: -webkit-optimize-contrast;
    image-rendering: optimize-contrast;
    image-rendering: crisp-edges;
    image-rendering: pixelated;
    -ms-interpolation-mode: nearest-neighbor;
  }
''';
  html.document.head?.append(style);
  final html.ScriptElement script = html.ScriptElement();
  script.src = '${sdkWebBase}gemkitloader.js';
  script.type = 'text/javascript';
  script.onLoad.listen((final _) {
    context.callMethod('initApp', <dynamic>[]);
  });
  html.document.body?.children.add(script);
  //html.document.body?.children.add(wrapper);
  platformViewRegistry.registerViewFactory(
    'canvasView',
    (final int viewId) => createCanvas(viewId),
  );
}

void finishedLoadWasm() {
  GemMethodListener.initCallbackFunctions();
  GemKitWeb.initCallbackFunctions();
  GemKitPlatform.instance.setLibLoaded();

  // var pWebRTCModule = context["Module"];
  // String appToken = "YourAPPToken";
  // final appTokenNative = pWebRTCModule.callMethod("allocateUTF8", [appToken]);
  // pWebRTCModule.callMethod("_setAppAuthorization", [appTokenNative]);
  // pWebRTCModule.callMethod("_free", [appTokenNative]);
  try {
    _completer.complete();
  } catch (e) {
    gemSdkLogger.log(Level.SEVERE, e.toString());
  }
}

typedef CallbackMethodListener = void Function(String);

class GemMethodListener {
  GemMethodListener(final CallbackMethodListener pCallbackMethod) {
    _pCallbackMethod = pCallbackMethod;
    final JsObject pWebRTCModule = context['Module'];
    _pVoidPointer = pWebRTCModule.callMethod('_CreateMethodListener', <dynamic>[
      pointerFunc,
    ]);
  }
  static void initCallbackFunctions() {
    final JsObject pWebRTCModule = context['Module'];
    pointerFunc = pWebRTCModule.callMethod('addFunction', <Object>[
      callbackHandler,
      'viii',
    ]);
  }

  static GemMethodListener produce(
    final CallbackMethodListener pCallbackMethod,
  ) {
    final GemMethodListener gemMethodListener = GemMethodListener(
      pCallbackMethod,
    );
    instanceList[gemMethodListener.nativePointer] = gemMethodListener;
    return gemMethodListener;
  }

  static void callbackHandler(
    final int pVoidPointer,
    final int messageType,
    final int messageChar,
  ) {
    final dynamic pGemMethodListener = instanceList[pVoidPointer];
    if (messageType == 0) {
      final JsObject pWebRTCModule = context['Module'];
      final String pCharConverted = pWebRTCModule.callMethod(
        'UTF8ToString',
        <int>[messageChar],
      );
      pGemMethodListener._pCallbackMethod(pCharConverted);
    } else if (messageType == 1) {
      final JsObject pWebRTCModule = context['Module'];
      pWebRTCModule.callMethod('_DeleteMethodListener', <int>[pVoidPointer]);
      instanceList.remove(pVoidPointer);
    }
  }

  int get nativePointer {
    return _pVoidPointer;
  }

  static Map<dynamic, dynamic> instanceList = <dynamic, dynamic>{};
  int _pVoidPointer = 0;
  static dynamic pointerFunc;
  late CallbackMethodListener _pCallbackMethod;
}

void handleMessage(
  final String methodName,
  final String arguments,
  final String canvasId,
  final CallbackMethodListener pFuncCallback,
) {
  final GemMethodListener gemMethodListener = GemMethodListener.produce(
    pFuncCallback,
  );
  final JsObject pWebRTCModule = context['Module'];
  final dynamic methodNameNative = pWebRTCModule.callMethod(
    'allocateUTF8',
    <String>[methodName],
  );
  final dynamic argumentsNative = pWebRTCModule.callMethod(
    'allocateUTF8',
    <String>[arguments],
  );
  final dynamic canvasIdNative = pWebRTCModule.callMethod(
    'allocateUTF8',
    <String>[canvasId],
  );
  try {
    pWebRTCModule.callMethod('_HandleMessage', <dynamic>[
      methodNameNative,
      gemMethodListener.nativePointer,
      argumentsNative,
      canvasIdNative,
    ]);
  } catch (e) {
    gemSdkLogger.log(Level.SEVERE, e.toString());
  }
  pWebRTCModule.callMethod('_gemFree', <dynamic>[methodNameNative]);
  pWebRTCModule.callMethod('_gemFree', <dynamic>[argumentsNative]);
  pWebRTCModule.callMethod('_gemFree', <dynamic>[canvasIdNative]);
}

/// A web implementation of the GemKitPlatform of the GemKit plugin.
///
/// {@category Core}
class GemKitWeb extends GemKitPlatform {
  /// Constructs a GemKitWeb
  GemKitWeb() {
    context['finishedLoadWasm'] = JsFunction.withThis((final _) {
      finishedLoadWasm();
    });
  }
  static void initCallbackFunctions() {
    final JsObject pWebRTCModule = context['Module'];
    pointerFunc = pWebRTCModule.callMethod('addFunction', <Object>[
      invokeMethod,
      'vii',
    ]);
    pWebRTCModule.callMethod('_registerChannelMethod', <dynamic>[pointerFunc]);
  }

  static void invokeMethod(
    final int methodNativeString,
    final int argumentsString,
  ) {
    final JsObject pWebRTCModule = context['Module'];
    final String methodName = pWebRTCModule.callMethod('UTF8ToString', <int>[
      methodNativeString,
    ]);
    final String arguments = pWebRTCModule.callMethod('UTF8ToString', <int>[
      argumentsString,
    ]);
    _channels[0]!.invokeMethod(methodName, arguments);
  }

  static void createChannelWithId(final int id) {
    _channels[id] = MethodChannel(
      'plugins.flutter.dev/gem_maps_$id',
      const StandardMethodCodec(),
      binaryMessenger,
    );
    _channels[id]!.setMethodCallHandler((final MethodCall call) async {
      await _completer.future;
      await _completersCanvasInit[id]?.future;
      switch (call.method) {
        case 'initializeGemSdk':
          {
            return Future<bool>.value(true);
          }
        case 'handleTouchEvent':
          {
            // Pointer/touch events go straight to the dedicated WASM export
            // (Module._handleTouchEvent), not the generic channel: on web the
            // channel's parseMethod does not support this method and returns
            // notSupported (-4). The export takes the canvas id + event fields.
            _handleTouchEventWeb(id, call.arguments);
            return null;
          }
        default:
          {
            final Completer<void> pCompleter = Completer<void>();
            String returnMessage = '{}';
            // Channel args arrive as a String (JSON) from most callers, but
            // some pass a Map. The web bridge forwards a JSON string to the
            // native _HandleMessage, so encode non-Strings.
            final dynamic rawArgs = call.arguments;
            final String arg = rawArgs is String
                ? rawArgs
                : (rawArgs == null ? '' : jsonEncode(rawArgs));
            final String canvasId = 'canvas$id';
            handleMessage(call.method, arg, canvasId, (final String retVal) {
              returnMessage = retVal;
              pCompleter.complete();
            });
            await pCompleter.future;
            return Future<String>.value(returnMessage);
          }
      }
    });
  }

  static dynamic pointerFunc;
  static void registerWith(final Registrar registrar) {
    loadWasmModule();
    binaryMessenger = registrar;
    GemKitPlatform.instance = GemKitWeb();
    // Create engine channel at initialization
    _createEngineChannel();
  }

  static void _createEngineChannel() {
    const int engineId = 0;
    _channels[engineId] = MethodChannel(
      'plugins.flutter.dev/gem_engine',
      const StandardMethodCodec(),
      binaryMessenger,
    );
    _channels[engineId]!.setMethodCallHandler((final MethodCall call) async {
      await _completer.future;
      // Engine channel doesn't wait for canvas initialization
      switch (call.method) {
        case 'initializeGemSdk':
          {
            return Future<bool>.value(true);
          }
        default:
          {
            final Completer<void> pCompleter = Completer<void>();
            String returnMessage = '{}';
            // Channel args arrive as a String (JSON) from most callers, but
            // some (e.g. handleTouchEvent) pass a Map. The web bridge forwards
            // a JSON string to the native _HandleMessage, so encode non-Strings.
            final dynamic rawArgs = call.arguments;
            final String arg = rawArgs is String
                ? rawArgs
                : (rawArgs == null ? '' : jsonEncode(rawArgs));
            const String canvasId = 'canvas$engineId';
            handleMessage(call.method, arg, canvasId, (final String retVal) {
              returnMessage = retVal;
              pCompleter.complete();
            });
            await pCompleter.future;
            return Future<String>.value(returnMessage);
          }
      }
    });
  }

  static BinaryMessenger? binaryMessenger;

  /// Returns a [String] containing the version of the platform.
  Future<String?> get platformVersion async {
    final String version = html.window.navigator.userAgent;
    return version;
  }
}
