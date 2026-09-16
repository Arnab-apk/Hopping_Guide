/*
 * SPDX-FileCopyrightText: 2023-2026 Magic Lane International B.V. <info@magiclane.com>
 * SPDX-License-Identifier: LicenseRef-MagicLane-Proprietary
 *
 * For the latest licensing terms and conditions, see https://www.magiclane.com/web/terms-and-conditions#terms-of-service.
 * For further information use the contact form at https://www.magiclane.com/web/contact.
 */

package com.magiclane.magiclane_maps_flutter

import android.app.Activity
import android.app.Application
import android.content.Context
import android.graphics.Bitmap
import android.graphics.Matrix
import android.opengl.GLES20
import android.os.Bundle
import android.util.Log
import android.view.View
import android.view.ViewGroup
import android.view.Window
import android.view.WindowManager
import com.magiclane.sdk.core.DataBuffer
import com.magiclane.sdk.core.GemError
import com.magiclane.sdk.core.GemSdk
import com.magiclane.sdk.core.GemSurfaceView
import com.magiclane.sdk.flutter.FlutterChannel
import com.magiclane.sdk.flutter.FlutterMethodListener
import com.magiclane.sdk.util.SdkCall
import com.magiclane.sdk.util.Util
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.platform.PlatformView
import org.json.JSONArray
import org.json.JSONObject
import java.io.ByteArrayOutputStream
import java.io.InputStream
import java.nio.ByteBuffer
import java.nio.ByteOrder
import java.util.concurrent.CountDownLatch
import android.view.MotionEvent
import android.os.SystemClock
import android.view.InputDevice

class EventCustom(val eventName: String, val arguments: String, var valid: Boolean)

