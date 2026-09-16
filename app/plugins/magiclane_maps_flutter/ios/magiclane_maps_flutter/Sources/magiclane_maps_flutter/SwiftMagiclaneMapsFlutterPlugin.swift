// SPDX-FileCopyrightText: 2023-2026 Magic Lane International B.V. <info@magiclane.com>
// SPDX-License-Identifier: LicenseRef-MagicLane-Proprietary
//
// For the latest licensing terms and conditions, see https://www.magiclane.com/web/terms-and-conditions#terms-of-service.
// For further information use the contact form at https://www.magiclane.com/web/contact.

import Flutter
import UIKit

public class SwiftMagiclaneMapsFlutterPlugin: NSObject, FlutterPlugin {

    public static func register(with registrar: FlutterPluginRegistrar) {

        let factory = GemViewFactory.init(withRegistrar: registrar)

        registrar.register(factory, withId:"plugins.flutter.dev/gem_maps")
    }
}
