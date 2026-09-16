/*
 * SPDX-FileCopyrightText: 2023-2026 Magic Lane International B.V. <info@magiclane.com>
 * SPDX-License-Identifier: LicenseRef-MagicLane-Proprietary
 *
 * For the latest licensing terms and conditions, see https://www.magiclane.com/web/terms-and-conditions#terms-of-service.
 * For further information use the contact form at https://www.magiclane.com/web/contact.
 */

package com.magiclane.magiclane_maps_flutter

import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.FlutterPlugin.FlutterPluginBinding
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import android.util.Log
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import android.app.Application
import android.app.Activity
import android.content.Context
import android.os.Bundle
import android.os.Environment
import com.magiclane.sdk.util.SdkCall
import com.magiclane.sdk.core.GemSdk
import com.magiclane.sdk.core.ApiCallLogger
import com.magiclane.sdk.core.SdkSettings
import com.magiclane.sdk.core.EOffboardListenerReason
import com.magiclane.sdk.core.EOffboardListenerStatus
import com.magiclane.sdk.core.ProgressListener
import com.magiclane.sdk.core.ProxyDetails
import com.magiclane.sdk.flutter.FlutterChannel
import com.magiclane.sdk.flutter.FlutterMethodListener
import com.magiclane.sdk.core.GemError
import com.magiclane.sdk.util.Util
import org.json.JSONArray
import org.json.JSONObject
import com.magiclane.sdk.core.DataBuffer
import com.magiclane.sdk.util.*
import com.magiclane.sdk.core.SoundPlayingListener
import com.magiclane.sdk.core.ISoundPlayingListener
import com.magiclane.sdk.core.SoundPlayingPreferences
import com.magiclane.sdk.core.SoundPlayingService
import com.magiclane.sdk.core.INetworkListener
import com.magiclane.sdk.core.NetworkListener
import com.magiclane.sdk.core.ENetworkType
import android.os.Handler
import android.os.Looper
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import java.io.File
import com.magiclane.sdk.core.GemTextureWorker
import com.magiclane.sdk.core.GemOpenGLRenderer
import com.magiclane.sound.SoundUtils
import kotlin.jvm.Volatile

/** MagiclaneMapsFlutterPlugin */
class MagiclaneMapsFlutterPlugin : FlutterPlugin, MethodCallHandler, Application.ActivityLifecycleCallbacks, ActivityAware {
    // For OpenGL texture test
    private val openglRenders = mutableMapOf<Int, GemMapTextureView>()
    private var nextViewId: Int = 0
    private lateinit var channel: MethodChannel
    private val customApiCallLogger by lazy { CustomApiCallLogger() }
    lateinit var flutterPluginBinding: FlutterPluginBinding
    private lateinit var gemEngineChannel: MethodChannel
    var eventQueue = mutableListOf<EventCustom>()
    var lockEvent = Any()
    var isPosting = false
    private var activity: Activity? = null
    private val mainHandler = Handler(Looper.getMainLooper())
    @Volatile
    private var sdkSettingsCallbacksRegistered = false

    /**
     * Resets every callback registered by [registerSdkSettingsCallbacks] back
     * to the SDK-default no-op lambda (the callbacks are non-null function
     * types — `var x: () -> Unit = {}` — so they cannot be assigned `null`).
     * Also clears [sdkSettingsCallbacksRegistered] so a subsequent
     * [registerSdkSettingsCallbacks] call (e.g. on hot-restart re-attach)
     * proceeds. See audit issue 5c.
     */
    private fun unregisterSdkSettingsCallbacks() {
        if (!sdkSettingsCallbacksRegistered) {
            return
        }
        SdkSettings.onConnectionStatusUpdated = {}
        SdkSettings.onWorldwideRoadMapSupportDisabled = {}
        SdkSettings.onWorldwideRoadMapSupportEnabled = {}
        SdkSettings.onWorldwideRoadMapSupportStatus = {}
        SdkSettings.onResourcesReadyToDeploy = {}
        SdkSettings.isResourcesUpdateAllowed = { true }
        SdkSettings.onOnlineCacheSizeChange = {}
        SdkSettings.onWorldwideRoadMapVersionUpdated = {}
        SdkSettings.onWorldwideRoadMapUnsupportedCapabilities = {}
        SdkSettings.onApiTokenRejected = {}
        SdkSettings.onApiTokenUpdated = {}
        sdkSettingsCallbacksRegistered = false
    }

