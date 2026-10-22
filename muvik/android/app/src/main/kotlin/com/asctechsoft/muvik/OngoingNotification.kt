package com.asctechsoft.muvik

import android.app.AlarmManager
import android.app.ForegroundServiceStartNotAllowedException
import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.pm.ServiceInfo
import android.content.res.Configuration
import android.os.Build
import android.os.IBinder
import android.util.Log
import android.widget.RemoteViews
import androidx.core.app.NotificationCompat
import androidx.core.app.ServiceCompat

/**
 * The always-visible reminder notification: a short hook line and an "Open"
 * button that opens the app, to nudge the user back. Every tap opens the app.
 * It is separate from the audio_service media notification and is
 * kept alive by a foreground service plus a periodic health check, so it stays
 * in the shade until the user turns it off in Settings.
 *
 * Dart pushes the text through the `ongoing` method channel; everything is kept
 * in SharedPreferences so the service can rebuild it after a restart or reboot.
 */
object OngoingNotification {
    const val CHANNEL = "com.asctechsoft.muvik.ongoing"
    const val NOTIFICATION_ID = 7310
    private const val PREFS = "muvik_ongoing"
    private const val KEY_ENABLED = "enabled"
    private const val KEY_TITLE = "title"
    private const val KEY_DESC = "desc"
    private const val KEY_OPEN_LABEL = "open_label"
    private const val KEY_CHANNEL_NAME = "channel_name"
    private const val REQ_OPEN = 7311

    private fun prefs(context: Context) =
        context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)

    fun isEnabled(context: Context) = prefs(context).getBoolean(KEY_ENABLED, false)

    /** Stores the latest text; starts the service or re-posts as needed. */
    fun update(
        context: Context,
        title: String,
        desc: String,
        openLabel: String,
        channelName: String,
    ) {
        prefs(context).edit()
            .putBoolean(KEY_ENABLED, true)
            .putString(KEY_TITLE, title)
            .putString(KEY_DESC, desc)
            .putString(KEY_OPEN_LABEL, openLabel)
            .putString(KEY_CHANNEL_NAME, channelName)
            .apply()
        OngoingService.start(context)
        OngoingHealthCheckReceiver.schedule(context)
    }

    fun disable(context: Context) {
        prefs(context).edit().putBoolean(KEY_ENABLED, false).apply()
        OngoingHealthCheckReceiver.cancel(context)
        OngoingService.stop(context)
    }

    fun createChannel(context: Context) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return
        val name = prefs(context).getString(KEY_CHANNEL_NAME, null) ?: "Muvik"
        val channel = NotificationChannel(CHANNEL, name, NotificationManager.IMPORTANCE_LOW).apply {
            setSound(null, null)
            enableVibration(false)
            setShowBadge(false)
        }
        (context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager)
            .createNotificationChannel(channel)
    }

    fun build(context: Context): Notification {
        val p = prefs(context)
        val title = p.getString(KEY_TITLE, null).orEmpty().ifEmpty { "Muvik" }
        val desc = p.getString(KEY_DESC, "").orEmpty()
        val openLabel = p.getString(KEY_OPEN_LABEL, null) ?: "Open Muvik"

        // Every tap target (the card and the button) just opens the app.
        val open = openAppIntent(context)

        val small = RemoteViews(context.packageName, R.layout.noti_ongoing_small).apply {
            setTextViewText(R.id.tv_title, title)
            setTextViewText(R.id.tv_desc, desc)
            setTextViewText(R.id.tv_btn_open_small, openLabel)
            setOnClickPendingIntent(R.id.btn_open_small, open)
        }
        val large = RemoteViews(context.packageName, R.layout.noti_ongoing_large).apply {
            setTextViewText(R.id.tv_title, title)
            setTextViewText(R.id.tv_desc, desc)
            setTextViewText(R.id.tv_btn_open, openLabel)
            setOnClickPendingIntent(R.id.btn_open, open)
        }

        return NotificationCompat.Builder(context, CHANNEL)
            .setSmallIcon(R.drawable.ic_stat_muvik)
            .setCustomContentView(small)
            .setCustomBigContentView(large)
            .setStyle(NotificationCompat.DecoratedCustomViewStyle())
            .setOngoing(true)
            .setSilent(true)
            .setOnlyAlertOnce(true)
            .setShowWhen(false)
            .setCategory(NotificationCompat.CATEGORY_SERVICE)
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .setContentIntent(open)
            .build()
    }

    private fun openAppIntent(context: Context): PendingIntent {
        val launch = Intent(context, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
        }
        return PendingIntent.getActivity(
            context, REQ_OPEN, launch,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
    }
}

