/*
 * SPDX-FileCopyrightText: 2023-2026 Magic Lane International B.V. <info@magiclane.com>
 * SPDX-License-Identifier: LicenseRef-MagicLane-Proprietary
 *
 * For the latest licensing terms and conditions, see https://www.magiclane.com/web/terms-and-conditions#terms-of-service.
 * For further information use the contact form at https://www.magiclane.com/web/contact.
 */

package com.magiclane.magiclane_maps_flutter

import android.content.Context
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.StandardMessageCodec
import io.flutter.plugin.platform.PlatformView
import io.flutter.plugin.platform.PlatformViewFactory
import android.app.Activity

@Suppress("UNCHECKED_CAST")
class GemMapViewFactory(
    private val gemKitPlugin: MagiclaneMapsFlutterPlugin,
    private val flutterAssets: FlutterPlugin.FlutterAssets,
) : PlatformViewFactory(StandardMessageCodec.INSTANCE) {

    override fun create(context: Context, viewId: Int, args: Any?): PlatformView {
        return GemMapView(gemKitPlugin, viewId, context, args, flutterAssets)
    }
}