    /**
     * Disposes every entry in [openglRenders] and clears the map. Each
     * `onDispose` call is wrapped individually so a failure on one texture
     * cannot prevent the rest from being torn down. See audit issue 5c.
     */
    private fun disposeAllOpenGLTextures() {
        val texturesSnapshot = openglRenders.values.toList()
        openglRenders.clear()
        for (textureView in texturesSnapshot) {
            try {
                textureView.renderer?.onDispose()
            } catch (e: Exception) {
                Log.w(
                    "MagiclaneMapsFlutter",
                    "Error disposing OpenGL texture during detach",
                    e
                )
            }
        }
    }

    private fun emitSdkSettingsEvent(
        eventSubtype: String,
        payload: Map<String, Any?> = emptyMap()
    ) {
        if (!::gemEngineChannel.isInitialized) {
            return
        }

        val data = HashMap<String, Any?>(payload.size + 1)
        data["event_subtype"] = eventSubtype
        for ((key, value) in payload) {
            data[key] = value
        }

        mainHandler.post {
            try {
                gemEngineChannel.invokeMethod("sdkSettingsEvent", data)
            } catch (_: Exception) {
                // Best-effort notification; ignore channel failures.
            }
        }
    }

    private fun registerSdkSettingsCallbacks() {
        if (sdkSettingsCallbacksRegistered) {
            return
        }
        sdkSettingsCallbacksRegistered = true

        SdkSettings.onConnectionStatusUpdated = { connected: Boolean ->
            emitSdkSettingsEvent(
                eventSubtype = "onConnectionStatusUpdated",
                payload = mapOf("connected" to connected)
            )
        }

        SdkSettings.onWorldwideRoadMapSupportDisabled = { reason: EOffboardListenerReason ->
            emitSdkSettingsEvent(
                eventSubtype = "onWorldwideRoadMapSupportDisabled",
                payload = mapOf("reason" to reason.ordinal)
            )
        }

        SdkSettings.onWorldwideRoadMapSupportEnabled = {
            emitSdkSettingsEvent("onWorldwideRoadMapSupportEnabled")
        }

        SdkSettings.onWorldwideRoadMapSupportStatus = { state: EOffboardListenerStatus ->
            emitSdkSettingsEvent(
                eventSubtype = "onWorldwideRoadMapSupportStatus",
                payload = mapOf("state" to state.ordinal)
            )
        }

        SdkSettings.onResourcesReadyToDeploy = {
            emitSdkSettingsEvent("onResourcesReadyToDeploy")
        }

        SdkSettings.isResourcesUpdateAllowed = {
            true
        }

        SdkSettings.onOnlineCacheSizeChange = { size: Int ->
            emitSdkSettingsEvent(
                eventSubtype = "onOnlineCacheSizeChange",
                payload = mapOf("size" to size)
            )
        }

        SdkSettings.onWorldwideRoadMapVersionUpdated = {
            emitSdkSettingsEvent("onWorldwideRoadMapVersionUpdated")
        }

        SdkSettings.onWorldwideRoadMapUnsupportedCapabilities = {
            emitSdkSettingsEvent("onWorldwideRoadMapUnsupportedCapabilities")
        }

        SdkSettings.onApiTokenRejected = {
            emitSdkSettingsEvent("onApiTokenRejected")
        }

        SdkSettings.onApiTokenUpdated = {
            emitSdkSettingsEvent("onApiTokenUpdated")
        }
    }

    private fun getUseInternalPath(context: Context): Boolean {
        return try {
            val appPackageName = context.packageName
            val buildConfigClass = Class.forName("$appPackageName.BuildConfig")
            val field = buildConfigClass.getField("USE_INTERNAL_PATH")
            field.getBoolean(null)
        } catch (e: Exception) {
            // Fallback to plugin's default
            BuildConfig.USE_INTERNAL_PATH
        }
    }

    private fun getUseEarlyInit(context: Context): Boolean {
        return try {
            val appPackageName = context.packageName
            val buildConfigClass = Class.forName("$appPackageName.BuildConfig")
            val field = buildConfigClass.getField("USE_EARLY_INIT")
            field.getBoolean(null)
        } catch (e: Exception) {
            // Fallback to plugin's default
            BuildConfig.USE_EARLY_INIT
        }
    }

