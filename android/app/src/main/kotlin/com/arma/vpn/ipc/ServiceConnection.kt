package com.arma.vpn.ipc

import android.content.ComponentName
import android.os.Bundle
import android.os.Handler
import android.os.IBinder
import android.os.Looper
import android.os.Message
import android.os.Messenger
import android.util.Log
import com.arma.vpn.service.ArmaVpnService

/**
 * Messenger-based IPC bridge between the main process (Flutter/MainActivity)
 * and the VPN process (ArmaVpnService).
 *
 * Handles:
 * - Binding to ArmaVpnService via ServiceConnection
 * - Registering as reply target for status/stats messages
 * - Sending start/stop commands via Messenger
 * - Querying running state
 *
 * @param onStatusUpdate Callback invoked on the main thread with event maps
 *   containing "type" ("status", "stats", "isRunning") and associated data.
 */
class VpnServiceConnection(
    private val onStatusUpdate: (Map<String, Any>) -> Unit
) {
    private var vpnServiceMessenger: Messenger? = null

    private val incomingHandler = Handler(Looper.getMainLooper()) { msg ->
        when (msg.what) {
            ArmaVpnService.MSG_VPN_STATUS -> {
                val status = msg.data.getString("status") ?: "disconnected"
                Log.w("VpnServiceConnection", "IPC received: status=$status")
                onStatusUpdate(mapOf("type" to "status", "state" to status))
            }
            ArmaVpnService.MSG_TRAFFIC_STATS -> {
                val up = msg.data.getLong("uplink", 0)
                val down = msg.data.getLong("downlink", 0)
                onStatusUpdate(mapOf("type" to "stats", "uplink" to up, "downlink" to down))
            }
            ArmaVpnService.MSG_IS_RUNNING -> {
                val running = msg.data.getBoolean("running", false)
                Log.w("VpnServiceConnection", "IPC received: isRunning=$running")
                onStatusUpdate(mapOf("type" to "isRunning", "running" to running))
            }
            ArmaVpnService.MSG_DEBUG_LOG -> {
                val logMsg = msg.data.getString("log") ?: ""
                Log.w("VpnProcess", "[VPN] $logMsg")
                onStatusUpdate(mapOf("type" to "debug", "message" to logMsg))
            }
        }
        true
    }

    val serviceConnection = object : android.content.ServiceConnection {
        override fun onServiceConnected(name: ComponentName?, service: IBinder?) {
            vpnServiceMessenger = Messenger(service)
            // Register this process as reply target
            val msg = Message.obtain(null, ArmaVpnService.MSG_REGISTER_CLIENT)
            msg.replyTo = Messenger(incomingHandler)
            vpnServiceMessenger?.send(msg)
        }

        override fun onServiceDisconnected(name: ComponentName?) {
            vpnServiceMessenger = null
        }
    }

    /** Whether the service is currently bound and the Messenger is available. */
    val isConnected: Boolean get() = vpnServiceMessenger != null

    /**
     * Send a start command to the VPN service with config JSON and server name.
     */
    fun sendStart(config: String, serverName: String) {
        val msg = Message.obtain(null, ArmaVpnService.MSG_COMMAND_START)
        msg.data = Bundle().apply {
            putString("config", config)
            putString("serverName", serverName)
        }
        vpnServiceMessenger?.send(msg)
    }

    /**
     * Send a stop command to the VPN service.
     */
    fun sendStop() {
        val msg = Message.obtain(null, ArmaVpnService.MSG_COMMAND_STOP)
        vpnServiceMessenger?.send(msg)
    }

    /**
     * Query the VPN service running state. Response arrives via [onStatusUpdate]
     * with type "isRunning".
     */
    fun queryIsRunning(replyTo: Messenger) {
        val msg = Message.obtain(null, ArmaVpnService.MSG_IS_RUNNING)
        msg.replyTo = replyTo
        vpnServiceMessenger?.send(msg)
    }
}
