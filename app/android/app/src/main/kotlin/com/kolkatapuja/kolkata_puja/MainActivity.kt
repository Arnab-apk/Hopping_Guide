package com.kolkatapuja.kolkata_puja

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import android.view.WindowManager
import android.content.Intent
import android.os.Bundle

class MainActivity : FlutterActivity() {
    private var calls: MethodChannel? = null
    private var pendingCall: Map<String, String>? = null

    private fun readCallIntent(intent: Intent?) {
        val action = intent?.getStringExtra("callAction") ?: return
        val id = intent.getStringExtra("invitationId") ?: return
        val group = intent.getStringExtra("groupId") ?: return
        val expiry = intent.getStringExtra("expiresAt") ?: return
        IncomingCallAlert.stop(this, id, remember = action == "answer")
        intent.removeExtra("callAction")
        if ((expiry.toLongOrNull() ?: 0) <= System.currentTimeMillis()) return
        pendingCall = mapOf("groupId" to group, "invitationId" to id, "expiresAt" to expiry, "action" to action)
        calls?.invokeMethod("opened", pendingCall)
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        // A window-wide hint covers Flutter and native map surfaces. Android
        // retains control for supported modes, battery saver and thermal limits.
        window.attributes = window.attributes.apply { preferredRefreshRate = 120f }
        IncomingCallAlert.busy(this, false)
        readCallIntent(intent)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        readCallIntent(intent)
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        calls = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "uma/calls").also { channel ->
            IncomingCallAlert.onDismissed = { channel.invokeMethod("dismissed", it) }
            channel.setMethodCallHandler { call, result ->
                when (call.method) {
                    "configure" -> {
                        IncomingCallAlert.configure(this, call.argument<String>("uid"), call.argument<List<String>>("groups") ?: emptyList())
                        result.success(null)
                    }
                    "show" -> {
                        val data = Bundle()
                        (call.arguments as? Map<*, *>)?.forEach { (key, value) -> if (key is String && value is String) data.putString(key, value) }
                        result.success(IncomingCallAlert.show(this, data))
                    }
                    "stop" -> { IncomingCallAlert.stop(this, call.arguments as? String); result.success(null) }
                    "handled" -> result.success(IncomingCallAlert.handled(this, call.arguments as String))
                    "busy" -> { IncomingCallAlert.busy(this, call.arguments == true); result.success(null) }
                    "pending" -> { result.success(pendingCall); pendingCall = null }
                    else -> result.notImplemented()
                }
            }
        }
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "uma/navigation")
            .setMethodCallHandler { call, result ->
                if (call.method == "keepScreenOn") {
                    if (call.arguments == true) window.addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
                    else window.clearFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
                    result.success(null)
                } else result.notImplemented()
            }
    }

    override fun onDestroy() {
        IncomingCallAlert.onDismissed = null
        calls = null
        super.onDestroy()
    }
}