    fun initializeGemSdkIfNeeded(context: Context, activity: Activity?, setNetworkProvider: Boolean = true, callback: (Int) -> Unit, aVar: Int? = null) {
        Log.d("MagiclaneMapsFlutter", "initializeGemSdkIfNeeded called with aVar = $aVar")

        if (!GemSdk.isInitialized()) {
            SdkSettings.setAllowAutoMapUpdate(false)
            val sdkInitProgress = ProgressListener.create(
                onCompleted = { _, _ ->
                    GemSdk.notifyEngineInit()
                },
            )

            val internalPath = if (getUseInternalPath(flutterPluginBinding.applicationContext)) getInternalPath(flutterPluginBinding.applicationContext) else null
            SdkCall.execute {
               // customApiCallLogger = CustomApiCallLogger()

                val exceptionCallback: (Int, String) -> Unit = { code, message ->
                    Handler(Looper.getMainLooper()).post {
                        Log.d("MagiclaneMapsFlutter", "Forwarding exception to Flutter Gem Engine: code=$code, message=$message")
                        try {
                            if (::gemEngineChannel.isInitialized) {
                                gemEngineChannel.invokeMethod(
                                    "exceptionCallback",
                                    mapOf("code" to code, "message" to message)
                                )
                            }
                        } catch (_: Exception) {
                            // ignore any errors while forwarding
                        }
                    }
                }
                val initResult = GemSdk.initSdkWithDefaults(
                    context = context,
                    listener = sdkInitProgress,
                    internalPath = internalPath,
                    logger = customApiCallLogger,
                    exceptionCallback = exceptionCallback,
                    appVariant = aVar,
                )

                callback(initResult)
            }
        } else {
            callback(0) // Already initialized, success
        }
    }

    override fun onAttachedToEngine(flutterPluginBinding: FlutterPluginBinding) {
        this.flutterPluginBinding = flutterPluginBinding
        channel = MethodChannel(flutterPluginBinding.binaryMessenger, "plugins.flutter.dev/gem_maps")
        channel.setMethodCallHandler(this)

        flutterPluginBinding
            .platformViewRegistry
            .registerViewFactory("plugins.flutter.dev/gem_maps", GemMapViewFactory(this, flutterPluginBinding.flutterAssets))

        gemEngineChannel = MethodChannel(flutterPluginBinding.binaryMessenger, "plugins.flutter.dev/gem_engine")
        gemEngineChannel.setMethodCallHandler { call, result ->
            handleGemEngineMethodCall(call, result)
        }

        registerSdkSettingsCallbacks()

        val appContext = flutterPluginBinding.applicationContext as Application
        appContext.registerActivityLifecycleCallbacks(this)
    }

    override fun onMethodCall(call: MethodCall, result: Result) {
        if (call.method == "getPlatformVersion") {
            result.success("Android ${android.os.Build.VERSION.RELEASE}")
            return
        }

        // Test OpenGL texture creation
        if (call.method == "createOpenGLTexture") {
            val width = (call.argument<Int>("width") ?: 512)
            val height = (call.argument<Int>("height") ?: 512)
            val textures = flutterPluginBinding.textureRegistry
            val entry = textures.createSurfaceTexture()
            val surfaceTexture = entry.surfaceTexture()
            surfaceTexture.setDefaultBufferSize(width, height)
            val viewId = nextViewId++
            val textureView = GemMapTextureView(this, surfaceTexture, viewId, flutterPluginBinding.applicationContext)
            textureView.onSurfaceChanged(width, height)
            openglRenders[viewId] = textureView
            result.success(viewId)
            return
        }
        if (call.method == "disposeOpenGLTexture") {
            val viewId = call.argument<Int>("textureId")
            val textureView = openglRenders[viewId]
            // Always remove the map entry, even if onDispose throws — otherwise
            // a single bad teardown leaks the renderer permanently. See audit
            // issue 5a.
            try {
                textureView?.renderer?.onDispose()
            } finally {
                openglRenders.remove(viewId)
            }
            result.success(true)
            return
        }
        if (call.method == "onSurfaceChanged") {
            val viewId = call.argument<Int>("textureId")
            val width = call.argument<Int>("width") ?: return
            val height = call.argument<Int>("height") ?: return
            val textureView = openglRenders[viewId]
            textureView?.onSurfaceChanged(width, height)
            result.success(null)
            return
        }
        result.notImplemented()
    }

