package com.asctechsoft.muvik

import android.app.AlarmManager
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Build
import androidx.core.app.NotificationCompat
import java.util.Calendar

/**
 * One gentle "come back and listen" notification a day at most. The alarm is
 * re-armed for tomorrow every time the app is opened, so it only ever fires
 * for someone who has not listened that day, and it gives up after
 * [MAX_UNANSWERED] ignored nudges. The user can switch it off in Settings.
 */
object NudgeScheduler {
    const val CHANNEL = "com.asctechsoft.muvik.nudge"
    private const val PREFS = "muvik_nudge"
    private const val KEY_TITLE = "title"
    private const val KEY_BODY = "body"
    private const val KEY_HOUR = "hour"
    private const val KEY_SENT = "sent"
    private const val REQUEST = 7301
    private const val NOTIFICATION_ID = 7302
    private const val MAX_UNANSWERED = 3

    fun schedule(context: Context, hour: Int, title: String, body: String) {
        val prefs = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
        prefs.edit()
            .putString(KEY_TITLE, title)
            .putString(KEY_BODY, body)
            .putInt(KEY_HOUR, hour)
            .putInt(KEY_SENT, 0)
            .apply()
        arm(context, hour, daysAhead = 1)
    }

    fun cancel(context: Context) {
        alarmManager(context).cancel(pendingIntent(context))
        context.getSharedPreferences(PREFS, Context.MODE_PRIVATE).edit().clear().apply()
    }

    /** Re-arms after a reboot, if a nudge was configured. */
    fun restore(context: Context) {
        val prefs = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
        if (prefs.getString(KEY_TITLE, null) == null) return
        if (prefs.getInt(KEY_SENT, 0) >= MAX_UNANSWERED) return
        arm(context, prefs.getInt(KEY_HOUR, 19), daysAhead = 0)
    }

    internal fun fire(context: Context) {
        val prefs = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
        val title = prefs.getString(KEY_TITLE, null) ?: return
        val body = prefs.getString(KEY_BODY, "") ?: ""
        val sent = prefs.getInt(KEY_SENT, 0)
        if (sent >= MAX_UNANSWERED) return

        val manager = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            manager.createNotificationChannel(
                NotificationChannel(CHANNEL, "Reminders", NotificationManager.IMPORTANCE_DEFAULT),
            )
        }
        val launch = context.packageManager.getLaunchIntentForPackage(context.packageName)
        val open = PendingIntent.getActivity(
            context, 0, launch,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
        val notification = NotificationCompat.Builder(context, CHANNEL)
            .setSmallIcon(R.drawable.ic_stat_muvik)
            .setContentTitle(title)
            .setContentText(body)
            .setStyle(NotificationCompat.BigTextStyle().bigText(body))
            .setContentIntent(open)
            .setAutoCancel(true)
            .build()
        try {
            manager.notify(NOTIFICATION_ID, notification)
        } catch (_: SecurityException) {
            // Notification permission refused: nothing to show.
        }

        prefs.edit().putInt(KEY_SENT, sent + 1).apply()
        if (sent + 1 < MAX_UNANSWERED) arm(context, prefs.getInt(KEY_HOUR, 19), daysAhead = 1)
    }

    private fun arm(context: Context, hour: Int, daysAhead: Int) {
        val at = Calendar.getInstance().apply {
            add(Calendar.DAY_OF_YEAR, daysAhead)
            set(Calendar.HOUR_OF_DAY, hour)
            set(Calendar.MINUTE, 0)
            set(Calendar.SECOND, 0)
            set(Calendar.MILLISECOND, 0)
            if (timeInMillis <= System.currentTimeMillis()) add(Calendar.DAY_OF_YEAR, 1)
        }
        // Inexact on purpose: no exact-alarm permission needed.
        alarmManager(context).setAndAllowWhileIdle(
            AlarmManager.RTC, at.timeInMillis, pendingIntent(context),
        )
    }

    private fun alarmManager(context: Context) =
        context.getSystemService(Context.ALARM_SERVICE) as AlarmManager

    private fun pendingIntent(context: Context): PendingIntent =
        PendingIntent.getBroadcast(
            context, REQUEST,
            Intent(context, NudgeReceiver::class.java),
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
}

class NudgeReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        when (intent.action) {
            Intent.ACTION_BOOT_COMPLETED -> {
                NudgeScheduler.restore(context)
                if (OngoingNotification.isEnabled(context)) {
                    OngoingService.start(context)
                    OngoingHealthCheckReceiver.schedule(context)
                }
            }
            else -> NudgeScheduler.fire(context)
        }
    }
}
