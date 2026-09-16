// SPDX-FileCopyrightText: 2023-2026 Magic Lane International B.V. <info@magiclane.com>
// SPDX-License-Identifier: LicenseRef-MagicLane-Proprietary
//
// For the latest licensing terms and conditions, see https://www.magiclane.com/web/terms-and-conditions#terms-of-service.
// For further information use the contact form at https://www.magiclane.com/web/contact.

import UIKit
import Foundation
import Flutter
import GEMKit

public class GemMapController: NSObject, FlutterPlatformView {

    var viewId: Int64 = 0

    var methodChannel: FlutterMethodChannel?

    var sdkChannel: FlutterChannelObject?

    var mapViewController: MapViewController?

    // var liveDataSourceController: LiveDataSourceController?

    public init(withFrame frame: CGRect, viewIdentifier viewId: Int64, arguments args: Any?, registrar: FlutterPluginRegistrar?) {

        super.init()
        self.mapViewController = MapViewController.init()
        self.mapViewController!.view.frame = frame
        self.mapViewController!.hideCompass()
        self.mapViewController!.hideMapLogo()
        self.mapViewController!.startRender()
        self.initMapStyle(arguments: args, registrar: registrar)



        self.registerCallsFromFlutter(viewId: viewId, registrar: registrar)
    }


    deinit {
        self.methodChannel?.setMethodCallHandler(nil)

        self.clearMapView()

        if let mapViewController = self.mapViewController {

            mapViewController.destroy()
        }

        self.mapViewController = nil
        
        self.methodChannel = nil
    }

    // MARK: - FlutterPlatformView

    public func view() -> UIView {

        guard let mapViewController = self.mapViewController else { return UIView.init() }

        return mapViewController.view
    }

    // MARK: - Channel

    func registerCallsFromFlutter(viewId: Int64, registrar: FlutterPluginRegistrar?) {

        guard self.methodChannel == nil else { return }

        guard let registrar = registrar else { return }

        self.viewId = viewId

        let channelName = String("plugins.flutter.dev/gem_maps_\(viewId)")

        self.methodChannel = FlutterMethodChannel.init(name: channelName, binaryMessenger: registrar.messenger())

        self.methodChannel!.setMethodCallHandler({ [weak self] (call, result) in

            guard let strongSelf = self else { return }

            strongSelf.methodCallHandler(call: call, result: result)
        })

        self.sdkChannel = FlutterChannelObject.init()


        NSLog("GemMapController: channelName:%@, viewId:%d", channelName, viewId)
    }



    func methodCallHandler(call: FlutterMethodCall, result: @escaping FlutterResult) {

        guard let methodChannel = self.methodChannel else { return }

        guard let sdkChannel = self.sdkChannel else { return }

        if call.method == "waitForViewId" { // GemKitPlatform.init calls: channel.invokeMethod<void>('waitForViewId');

            self.registerMapView(result: result)

        } else if call.method == "handleTouchEvent" {
            guard let args = call.arguments as? [String: Any] else {
                result(FlutterError(code: "INVALID_ARGUMENTS", message: "Expected touch event arguments map", details: nil))
                return
            }

            let touchArgs: [String: Any] = [
                "x": args["x"] as? Int ?? 0,
                "y": args["y"] as? Int ?? 0,
                "touchType": args["touchType"] as? Int ?? 0,
                "pointerIndex": args["pointerIndex"] as? Int ?? 0
            ]

            let payload: [String: Any] = [
                "id": args["id"] as? Int ?? -1,
                "class": "MapView",
                "method": "handleTouchEvent",
                "args": touchArgs
            ]

            guard let data = self.convertToData(json: payload) else {
                result(FlutterError(code: "INVALID_ARGUMENTS", message: "Failed to encode touch event payload", details: nil))
                return
            }

            sdkChannel.parseMethod("callObjectMethod", args: data) { [weak self] eventName, eventData, finalEvent in

                guard let _ = self else { return }

                let arguments = String(data: eventData, encoding: .utf8)

                methodChannel.invokeMethod(eventName, arguments: arguments)

            } completionHandler: { [weak self] code, completionData, waitFutureEvents in

                guard let _ = self else { return }

                let arguments = String(data: completionData, encoding: .utf8)

                if code == .kNoError {

                    result(arguments)

                } else {

                    let error = FlutterError.init(code: String(format: "%d", code.rawValue), message: arguments, details: nil)

                    result(error)
                }
            }
        } else {

            if let string = call.arguments as? String, let data = string.data(using: .utf8) {

                NSLog("GemMapController: methodCallHandler, call.arguments:%@", string)

                sdkChannel.parseMethod(call.method, args: data) { [weak self] eventName, eventData, finalEvent in

                    guard let _ = self else { return }

                    let arguments = String(data: eventData, encoding: .utf8)

                    methodChannel.invokeMethod(eventName, arguments: arguments)

                } completionHandler: { [weak self] code, completionData, waitFutureEvents in

                    guard let _ = self else { return }

                    let arguments = String(data: completionData, encoding: .utf8)

                    if code == .kNoError {

                        result(arguments)

                    } else {

                        let error = FlutterError.init(code: String(format: "%d", code.rawValue), message: arguments, details: nil)

                        result(error)
                    }
                }
            }
        }
    }