    override fun onDetachedFromEngine(binding: FlutterPluginBinding) {
        // Stop incoming method-channel calls FIRST so no handler runs against
        // half-disposed state.
        channel.setMethodCallHandler(null)
        if (::gemEngineChannel.isInitialized) {
            gemEngineChannel.setMethodCallHandler(null)
        }

        // Reset SdkSettings callbacks back to their default no-op lambdas so
        // a subsequent re-attach (hot restart) can safely call
        // registerSdkSettingsCallbacks again without doubling them up.
        unregisterSdkSettingsCallbacks()

        // Drop any in-flight events — they belong to the previous engine and
        // would dispatch through a now-detached gemEngineChannel.
        synchronized(lockEvent) {
            eventQueue.clear()
        }

        // Tear down OpenGL renderers held in openglRenders. Each onDispose is
        // wrapped individually so a failure on one cannot leak the rest.
        disposeAllOpenGLTextures()

        val appContext = binding.applicationContext as Application
        appContext.unregisterActivityLifecycleCallbacks(this)
    }

    override fun onActivityPaused(activity: Activity) {
        SdkCall.execute {
            if (GemSdk.isInitialized())
                GemSdk.notifyBackgroundEvent(GemSdk.EBackgroundEvent.EnterBackground)
        }
    }

    override fun onActivityResumed(activity: Activity) {
        SdkCall.execute {
            if (GemSdk.isInitialized())
                GemSdk.notifyBackgroundEvent(GemSdk.EBackgroundEvent.LeaveBackground)
        }
    }

    override fun onActivityCreated(iActivity: Activity, savedInstanceState: Bundle?) {
        activity = iActivity
    }

    override fun onActivityStarted(activity: Activity) {
        // Called when the activity is started
    }

    override fun onActivityStopped(activity: Activity) {
        // Called when the activity is stopped
    }

    override fun onActivitySaveInstanceState(activity: Activity, outState: Bundle) {
    }

    override fun onActivityDestroyed(activity: Activity) {
    }