class OngoingService : Service() {

    companion object {
        private const val TAG = "OngoingService"
        private const val ACTION_START = "com.asctechsoft.muvik.ONGOING_START"
        private const val ACTION_STOP = "com.asctechsoft.muvik.ONGOING_STOP"

        fun start(context: Context) {
            val intent = Intent(context, OngoingService::class.java).setAction(ACTION_START)
            try {
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                    context.startForegroundService(intent)
                } else {
                    context.startService(intent)
                }
            } catch (e: Exception) {
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S &&
                    e is ForegroundServiceStartNotAllowedException
                ) {
                    // Started from the background (e.g. an alarm): the next
                    // time the app is in the foreground it will start again.
                    Log.w(TAG, "Cannot start foreground service from background", e)
                } else {
                    throw e
                }
            }
        }

        fun stop(context: Context) {
            context.stopService(Intent(context, OngoingService::class.java))
        }
    }

    private var lastNightMode = Configuration.UI_MODE_NIGHT_UNDEFINED

    override fun onCreate() {
        super.onCreate()
        lastNightMode = resources.configuration.uiMode and Configuration.UI_MODE_NIGHT_MASK
    }

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onConfigurationChanged(newConfig: Configuration) {
        super.onConfigurationChanged(newConfig)
        val night = newConfig.uiMode and Configuration.UI_MODE_NIGHT_MASK
        if (night == lastNightMode) return
        lastNightMode = night
        repost()
    }

    override fun onTaskRemoved(rootIntent: Intent?) {
        super.onTaskRemoved(rootIntent)
        if (OngoingNotification.isEnabled(this)) goForeground()
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        if (intent?.action == ACTION_STOP || !OngoingNotification.isEnabled(this)) {
            ServiceCompat.stopForeground(this, ServiceCompat.STOP_FOREGROUND_REMOVE)
            stopSelf()
            return START_NOT_STICKY
        }
        goForeground()
        return START_STICKY
    }

    private fun goForeground() {
        OngoingNotification.createChannel(this)
        val notification = OngoingNotification.build(this)
        try {
            ServiceCompat.startForeground(
                this,
                OngoingNotification.NOTIFICATION_ID,
                notification,
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE) {
                    ServiceInfo.FOREGROUND_SERVICE_TYPE_SPECIAL_USE
                } else {
                    0
                },
            )
        } catch (e: Exception) {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S &&
                e is ForegroundServiceStartNotAllowedException
            ) {
                Log.w(TAG, "Cannot promote to foreground from background", e)
                stopSelf()
            } else {
                throw e
            }
        }
    }

    private fun repost() {
        val manager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        manager.notify(OngoingNotification.NOTIFICATION_ID, OngoingNotification.build(this))
    }
}

/**
 * Some OEM skins and Android 14+ let the user swipe an ongoing notification
 * away; every 15 minutes this puts it back while the setting is on.
 */
class OngoingHealthCheckReceiver : BroadcastReceiver() {

    companion object {
        private const val REQUEST = 7315
        private const val INTERVAL_MS = 15 * 60 * 1000L

        fun schedule(context: Context) {
            val alarms = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
            val pending = pendingIntent(context)
            alarms.cancel(pending)
            alarms.setInexactRepeating(
                AlarmManager.RTC,
                System.currentTimeMillis() + INTERVAL_MS,
                INTERVAL_MS,
                pending,
            )
        }

        fun cancel(context: Context) {
            (context.getSystemService(Context.ALARM_SERVICE) as AlarmManager)
                .cancel(pendingIntent(context))
        }

        private fun pendingIntent(context: Context): PendingIntent =
            PendingIntent.getBroadcast(
                context, REQUEST,
                Intent(context, OngoingHealthCheckReceiver::class.java),
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
            )
    }

    override fun onReceive(context: Context, intent: Intent?) {
        if (!OngoingNotification.isEnabled(context)) {
            cancel(context)
            return
        }
        OngoingService.start(context)
    }
}