    // MARK: - SDK Channel

    func registerMapView(result: @escaping FlutterResult) {

        guard let methodChannel = self.methodChannel else { return }

        guard let sdkChannel = self.sdkChannel else { return }

        guard let mapViewController = self.mapViewController else { return }

        sdkChannel.registerMapView(mapViewController, args: Data.init()) { [weak self] eventName, eventData, finalEvent in

            guard let _ = self else { return }

            let arguments = String(data: eventData, encoding: .utf8)

            methodChannel.invokeMethod(eventName, arguments: arguments)

        } completionHandler: { [weak self] code, data, waitFutureEvents in

            guard let _ = self else { return }

            let arguments = String(data: data, encoding: .utf8)

            if code == .kNoError {

                result(arguments)

            } else {

                let error = FlutterError.init(code: String(format: "%d", code.rawValue), message: arguments, details: nil)

                result(error)
            }
        }
    }

    func clearMapView() {

        guard let sdkChannel = self.sdkChannel else { return }

        if let mapViewController = self.mapViewController {

            sdkChannel.clearMapView(mapViewController) { [viewId = self.viewId] code in

                // Surface any failure here — silently dropping the code makes
                // resource leaks (e.g. native view already released) invisible
                // and effectively undebuggable.
                if code != .kNoError {

                    NSLog("GemMapController: clearMapView failed for viewId:%d, code:%d", viewId, code.rawValue)
                }
            }
        }
        self.sdkChannel = nil
    }

    // MARK: - Utils

    func convertToDictionary(data: Data) -> [String : Any]? {

        do {

            let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String : AnyObject]

            return json

        } catch {

            print(error.localizedDescription)
        }

        return nil
    }

    func convertToData(json: Any?) -> Data? {

        if let object = json {

            do {

                let data = try JSONSerialization.data(withJSONObject: object, options: [])

                return data

            } catch {

                print(error.localizedDescription)
            }
        }

        return nil
    }

    private func initMapStyle(arguments args: Any?, registrar : FlutterPluginRegistrar?) {

        guard let args = args as? [String: Any] else {return}

        if let rawId = args["mapStyleId"] {
            if let styleId = (rawId as? NSNumber)?.intValue, styleId != 0 {
                self.mapViewController?.applyStyle(withStyleIdentifier: styleId, smoothTransition: false)
                return
            }
        }

        guard let registrar = registrar else {return}

        let assetKey = args["mapStyleAssetPath"] as? String
        guard let assetKey = assetKey else { return }

        let assetPath = registrar.lookupKey(forAsset: assetKey)
        let filePathWithoutExtension = (assetPath as NSString).deletingPathExtension

        if let path = Bundle.main.url(forResource: filePathWithoutExtension, withExtension: "style") {

            if let data = NSData.init(contentsOf: path) as Data? {
                self.mapViewController?.applyStyle(withStyleBuffer: data, smoothTransition: false)
            }
        }
    }
}
