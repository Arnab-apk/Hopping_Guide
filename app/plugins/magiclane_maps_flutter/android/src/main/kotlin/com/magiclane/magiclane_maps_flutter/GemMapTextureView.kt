/*
 * SPDX-FileCopyrightText: 2025-2026 Magic Lane International B.V. <info@magiclane.com>
 * SPDX-License-Identifier: LicenseRef-MagicLane-Proprietary
 *
 * For the latest licensing terms and conditions, see https://www.magiclane.com/web/terms-and-conditions#terms-of-service.
 * For further information use the contact form at https://www.magiclane.com/web/contact.
 */

package com.magiclane.magiclane_maps_flutter

import android.graphics.SurfaceTexture
import io.flutter.plugin.common.MethodChannel
import org.json.JSONArray
import org.json.JSONObject
import com.magiclane.sdk.util.SdkCall
import com.magiclane.sdk.core.GemSdk
import com.magiclane.sdk.core.GemTextureWorker
import com.magiclane.sdk.core.GemOpenGLRenderer
import com.magiclane.sdk.flutter.FlutterChannel
import com.magiclane.sdk.flutter.FlutterMethodListener
import com.magiclane.sdk.core.GemError
import com.magiclane.sdk.core.DataBuffer
import com.magiclane.sdk.util.Util
import android.content.Context
import android.graphics.Bitmap
import com.magiclane.sdk.d3scene.ETouchEvent
import java.io.ByteArrayOutputStream
import android.util.Log