class GemMapView(
    private val gemKitPlugin: MagiclaneMapsFlutterPlugin,
    viewId: Int,
    context: Context,
    args: Any?,
    private val flutterAssets: FlutterPlugin.FlutterAssets
) : PlatformView, Application.ActivityLifecycleCallbacks {
    var eventQueue = mutableListOf<EventCustom>()
    var lockEvent = Any()
    var isPosting = false
    private val gemSurfaceView: GemSurfaceView
    private lateinit var methodChannel: MethodChannel
    private val appContext: Context

    private var activity: Activity? = null
    private var binaryMapStyle: ByteArray? = null
    private var initialMapStyleId: Long? = null

    private var shouldSurfaceBeHidden: Boolean = false

    init {
        gemSurfaceView = GemSurfaceView(
            context = context,
            autoReleaseOnDetachedFromWindow = false,
            postLambdasOnMain = false
        )

        val creationParams = args as? Map<String, Any>
        if (creationParams != null) {
            val rawId = creationParams["mapStyleId"]
            initialMapStyleId = when (rawId) {
                is Number -> rawId.toLong()
                else -> null
            }
            if (initialMapStyleId == null) {
                val assetKey = creationParams["mapStyleAssetPath"] as? String
                if (assetKey != null) {
                    binaryMapStyle = readFlutterAssetAsByteArray(context, assetKey)
                }
            }
        }

        gemSurfaceView.visibilityChangeListener = object : GemSurfaceView.VisibilityChangeListener {
            override fun onVisibilityChanged(isVisible: Boolean) {

                if (shouldSurfaceBeHidden) return

                // Handle visibility change
                if (gemSurfaceView.isShown) {
                    if (gemSurfaceView.mapView != null)

                        gemSurfaceView.onResume()
                } else {
                    if (gemSurfaceView.mapView != null) {
                        gemSurfaceView.onPause()
                    }
                }
                if (isVisible)
                    gemSurfaceView.visibility = View.VISIBLE
                else
                    gemSurfaceView.visibility = View.INVISIBLE
            }
        }
        appContext = context.applicationContext
        val aContext = appContext as Application
        aContext.registerActivityLifecycleCallbacks(this)
        registerCallsFromFlutter(viewId.toLong())
    }

    override fun getView(): View = gemSurfaceView

    override fun dispose() {
        releaseMapView()
        val aContext = appContext as Application
        aContext.unregisterActivityLifecycleCallbacks(this)
    }

    private fun registerMapView(result: MethodChannel.Result) {
        if (gemSurfaceView.mapView == null) {
            var hasBeenNotified = false
            gemSurfaceView.onDefaultMapViewCreated = {
                if (initialMapStyleId != null) {
                    gemSurfaceView.mapView?.preferences?.setMapStyleById(initialMapStyleId!!)
                } else if (binaryMapStyle != null) {
                    val dataBuffer = DataBuffer(binaryMapStyle!!)
                    val res = gemSurfaceView.mapView?.preferences?.setMapStyleByDataBuffer(dataBuffer)
                }

                FlutterChannel.registerMapView(
                    gemSurfaceView.mapView!!,
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
                gemSurfaceView.mapView!!,
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

    private fun releaseMapView() {
        if (gemSurfaceView != null && gemSurfaceView.mapView != null) {
            SdkCall.execute {
                FlutterChannel.unregisterMapView(gemSurfaceView.mapView!!, FlutterMethodListener.create())
                gemSurfaceView.release()
            }
        }
    }

    private fun captureScreenshotSync(): ByteArray? {
        var screenshotByteArray: ByteArray? = null

        // Create a latch to synchronize the completion of OpenGL operations
        val latch = CountDownLatch(1)

        // Queue a Runnable to execute on the GLThread
        gemSurfaceView.queueEvent(Runnable {
            try {
                // Ensure OpenGL operations are performed on the GLSurfaceView's rendering thread
                val width = gemSurfaceView.width
                val height = gemSurfaceView.height
                val buffer = ByteBuffer.allocateDirect(width * height * 4)
                buffer.order(ByteOrder.nativeOrder())

                // Read pixels from the framebuffer
                GLES20.glReadPixels(0, 0, width, height, GLES20.GL_RGBA, GLES20.GL_UNSIGNED_BYTE, buffer)

                // Create bitmap from pixel data
                val bitmap = Bitmap.createBitmap(width, height, Bitmap.Config.ARGB_8888)
                buffer.rewind()
                bitmap.copyPixelsFromBuffer(buffer)

                // Flip the bitmap vertically
                val flippedBitmap = Bitmap.createBitmap(width, height, Bitmap.Config.ARGB_8888)
                for (y in 0 until height) {
                    for (x in 0 until width) {
                        flippedBitmap.setPixel(x, height - y - 1, bitmap.getPixel(x, y))
                    }
                }

                // Convert flipped bitmap to byte array (PNG format)
                val outputStream = ByteArrayOutputStream()
                flippedBitmap.compress(Bitmap.CompressFormat.PNG, 100, outputStream)
                screenshotByteArray = outputStream.toByteArray()

                // Clean up resources
                bitmap.recycle()
                flippedBitmap.recycle()
            } catch (e: Exception) {
                e.printStackTrace()
            } finally {
                // Release the latch to signal completion
                latch.countDown()
            }
        })

        try {
            // Wait for OpenGL operations to complete
            latch.await()
        } catch (e: InterruptedException) {
            e.printStackTrace()
        }

        // Return the captured screenshot byte array (or null if capturing failed)
        return screenshotByteArray
    }

    fun getMotionEventAction(touchType: Int, pointerIndex: Int): Int {
        return when (touchType) {
            0 -> MotionEvent.ACTION_DOWN // First finger down
            1 -> MotionEvent.ACTION_MOVE
            2 -> MotionEvent.ACTION_UP // Last finger up
            3 -> MotionEvent.ACTION_CANCEL
            else -> -1
        }.let { baseAction ->
            // For multi-touch: Encode pointer index in action
            if (baseAction == MotionEvent.ACTION_DOWN || baseAction == MotionEvent.ACTION_UP) {
                baseAction
            } else {
                baseAction or (pointerIndex shl MotionEvent.ACTION_POINTER_INDEX_SHIFT)
            }
        }
    }

    private fun dispatchTouchEventToGLSurfaceView(x: Float, y: Float, touchType: Int, pointerIndex: Int) {
        val action = getMotionEventAction(touchType, pointerIndex)
        if (action == -1) return

        val eventTime = SystemClock.uptimeMillis()

        val pointerProperties = arrayOf(MotionEvent.PointerProperties().apply {
            id = pointerIndex
            toolType = MotionEvent.TOOL_TYPE_FINGER
        })

        val pointerCoords = arrayOf(MotionEvent.PointerCoords().apply {
            this.x = x
            this.y = y
            pressure = 1.0f
            size = 1.0f
        })
        val event = MotionEvent.obtain(
            eventTime,
            eventTime,
            action,
            1,
            pointerProperties,
            pointerCoords,
            0, 0, 1.0f, 1.0f,
            0, 0, InputDevice.SOURCE_TOUCHSCREEN, 0
        )
        gemSurfaceView.dispatchTouchEvent(event)
        event.recycle()
    }

    private fun registerCallsFromFlutter(mapId: Long) {
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
                SdkCall.execute { registerMapView(result) }
            } else if (call.method == "captureScreenshot") {
                val screenshot = captureScreenshotSync()
                if (screenshot != null) {
                    result.success(screenshot)
                } else {
                    result.error("UNAVAILABLE", "Screenshot not available.", null)
                }
            } else if (call.method == "handleTouchEvent") {
                val args = call.arguments as? Map<*, *> ?: return@setMethodCallHandler
                val x = (args["x"] as? Number)?.toFloat() ?: return@setMethodCallHandler
                val y = (args["y"] as? Number)?.toFloat() ?: return@setMethodCallHandler
                val touchType = (args["touchType"] as? Number)?.toInt() ?: return@setMethodCallHandler
                val pointerIndex = (args["pointerIndex"] as? Number)?.toInt() ?: return@setMethodCallHandler

                // Dispatch the touch event
                dispatchTouchEventToGLSurfaceView(x, y, touchType, pointerIndex)
                result.success(null)

            } else if (call.method == "pauseResumeSurface") {
                val shouldResume = call.arguments as? Boolean ?: return@setMethodCallHandler

                if (shouldResume) {
                    shouldSurfaceBeHidden = false
                    gemSurfaceView.onResume()
                    result.success("Surface resumed")
                } else {
                    shouldSurfaceBeHidden = true
                    gemSurfaceView.onPause();
                    result.success("Surface paused")
                }
            } else if (call.method == "isSurfaceVisible") {
                result.success(gemSurfaceView.isShown)
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

    override fun onActivityPaused(activity: Activity) {
        if (gemSurfaceView.mapView != null) {
            gemSurfaceView.onPause()
        }
    }

    override fun onActivityResumed(activity: Activity) {
        this.activity = activity
        if (gemSurfaceView.mapView != null && gemSurfaceView.isShown) {
            gemSurfaceView.onResume()
        }
    }

    override fun onActivityCreated(activity: Activity, savedInstanceState: Bundle?) {
        // Called when the activity is created or re-created
    }

    override fun onActivityStarted(activity: Activity) {
        // Called when the activity is started
    }

    override fun onActivityStopped(activity: Activity) {
        // Called when the activity is stopped
    }

    override fun onActivitySaveInstanceState(activity: Activity, outState: Bundle) {}

    override fun onActivityDestroyed(activity: Activity) {
        if (this.activity == activity) {
            this.activity = null
        }

    }

    private fun readFlutterAssetAsByteArray(
        context: Context,
        assetKey: String
    ): ByteArray? {
        return try {
            // Resolve the asset path using FlutterAssets
            val assetPath = flutterAssets.getAssetFilePathByName(assetKey)

            // Open the asset using AssetManager
            val inputStream: InputStream = context.assets.open(assetPath)

            // Read the input stream into a ByteArray
            inputStream.use { it.readBytes() }
        } catch (e: Exception) {
            e.printStackTrace()
            null
        }
    }

}
