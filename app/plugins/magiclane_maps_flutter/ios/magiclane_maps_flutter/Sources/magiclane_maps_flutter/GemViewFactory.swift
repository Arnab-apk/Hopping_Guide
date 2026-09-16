// SPDX-FileCopyrightText: 2023-2026 Magic Lane International B.V. <info@magiclane.com>
// SPDX-License-Identifier: LicenseRef-MagicLane-Proprietary
//
// For the latest licensing terms and conditions, see https://www.magiclane.com/web/terms-and-conditions#terms-of-service.
// For further information use the contact form at https://www.magiclane.com/web/contact.

import Foundation
import Flutter
import GEMKit

public class GemViewFactory: NSObject, FlutterPlatformViewFactory {

    var registrar: FlutterPluginRegistrar?
    var methodChannel: FlutterMethodChannel?
    var sdkChannel: FlutterChannelObject?
    var isSdkInitialized: Bool = false
    var releaseInProgress: Bool = false
    public init(withRegistrar registrar: FlutterPluginRegistrar) {

        super.init()

        self.registrar = registrar
        let channelName = "plugins.flutter.dev/gem_engine"
        methodChannel = FlutterMethodChannel(name: channelName, binaryMessenger: registrar.messenger())
        methodChannel?.setMethodCallHandler({ [weak self] (call, result) in
            guard let strongSelf = self else { return }
            strongSelf.methodCallHandler(call: call, result: result)
        })
        // self.prepareSDK()
    }
      func methodCallHandler(call: FlutterMethodCall, result: @escaping FlutterResult) {
    if(call.method == "networkProviderCall" )
    {
        handleNetworkProviderCall(call: call, result: result)
        return
    }
    if(call.method == "releaseEngine")
    {
        if( self.isSdkInitialized)
        {
            releaseInProgress = true
            GEMSdk.shared().cleanDestroy()
            releaseInProgress = false
            self.isSdkInitialized = false
        }
        result(true)
        return
    }
    if(call.method == "initializeGemSdk")
    {
        if(self.isSdkInitialized == false)
        {
            var aVar = 0
            if let args = call.arguments as? [String: Any] {
                aVar = args["aVar"] as? Int ?? 0
            } else if let jsonString = call.arguments as? String,
                      let jsonData = jsonString.data(using: .utf8),
                      let json = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any] {
                aVar = json["aVar"] as? Int ?? 0
            }
            NSLog("initializeGemSdk called with aVar: %d", aVar)
            self.prepareSDK(appVariant: aVar)
        }
        result(true)
        return
    }
    if call.method == "setLogLevel" {
        guard let jsonString = call.arguments as? String,
            let data = jsonString.data(using: .utf8) else {
            result(FlutterError(code: "INVALID_ARGUMENT", message: "Expected JSON string", details: nil))
            return
        }

        do {
            if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
            let level = json["level"] as? Int {
                if level == 6 {
                    GEMSdk.shared().deactivateDebugLogger()
                } else {
                    GEMSdk.shared().activateDebugLogger()
                }
                result(true)
            } else {
                result(FlutterError(code: "INVALID_JSON", message: "Missing or invalid 'level' field", details: nil))
            }
        } catch {
            result(FlutterError(code: "JSON_ERROR", message: "Failed to parse JSON: \(error.localizedDescription)", details: nil))
        }
        return
    }
    if call.method == "getLogPath" {
        if let docsDir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
            let logDirPath = docsDir.appendingPathComponent("GEMKit.log").path
            result(logDirPath)
        } else {
            result("")
        }
        return
    }

    guard let sdkChannel = sdkChannel else {
        result(FlutterError(code: "SDK_CHANNEL_NULL", message: "SDK Channel is not initialized", details: nil))
        return
    }

    guard let string = call.arguments as? String, let data = string.data(using: .utf8) else {
        result(FlutterError(code: "INVALID_ARGUMENTS", message: "Arguments are invalid or nil", details: nil))
        return
    }

    NSLog("GemMapController: methodCallHandler, call.arguments: %@", string)

    sdkChannel.parseMethod(call.method, args: data) { [weak self] eventName, eventData, finalEvent in
        guard let self = self else { return }

        guard let methodChannel = self.methodChannel else {
            NSLog("GemViewFactory: methodChannel is nil")
            return
        }

        let arguments = String(data: eventData, encoding: .utf8)
        methodChannel.invokeMethod(eventName, arguments: arguments)

    } completionHandler: { [weak self] code, completionData, waitFutureEvents in
        guard let self = self else { return }

        let arguments = String(data: completionData, encoding: .utf8)

        if code == .kNoError {
            result(arguments)
        } else {
            let error = FlutterError(code: String(format: "%d", code.rawValue), message: arguments, details: nil)
            result(error)
        }
    }
}
    // MARK: - GEMSdk

    func prepareSDK(appVariant: Int = 0) {
        let deviceLanguage = Locale.preferredLanguages.first ?? "en"

        let token = ""

        let success = GEMSdk.shared().initCoreSdk(token, language: deviceLanguage, appVariant: Int32(appVariant)) { err in

            print("SDK initialization completed with result: \(err)")
        }

        if success.rawValue == 0 {
            self.isSdkInitialized = true
            GEMSdk.shared().activateDebugLogger()
            GEMSdk.shared().appDidBecomeActive()
            GEMSdk.shared().setAllowConnection(true)
        }
        self.sdkChannel = FlutterChannelObject.init()
          NotificationCenter.default.addObserver(self, selector: #selector(handleApplicationDidEnterBackground), name: UIApplication.didEnterBackgroundNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(handleApplicationWillEnterForeground), name: UIApplication.willEnterForegroundNotification, object: nil)
    }

    public func createArgsCodec() -> FlutterMessageCodec & NSObjectProtocol {
          return FlutterStandardMessageCodec.sharedInstance()
    }

    // MARK: - FlutterPlatformViewFactory

    public func create(withFrame frame: CGRect, viewIdentifier viewId: Int64, arguments args: Any?) -> FlutterPlatformView {
        if(self.isSdkInitialized == false) {
            self.prepareSDK()
            }
        let gemMapController = GemMapController.init(withFrame: frame, viewIdentifier: viewId, arguments: args, registrar: self.registrar)

        return gemMapController
    }
 @objc func handleApplicationDidEnterBackground() {
        // Handle application entering background state
        // Send an event to Flutter using EventChannel or MethodChannel
        GEMSdk.shared().appDidEnterBackground()
    }
    @objc func handleApplicationWillEnterForeground() {
           // Handle application entering foreground state
           // Send an event to Flutter using EventChannel or MethodChannel
        GEMSdk.shared().appDidBecomeActive()
       }
    // Add a Swift equivalent for the Kotlin `handleNetworkProviderCall` function
    func handleNetworkProviderCall(call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let arguments = call.arguments as? String, let data = arguments.data(using: .utf8) else {
            result(FlutterError(code: "INVALID_ARGUMENTS", message: "Arguments are invalid or nil", details: nil))
            return
        }

        do {
            if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
               let action = json["action"] as? String {
                switch action {
                case "isConnected":
                    result(GEMSdk.shared().isOnlineConnection())
                case "isWifiConnected":
                    result(GEMSdk.shared().isWiFiConnected())
                case "isMobileDataConnected":
                    result(GEMSdk.shared().isMobileDataConnected())
                case "refreshNetwork":
                    GEMSdk.shared().refreshNetwork()
                    result(nil)
                default:
                    result(FlutterError(code: "INVALID_ACTION", message: "Action \(action) is not supported", details: nil))
                }
            } else {
                result(FlutterError(code: "INVALID_JSON", message: "Failed to parse JSON", details: nil))
            }
        } catch {
            result(FlutterError(code: "JSON_ERROR", message: "Failed to parse JSON: \(error.localizedDescription)", details: nil))
        }
    }
}

