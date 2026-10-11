package com.kolkatapuja.kolkata_puja

import android.app.Notification
import android.app.AlarmManager
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.media.AudioAttributes
import android.media.RingtoneManager
import android.os.Build
import android.os.Bundle

/** Android owns the sound/vibration: respect ring volume, silent mode and DND. */
object IncomingCallAlert {
    @Volatile private var inCall = false
    var onDismissed: ((String) -> Unit)? = null
    private const val CHANNEL = "uma_ringing_calls_v2"
    private const val NOTIFICATION = 9021
    private fun prefs(context: Context) = context.getSharedPreferences("uma_calls", Context.MODE_PRIVATE)
    private fun manager(context: Context) = context.getSystemService(NotificationManager::class.java)

    fun configure(context: Context, uid: String?, groups: List<String>) {
        val state = prefs(context)
        if (state.getString("uid", null) != uid) stop(context, null)
        state.edit().putString("uid", uid).putStringSet("groups", groups.toSet()).apply()
        val activeGroup = state.getString("activeGroup", null)
        if (activeGroup != null && activeGroup !in groups) stop(context, null)
    }

    fun busy(context: Context, value: Boolean) {
        inCall = value
        if (value) stop(context, null)
    }

    fun handled(context: Context, id: String): Boolean =
        prefs(context).getLong("handled:$id", 0) > System.currentTimeMillis()

    fun stop(context: Context, id: String?, remember: Boolean = true) {
        val state = prefs(context)
        val active = state.getString("active", null)
        if (remember && id != null) {
            val edit = state.edit()
            state.all.filter { it.key.startsWith("handled:") && (it.value as? Long ?: 0) < System.currentTimeMillis() }
                .keys.forEach { edit.remove(it) }
            edit.putLong("handled:$id", System.currentTimeMillis() + 120000).apply()
        }
        if (id == null || active == id) {
            manager(context).cancel(NOTIFICATION)
            state.edit().remove("active").remove("activeGroup").apply()
        }
    }

    fun show(context: Context, data: Bundle): Boolean {
        val id = data.getString("invitationId") ?: return false
        val group = data.getString("groupId") ?: return false
        val expiry = data.getString("expiresAt")?.toLongOrNull() ?: return false
        val now = System.currentTimeMillis()
        val state = prefs(context)
        if (expiry <= now || expiry > now + 70000 || handled(context, id) ||
            inCall || state.getString("uid", null) == null ||
            group !in (state.getStringSet("groups", emptySet()) ?: emptySet())) return false
        if (state.getString("active", null) == id &&
            manager(context).activeNotifications.any { it.id == NOTIFICATION }) return true

        val audio = AudioAttributes.Builder().setUsage(AudioAttributes.USAGE_NOTIFICATION_RINGTONE)
            .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION).build()
        val ringtone = RingtoneManager.getDefaultUri(RingtoneManager.TYPE_RINGTONE)
        if (Build.VERSION.SDK_INT >= 26) {
            manager(context).createNotificationChannel(NotificationChannel(CHANNEL, "Incoming calls", NotificationManager.IMPORTANCE_HIGH).apply {
                description = "Ringing and vibration for incoming group calls"
                setSound(ringtone, audio)
                enableVibration(true)
                vibrationPattern = longArrayOf(0, 1000, 1000)
                lockscreenVisibility = Notification.VISIBILITY_PRIVATE
            })
        }
        fun activity(action: String): PendingIntent = PendingIntent.getActivity(context, action.hashCode(),
            Intent(context, MainActivity::class.java).setAction("uma.call.$action.$id")
                .putExtras(data).putExtra("callAction", action)
                .addFlags(Intent.FLAG_ACTIVITY_SINGLE_TOP or Intent.FLAG_ACTIVITY_CLEAR_TOP),
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE)
        val decline = PendingIntent.getBroadcast(context, id.hashCode(),
            Intent(context, CallActionReceiver::class.java).putExtra("invitationId", id),
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE)
        val caller = data.getString("callerName") ?: "Group member"
        val builder = if (Build.VERSION.SDK_INT >= 26) Notification.Builder(context, CHANNEL) else Notification.Builder(context)
        builder.setSmallIcon(R.drawable.ic_notification).setContentTitle("Incoming group call")
            .setContentText("$caller is calling ${data.getString("groupName") ?: "your group"}")
            .setCategory(Notification.CATEGORY_CALL).setVisibility(Notification.VISIBILITY_PRIVATE)
            .setPriority(Notification.PRIORITY_MAX).setOngoing(true)
            .setContentIntent(activity("open")).setDeleteIntent(decline)
        if (Build.VERSION.SDK_INT >= 26) builder.setTimeoutAfter(expiry - now)
        else builder.setSound(ringtone, audio).setVibrate(longArrayOf(0, 1000, 1000))
        // CallStyle requires an FGS or full-screen intent on recent Android.
        // CATEGORY_CALL with actions can ring without either extra privilege.
        builder.addAction(Notification.Action.Builder(null, "Decline", decline).build())
            .addAction(Notification.Action.Builder(null, "Answer", activity("answer")).build())
        val notification = builder.build()
        notification.flags = notification.flags or Notification.FLAG_INSISTENT
        return try {
            manager(context).notify(NOTIFICATION, notification)
            if (Build.VERSION.SDK_INT < 26) {
                context.getSystemService(AlarmManager::class.java)
                    .setAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, expiry, decline)
            }
            state.edit().putString("active", id).putString("activeGroup", group).apply()
            true
        } catch (_: SecurityException) { false }
    }
}

/** Only Google Play services can deliver to this permission-protected receiver. */
class CallPushReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        val data = intent.extras ?: return
        when (data.getString("type")) {
            "group_call_ring" -> IncomingCallAlert.show(context, data)
            "group_call_end" -> data.getString("invitationId")?.let {
                IncomingCallAlert.stop(context, it)
                IncomingCallAlert.onDismissed?.invoke(it)
            }
        }
    }
}

class CallActionReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        intent.getStringExtra("invitationId")?.let {
            IncomingCallAlert.stop(context, it)
            IncomingCallAlert.onDismissed?.invoke(it)
        }
    }
}