class GemMapTextureView(
    private val gemKitPlugin: MagiclaneMapsFlutterPlugin,
    private val surfaceTexture: SurfaceTexture,
    private val viewId: Int,
    private val context: Context
) {
    private lateinit var methodChannel: MethodChannel
    private var shouldSurfaceBeHidden: Boolean = false
    private val eventQueue = mutableListOf<EventCustom>()
    private val lockEvent = Any()
    private var isPosting = false
    val worker: GemTextureWorker
    val renderer: GemOpenGLRenderer

    init {
        worker = GemTextureWorker(context)
        renderer = GemOpenGLRenderer(surfaceTexture, worker, context)
        registerCallsFromFlutter(viewId)
    }

    private fun registerCallsFromFlutter(mapId: Int) {
        val name = "plugins.flutter.dev/gem_maps_$mapId"
        methodChannel = MethodChannel(
            gemKitPlugin.flutterPluginBinding.binaryMessenger,
            name
        )
        methodChannel.setMethodCallHandler { call, result ->
            if (!GemSdk.isInitialized()) {
                result.error(
                    GemError.EngineNotInitialized.toString(),
                    GemError.getMessage(GemError.EngineNotInitialized), null
                )
            }
            if (call.method == "waitForViewId") {
                SdkCall.execute {
                    registerMapView(result)
                }
            } else if (call.method == "captureScreenshot") {

                val pairDimensions = renderer.getSurfaceDimensions();
                val future = renderer.captureScreenshotAsync(pairDimensions?.first ?: 0, pairDimensions?.second ?: 0)
                SdkCall.execute {
                    val screenshot = future.get()
                    if (screenshot != null) {
                        var screenshotByteArray: ByteArray? = null
                        // Convert flipped bitmap to byte array (PNG format)
                        val outputStream = ByteArrayOutputStream()
                        screenshot.compress(Bitmap.CompressFormat.PNG, 100, outputStream)
                        screenshotByteArray = outputStream.toByteArray()

                        result.success(screenshotByteArray)
                    } else {
                        // result.error(
                        //GemError.UnknownError.toString(),
                        //GemError.getMessage(GemError.UnknownError), null
                        // )
                    }
                }
            } else if (call.method == "pauseResumeSurface") {
                val shouldResume = call.arguments as? Boolean ?: return@setMethodCallHandler
                result.success(if (shouldResume) "Surface resumed" else "Surface paused")
            } else if (call.method == "handleTouchEvent") {
                val args = call.arguments as? Map<*, *> ?: return@setMethodCallHandler
                val x = (args["x"] as? Number)?.toFloat() ?: return@setMethodCallHandler
                val y = (args["y"] as? Number)?.toFloat() ?: return@setMethodCallHandler
                val touchType = (args["touchType"] as? Number)?.toInt() ?: return@setMethodCallHandler
                val pointerIndex = (args["pointerIndex"] as? Number)?.toInt() ?: return@setMethodCallHandler
                // Dispatch the touch event
                dispatchTouchEventToGLSurfaceView(x, y, touchType, pointerIndex)
                //     result.success(null)
                // } else if (call.method == "pauseResumeSurface") {
                //     val shouldResume = call.arguments as? Boolean ?: return@setMethodCallHandler
                //     shouldSurfaceBeHidden = !shouldResume
                //     result.success(if (shouldResume) "Surface resumed" else "Surface paused")
                // } else if (call.method == "isSurfaceVisible") {
                //     result.success(!shouldSurfaceBeHidden)
                //
            } else if (call.arguments != null) {
                val flutterMethodListener = FlutterMethodListener.create(
                    onNotifyComplete = { err, retDetails, _ ->
                        if (err == GemError.NoError) {
                            val returnedResult = retDetails.bytes?.let { String(it) } ?: ""
                            result.success(returnedResult)
                        } else {
                            result.error(err.toString(), GemError.getMessage(err), null)
                        }
                    },
                    onNotifyEvent = { eventName, eventDetails, _ ->
                        if (eventName.isNotEmpty()) {
                            val arguments = eventDetails.bytes?.let { String(it) } ?: ""
                            if (!isPosting) {
                                isPosting = true
                                synchronized(lockEvent) {
                                    eventQueue.add(EventCustom(eventName, arguments, true))
                                }
                                Util.postOnMainDelayed({
                                    val jsonArray = JSONArray()
                                    synchronized(lockEvent) {
                                        for (eventCustom in eventQueue) {
                                            if (eventCustom != null) {
                                                val jsonObject = JSONObject()
                                                jsonObject.put("eventName", eventCustom.eventName)
                                                jsonObject.put("arguments", eventCustom.arguments)
                                                jsonArray.put(jsonObject)
                                                eventCustom.valid = false
                                            }
                                        }
                                        eventQueue.removeIf { eventCustom -> !eventCustom.valid }
                                    }
                                    val jsonArrayAsString = jsonArray.toString()
                                    methodChannel.invokeMethod("notifyEvents", jsonArrayAsString)
                                    isPosting = false
                                })
                            } else {
                                synchronized(lockEvent) {
                                    eventQueue.add(EventCustom(eventName, arguments, true))
                                }
                            }
                        }
                    },
                    onNotifyException = { _, _ ->
                        return@create GemError.NotSupported.toLong()
                    }
                )
                SdkCall.execute {
                    val args = DataBuffer((call.arguments as String).toByteArray())
                    val ret = FlutterChannel.parseMethod(call.method, args, flutterMethodListener)
                    if (ret != GemError.NoError) {
                        if (ret == GemError.NotSupported) {
                            result.notImplemented()
                        } else {
                            result.error(ret.toString(), GemError.getMessage(ret), null)
                        }
                    }
                }
            }
        }
    }

    private fun registerMapView(result: MethodChannel.Result) {
        if (worker.mapView == null) {
            var hasBeenNotified = false
            worker.onDefaultMapViewCreated = {
                // if(binaryMapStyle != null) {
                //    val dataBuffer = DataBuffer(binaryMapStyle!!)
                //   val res = worker.mapView?.preferences?.setMapStyleByDataBuffer(dataBuffer)
                //}

                FlutterChannel.registerMapView(
                    worker.mapView!!,
                    DataBuffer(),
                    FlutterMethodListener.create(
                        onNotifyComplete = { err, retDetails, _ ->
                            val arguments = retDetails.bytes?.let { returnedDetails -> String(returnedDetails) } ?: ""
                            if (err == GemError.NoError && arguments.isNotEmpty()) {
                                if (!hasBeenNotified) {
                                    result.success(arguments)
                                    hasBeenNotified = true
                                }
                            } else {
                                result.error(err.toString(), GemError.getMessage(err), null)
                            }
                        },
                        onNotifyEvent = { eventName, eventDetails, _ ->
                            if (eventName.isNotEmpty()) {
                                val arguments = eventDetails.bytes?.let { String(it) } ?: ""
                                if (!isPosting) {
                                    isPosting = true
                                    synchronized(lockEvent) {
                                        eventQueue.add(EventCustom(eventName, arguments, true))
                                    }
                                    Util.postOnMainDelayed({
                                        val jsonArray = JSONArray()
                                        synchronized(lockEvent) {
                                            for (eventCustom in eventQueue) {
                                                if (eventCustom != null) {
                                                    val jsonObject = JSONObject()
                                                    jsonObject.put("eventName", eventCustom.eventName)
                                                    jsonObject.put("arguments", eventCustom.arguments)
                                                    jsonArray.put(jsonObject)
                                                    eventCustom.valid = false
                                                }
                                            }
                                            eventQueue.removeIf { eventCustom -> !eventCustom.valid }
                                        }
                                        val jsonArrayAsString = jsonArray.toString()
                                        methodChannel.invokeMethod("notifyEvents", jsonArrayAsString)
                                        isPosting = false
                                    })
                                } else {
                                    synchronized(lockEvent) {
                                        eventQueue.add(EventCustom(eventName, arguments, true))
                                    }
                                }
                            }
                        }
                    )
                )
            }
        } else {
            FlutterChannel.registerMapView(
                worker.mapView!!,
                DataBuffer(),
                FlutterMethodListener.create(
                    onNotifyComplete = { err, retDetails, _ ->
                        SdkCall.execute {
                            val arguments = retDetails.bytes?.let { returnedDetails -> String(returnedDetails) } ?: ""
                            if (err == GemError.NoError && arguments.isNotEmpty()) {
                                result.success(arguments)
                            } else {
                                result.error(err.toString(), GemError.getMessage(err), null)
                            }
                        }
                    },
                    onNotifyEvent = { eventName, eventDetails, _ ->
                        if (eventName.isNotEmpty()) {
                            val arguments = eventDetails.bytes?.let { String(it) } ?: ""
                            if (!isPosting) {
                                isPosting = true
                                synchronized(lockEvent) {
                                    eventQueue.add(EventCustom(eventName, arguments, true))
                                }
                                Util.postOnMainDelayed({
                                    val jsonArray = JSONArray()
                                    synchronized(lockEvent) {
                                        for (eventCustom in eventQueue) {
                                            if (eventCustom != null) {
                                                val jsonObject = JSONObject()
                                                jsonObject.put("eventName", eventCustom.eventName)
                                                jsonObject.put("arguments", eventCustom.arguments)
                                                jsonArray.put(jsonObject)
                                                eventCustom.valid = false
                                            }
                                        }
                                        eventQueue.removeIf { eventCustom -> !eventCustom.valid }
                                    }
                                    val jsonArrayAsString = jsonArray.toString()
                                    methodChannel.invokeMethod("notifyEvents", jsonArrayAsString)
                                    isPosting = false
                                })
                            } else {
                                synchronized(lockEvent) {
                                    eventQueue.add(EventCustom(eventName, arguments, true))
                                }
                            }
                        }
                    }
                )
            )
        }
    }

    fun onSurfaceChanged(width: Int, height: Int) {
        surfaceTexture.setDefaultBufferSize(width, height)
        worker.onSurfaceChanged(width, height)
    }

    private fun dispatchTouchEventToGLSurfaceView(x: Float, y: Float, touchType: Int, pointerIndex: Int) {
        val event = ETouchEvent.values()[touchType]
        worker.addTouchEvent(event, pointerIndex, x, y)
        worker.forceRender();
    }

    // Renderer and worker are initialized in constructor and available as members
}
