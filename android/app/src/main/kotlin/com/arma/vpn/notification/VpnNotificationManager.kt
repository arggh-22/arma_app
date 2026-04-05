package com.arma.vpn.notification

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import androidx.core.app.NotificationCompat
import com.arma.vpn.R

/**
 * Manages the foreground service notification for ArmaVpnService.
 *
 * Handles:
 * - Notification channel creation (IMPORTANCE_LOW — no sound on speed updates)
 * - Building persistent notification showing connection status, server name, and traffic speeds
 * - Notification updates with real-time upload/download speeds
 *
 * Per D-07: Foreground notification shows connection status, server name, upload/download speeds.
 * Tapping the notification opens the app.
 */
object VpnNotificationManager {

    const val CHANNEL_ID = "arma_vpn_service"
    const val NOTIFICATION_ID = 1

    /**
     * Create the notification channel. Must be called before building any notification.
     * Safe to call multiple times — Android ignores duplicate channel creation.
     */
    fun createNotificationChannel(context: Context) {
        val channel = NotificationChannel(
            CHANNEL_ID,
            "VPN Service",
            NotificationManager.IMPORTANCE_LOW  // No sound on speed updates
        ).apply {
            description = "Shows VPN connection status"
            setShowBadge(false)
        }
        context.getSystemService(NotificationManager::class.java)
            .createNotificationChannel(channel)
    }

    /**
     * Build a foreground service notification.
     *
     * @param context Android context
     * @param status Connection status text (e.g., "Connecting...", "Connected")
     * @param serverName Name of the connected server
     * @param uploadSpeed Formatted upload speed (e.g., "1.2 MB/s"), empty if not connected
     * @param downloadSpeed Formatted download speed (e.g., "3.4 MB/s"), empty if not connected
     * @return Built [Notification] ready for startForeground() or NotificationManager.notify()
     */
    fun buildNotification(
        context: Context,
        status: String,
        serverName: String,
        uploadSpeed: String = "",
        downloadSpeed: String = ""
    ): Notification {
        val pendingIntent = PendingIntent.getActivity(
            context, 0,
            context.packageManager.getLaunchIntentForPackage(context.packageName),
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        val contentText = if (uploadSpeed.isNotEmpty()) {
            "↓ $downloadSpeed  ↑ $uploadSpeed"
        } else {
            status
        }

        return NotificationCompat.Builder(context, CHANNEL_ID)
            .setSmallIcon(R.drawable.ic_vpn_key)
            .setContentTitle("Arma VPN — $serverName")
            .setContentText(contentText)
            .setContentIntent(pendingIntent)
            .setOngoing(true)
            .setSilent(true)
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .setCategory(NotificationCompat.CATEGORY_SERVICE)
            .build()
    }
}