    private fun handleGemEngineMethodCall(call: MethodCall, result: Result) {
        if (call.arguments != null) {
            if (call.method == "networkProviderCall") {
                handleNetworkProviderCall(call.arguments as String, result)
                return
            }
            if (call.method == "setLogLevel") {
                val jsonString = call.arguments as? String
                if (jsonString == null) {
                    result.error("NO_ARGUMENT", "Expected a JSON string", null)
                    return
                }

                val jsonResult = runCatching {
                    JSONObject(jsonString)
                }

                val json = jsonResult.getOrNull()
                if (json == null) {
                    result.error("INVALID_JSON", "Could not parse JSON", null)
                    return
                }

                val level = json.optInt("level", 0)
                customApiCallLogger.logLevel = level

                result.success(true)
                return
            }
            if (call.method == "getLogPath") {
                val logPath = GemSdk.appLogPath
                result.success(logPath)
                return
            }
            if (call.method == "releaseEngine") {
                SdkCall.execute {
                    GemSdk.release()
                    result.success(true)
                }
                return
            }
            if (call.method == "SoundServicePlayText") {
                val jsonObject = JSONObject(call.arguments as String);
                val text = jsonObject.getString("text")
                val severity = jsonObject.optInt("severity", 0)
                val progressListenerId = jsonObject.optLong("progressListenerId", -1)
                val preferencesPointer = jsonObject.optLong("preferencesPointer", -1)
                if (!SoundPlayingService.ttsPlayerIsInitialized) {
                    SoundUtils.addTTSPlayerInitializationListener(object :
                        SoundUtils.ITTSPlayerInitializationListener {
                        override fun onTTSPlayerInitialized() = playText(text, severity, progressListenerId, preferencesPointer, result)
                        override fun onTTSPlayerInitializationFailed() {
                            assert(false) { "init failed" }
                        }
                    })
                } else {
                    playText(text, severity, progressListenerId, preferencesPointer, result)
                }
                return
            }

            if (call.method == "SoundServiceGetPointer") {
                val address = SoundPlayingService.address
                val addressTtsPlayer = SoundPlayingService.ttsPlayer?.address
                val addressRawPlayer = SoundPlayingService.rawPlayer?.address
                val responseData = mapOf(
                    "address" to address,
                    "addressTtsPlayer" to addressTtsPlayer,
                    "addressRawPlayer" to addressRawPlayer
                )
                result.success(responseData)
                return
            }
            if (call.method == "initializeGemSdk") {
                // Get aVar from JSON arguments
                val jsonString = call.arguments as? String
                var aVar: Int? = null
                if (jsonString != null) {
                    val jsonResult = runCatching {
                        JSONObject(jsonString)
                    }
                    val json = jsonResult.getOrNull()
                    if (json != null) {
                        aVar = if (json.has("aVar")) json.optInt("aVar") else null
                    }
                }

                val context = activity ?: flutterPluginBinding.applicationContext
                initializeGemSdkIfNeeded(
                    context = context,
                    activity = activity,
                    setNetworkProvider = true,
                    callback = { initResult ->
                        result.success(initResult)
                    },
                    aVar = aVar
                )
                return
            }

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
                                gemEngineChannel.invokeMethod("notifyEvents", jsonArrayAsString)
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

    private fun playText(text: String, severity: Int, progressListenerId: Long, preferencesPointer: Long, result: Result) {
        SdkCall.execute {

            val errorCode = SoundPlayingService.playText(
                text, ISoundPlayingListener(progressListenerId, true), SoundPlayingPreferences(preferencesPointer, true)
            )
            result.success(errorCode)
        }
    }

    private fun handleNetworkProviderCall(jsonCall: String, result: Result) {
        try {
            val jsonObject = JSONObject(jsonCall)
            val action = jsonObject.getString("action")

            when (action) {
                "isConnected" -> {
                    SdkCall.execute {
                        val isConnected = SdkSettings.isConnected()
                        result.success(isConnected)
                    }
                }

                "isWifiConnected" -> {
                    SdkCall.execute {
                        val networkProvider = SdkSettings.networkProvider;
                        if (networkProvider == null){
                            result.success(false)
                            return@execute
                        }
                        val isWifi = networkProvider.isWifiConnected()
                        result.success(isWifi)
                    }
                }

                "isMobileDataConnected" -> {
                    SdkCall.execute {
                        val networkProvider = SdkSettings.networkProvider;
                        if (networkProvider == null){
                            result.success(false)
                            return@execute
                        }
                        val isMobileData = networkProvider.isMobileDataConnected()
                        result.success(isMobileData)
                    }
                }


                "refreshNetwork" -> {
                    result.success(true) // Operation no longer required
                }

                "setUserDisabledNetwork" -> {
                    SdkCall.execute {
                        val userDisabledNetwork = jsonObject.getBoolean("disabled")
                        SdkSettings.allowConnection = !userDisabledNetwork
                        result.success(true)
                    }
                }

                else -> {
                    result.error("INVALID_ACTION", "Action $action is not supported", null)
                }
            }
        } catch (e: Exception) {
            result.error("JSON_ERROR", "Failed to parse JSON: ${e.message}", null)
        }
    }

    private fun getInternalPath(context: Context): String {
        try {
            val fileList = context.getExternalFilesDirs(Environment.DIRECTORY_DOWNLOADS)
            if (fileList != null) {
                for (i in fileList.indices) {
                    if ((fileList[i] != null) && fileList[i].absolutePath.isNotEmpty() && isValidStorage(
                            fileList[i]
                        )
                    ) {
                        val file = File(fileList[i].absolutePath, "MAGICEARTH")
                        return file.absolutePath ?: ""
                    }
                }
            }
        } catch (_: Throwable) {
        }

        return ""
    }


    private fun isValidStorage(path: File): Boolean {
        val testFolderName = "qazxywqazwsx"


        try {
            if (path.isDirectory && path.canRead() && path.canWrite()) {
                val file = File(path, testFolderName)

                file.delete()

                if (file.mkdir()) {

                    return file.delete()

                }

                GEMLog.debug(
                    this,
                    "AppUtils.isValidStorage(): path ${path.absolutePath} is not valid"
                )
            }
        } catch (_: Exception) {
        }
        return false
    }

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        activity = binding.activity
        // if (getUseEarlyInit(activity!!.applicationContext)) {
        //     initializeGemSdkIfNeeded(
        //         context = activity!!.applicationContext,
        //         activity = activity!!,
        //         setNetworkProvider = true
        //     )
        // }
    }

    override fun onDetachedFromActivityForConfigChanges() {
        activity = null
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        activity = binding.activity
    }

    override fun onDetachedFromActivity() {
        activity = null
    }
}
