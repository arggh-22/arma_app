package com.arma.vpn.service

import android.app.NotificationManager
import android.content.Intent
import android.net.ConnectivityManager
import android.net.Network
import android.net.NetworkCapabilities
import android.net.NetworkRequest
import android.net.VpnService
import android.os.Bundle
import android.os.Handler
import android.os.IBinder
import android.os.Looper
import android.os.Message
import android.os.Messenger
import android.os.ParcelFileDescriptor
import android.os.StrictMode
import android.util.Log
import libv2ray.CoreCallbackHandler
import libv2ray.CoreController
import com.arma.vpn.core.XrayCoreManager
import com.arma.vpn.notification.VpnNotificationManager
import com.arma.vpn.monitor.TrafficMonitor

/**
 * Android VpnService implementation for Arma VPN.
 *
 * Runs in the `:vpn_process` (separate from Flutter main process) per D-06.
 * Go panics in xray-core cannot crash the Flutter UI.
 *
 * Responsibilities:
 * - TUN interface creation with IPv4/IPv6 routes, MTU 9000, self-exclusion
 * - Xray-core lifecycle management (init, start, stop)
 * - Foreground notification with connection status and traffic speeds (D-07)
 * - Traffic monitoring via QueryStats polling (MON-03)
 * - Network resilience via ConnectivityManager callback (D-10, MON-04)
 * - Messenger-based IPC for cross-process communication with main process
 * - Proper shutdown order per D-09: stopLoop → stopSelf → close TUN fd
 */
class ArmaVpnService : VpnService() {

    companion object {
        const val ACTION_START = "com.arma.vpn.START"
        const val ACTION_STOP = "com.arma.vpn.STOP"
        const val EXTRA_CONFIG = "config"
        const val EXTRA_SERVER_NAME = "server_name"
        const val MSG_REGISTER_CLIENT = 1
        const val MSG_VPN_STATUS = 2
        const val MSG_TRAFFIC_STATS = 3
        const val MSG_COMMAND_START = 4
        const val MSG_COMMAND_STOP = 5
        const val MSG_IS_RUNNING = 6
        private const val TAG = "ArmaVpnService"
    }

    // --- State fields ---
    private var tunInterface: ParcelFileDescriptor? = null
    private var coreController: CoreController? = null
    private var trafficMonitor: TrafficMonitor? = null
    private var currentServerName: String = ""
    private var isRunning = false
    private var lastStatus: String = "disconnected"
    private var clientMessenger: Messenger? = null
    private val incomingMessenger = Messenger(IncomingHandler())

    // --- Network callback for auto-reconnect (D-10, MON-04) ---
    private var networkCallback: ConnectivityManager.NetworkCallback? = null

    // =========================================================================
    // Messenger IPC — handles messages from main process
    // =========================================================================

    /**
     * Handles incoming messages from the main process via Messenger IPC.
     *
     * Supported messages:
     * - MSG_REGISTER_CLIENT: Register the client's reply Messenger
     * - MSG_COMMAND_START: Start VPN with config JSON and server name
     * - MSG_COMMAND_STOP: Stop VPN
     * - MSG_IS_RUNNING: Query running state, replies with boolean
     */
    private inner class IncomingHandler : Handler(Looper.getMainLooper()) {
        override fun handleMessage(msg: Message) {
            when (msg.what) {
                MSG_REGISTER_CLIENT -> {
                    clientMessenger = msg.replyTo
                    // Send current status immediately so Flutter gets synced state
                    sendStatusToClient(lastStatus)
                }
                MSG_COMMAND_START -> {
                    val config = msg.data.getString("config") ?: return
                    val serverName = msg.data.getString("serverName") ?: "Unknown"
                    startVpn(config, serverName)
                }
                MSG_COMMAND_STOP -> stopVpn()
                MSG_IS_RUNNING -> {
                    val reply = Message.obtain(null, MSG_IS_RUNNING)
                    reply.data = Bundle().apply { putBoolean("running", isRunning) }
                    msg.replyTo?.send(reply)
                }
                else -> super.handleMessage(msg)
            }
        }
    }

    // =========================================================================
    // Service lifecycle
    // =========================================================================

    override fun onCreate() {
        super.onCreate()
        // Go runtime performs network operations during init (Pitfall #15)
        StrictMode.setThreadPolicy(StrictMode.ThreadPolicy.Builder().permitAll().build())
        VpnNotificationManager.createNotificationChannel(this)
        XrayCoreManager.initialize(this)
    }

    override fun onBind(intent: Intent?): IBinder {
        return incomingMessenger.binder
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        when (intent?.action) {
            ACTION_START -> {
                val config = intent.getStringExtra(EXTRA_CONFIG) ?: return START_NOT_STICKY
                val serverName = intent.getStringExtra(EXTRA_SERVER_NAME) ?: "Unknown"
                startVpn(config, serverName)
            }
            ACTION_STOP -> stopVpn()
        }
        return START_STICKY
    }

    override fun onRevoke() {
        // System revoked VPN permission (e.g., another VPN app started)
        stopVpn()
        super.onRevoke()
    }

    // =========================================================================
    // VPN start — TUN + core + monitor + notification + network callback
    // =========================================================================

    /**
     * Start the VPN connection.
     *
     * Order:
     * 1. Start foreground service with notification
     * 2. Configure TUN interface
     * 3. Create and start Xray-core loop
     * 4. Start traffic monitor
     * 5. Register network callback for auto-reconnect
     * 6. Notify client of connected state
     */
    private fun startVpn(config: String, serverName: String) {
        if (isRunning) {
            Log.w(TAG, "VPN already running, ignoring duplicate start")
            return
        }
        currentServerName = serverName
        isRunning = true

        // 1. Start foreground service with notification — must be within 5 seconds
        startForeground(
            VpnNotificationManager.NOTIFICATION_ID,
            VpnNotificationManager.buildNotification(this, "Connecting...", serverName)
        )

        // 2. Send connecting status to client
        sendStatusToClient("connecting")

        try {
            // 3. Configure TUN interface
            tunInterface = configureTunInterface()

            // 4. Create core callback — CRITICAL: must protect outbound sockets!
            // When Xray-core creates an outbound connection, it calls onEmitStatus
            // with the socket fd. We MUST call VpnService.protect(fd) to exclude
            // that socket from TUN routing, otherwise traffic loops:
            // Xray outbound → TUN → back to Xray → infinite loop → no internet.
            val vpnService = this@ArmaVpnService
            val callback = object : CoreCallbackHandler {
                override fun onEmitStatus(p0: Long, p1: String?): Long {
                    Log.d(TAG, "Core status: code=$p0, msg=$p1")
                    // Protect outbound sockets from VPN routing loop
                    return if (p0 > 0) {
                        val protected = vpnService.protect(p0.toInt())
                        Log.d(TAG, "protect(fd=$p0) = $protected")
                        if (protected) 0L else 1L
                    } else {
                        0L
                    }
                }
                override fun shutdown(): Long {
                    Log.d(TAG, "Core shutdown callback")
                    return 0
                }
                override fun startup(): Long {
                    Log.d(TAG, "Core startup callback")
                    return 0
                }
            }
            coreController = XrayCoreManager.createController(callback)
            Log.i(TAG, "Starting Xray loop with TUN fd=${tunInterface!!.fd}, config length=${config.length}")
            Log.i(TAG, "Xray config (first 500 chars): ${config.take(500)}")
            coreController?.startLoop(config, tunInterface!!.fd)
            Log.i(TAG, "Xray startLoop returned successfully, isRunning=${coreController?.isRunning}")

            // 5. Start traffic monitoring — polls QueryStats every 1 second
            trafficMonitor = TrafficMonitor(coreController!!) { up, down ->
                sendStatsToClient(up, down)
                updateNotification(serverName, up, down)
            }
            trafficMonitor?.start()

            // 6. Register network callback for auto-reconnect (D-10)
            registerNetworkCallback()

            // 7. Notify client of connected state
            sendStatusToClient("connected")

        } catch (e: Exception) {
            Log.e(TAG, "Failed to start VPN", e)
            sendStatusToClient("error", e.message ?: "Failed to start VPN engine")
            isRunning = false
            // Clean up partial state
            trafficMonitor?.stop()
            trafficMonitor = null
            try { coreController?.stopLoop() } catch (_: Exception) {}
            coreController = null
            try { tunInterface?.close() } catch (_: Exception) {}
            tunInterface = null
            stopSelf()
        }
    }

    // =========================================================================
    // VPN stop — D-09 shutdown order is CRITICAL
    // =========================================================================

    /**
     * Stop the VPN connection.
     *
     * D-09 shutdown order (from CONTEXT.md / Research Pitfall #1):
     * 1. Stop traffic monitoring
     * 2. Stop xray-core loop FIRST
     * 3. Unregister network callback
     * 4. Stop the Android service (stopSelf)
     * 5. LAST: close the TUN file descriptor
     *
     * NEVER close TUN fd before stopSelf() — causes port-in-use errors on reconnect.
     */
    private fun stopVpn() {
        isRunning = false
        sendStatusToClient("disconnected")

        // D-09: Shutdown order is CRITICAL
        // 1. Stop traffic monitoring
        trafficMonitor?.stop()
        trafficMonitor = null

        // 2. Stop xray-core loop FIRST
        try {
            coreController?.stopLoop()
        } catch (e: Exception) {
            Log.w(TAG, "Error stopping core", e)
        }
        coreController = null

        // 3. Unregister network callback
        unregisterNetworkCallback()

        // 4. Stop the Android service (calls onDestroy)
        stopSelf()

        // 5. LAST: close the TUN file descriptor
        try {
            tunInterface?.close()
        } catch (e: Exception) {
            Log.w(TAG, "Error closing TUN", e)
        }
        tunInterface = null
    }

    // =========================================================================
    // TUN interface configuration
    // =========================================================================

    /**
     * Configure the TUN network interface.
     *
     * - MTU 9000 for optimal throughput
     * - IPv4: 26.26.26.1/30 with default route (0.0.0.0/0)
     * - IPv6: da26:2626::1/126 with default route (::/0) — prevents IPv6 leakage (Pitfall #21)
     * - DNS: Cloudflare 1.1.1.1 + Google 8.8.8.8
     * - Self-exclusion: addDisallowedApplication(packageName) prevents routing loop (Pitfall #12)
     *
     * @return ParcelFileDescriptor for the TUN interface
     * @throws IllegalStateException if builder.establish() returns null
     */
    private fun configureTunInterface(): ParcelFileDescriptor {
        val builder = Builder()
        builder.setMtu(9000)
        builder.addAddress("26.26.26.1", 30)
        builder.addRoute("0.0.0.0", 0)
        builder.addDnsServer("1.1.1.1")
        builder.addDnsServer("8.8.8.8")
        // IPv6 — prevent leakage (Pitfall #21)
        builder.addAddress("da26:2626::1", 126)
        builder.addRoute("::", 0)
        builder.setSession("Arma VPN")
        // CRITICAL: Exclude self to prevent routing loop (Pitfall #12)
        builder.addDisallowedApplication(packageName)
        return builder.establish()
            ?: throw IllegalStateException("VPN builder.establish() returned null")
    }

    // =========================================================================
    // Network callback — auto-reconnect on WiFi ↔ cellular (D-10, MON-04)
    // =========================================================================

    /**
     * Register a network callback to detect network changes (WiFi ↔ cellular).
     *
     * Uses requestNetwork with NET_CAPABILITY_NOT_VPN — NOT registerDefaultNetworkCallback.
     * The default callback returns the VPN interface itself, creating a loop (Pitfall #9).
     *
     * On network change, calls setUnderlyingNetworks() to update the VPN's
     * underlying physical network, enabling seamless handover.
     */
    private fun registerNetworkCallback() {
        val cm = getSystemService(ConnectivityManager::class.java)
        val request = NetworkRequest.Builder()
            .addCapability(NetworkCapabilities.NET_CAPABILITY_INTERNET)
            .addCapability(NetworkCapabilities.NET_CAPABILITY_NOT_VPN)  // CRITICAL: exclude VPN itself!
            .build()
        networkCallback = object : ConnectivityManager.NetworkCallback() {
            override fun onAvailable(network: Network) {
                setUnderlyingNetworks(arrayOf(network))
            }
            override fun onCapabilitiesChanged(network: Network, caps: NetworkCapabilities) {
                setUnderlyingNetworks(arrayOf(network))
            }
            override fun onLost(network: Network) {
                setUnderlyingNetworks(null)
            }
        }
        cm.requestNetwork(request, networkCallback!!)
    }

    /**
     * Unregister the network callback. Safe to call even if not registered.
     */
    private fun unregisterNetworkCallback() {
        networkCallback?.let {
            try {
                getSystemService(ConnectivityManager::class.java).unregisterNetworkCallback(it)
            } catch (e: Exception) {
                Log.w(TAG, "Error unregistering network callback", e)
            }
        }
        networkCallback = null
    }

    // =========================================================================
    // IPC helper methods — send status/stats to main process via Messenger
    // =========================================================================

    /**
     * Send connection status to the main process client.
     *
     * @param status One of: "connecting", "connected", "disconnected", "error"
     * @param message Optional error message (for "error" status)
     */
    private fun sendStatusToClient(status: String, message: String? = null) {
        lastStatus = status
        try {
            val msg = Message.obtain(null, MSG_VPN_STATUS)
            msg.data = Bundle().apply {
                putString("status", status)
                if (message != null) putString("message", message)
            }
            clientMessenger?.send(msg)
        } catch (e: Exception) {
            Log.w(TAG, "Failed to send status", e)
        }
    }

    /**
     * Send traffic stats to the main process client.
     *
     * @param uplink Bytes uploaded in the last polling interval
     * @param downlink Bytes downloaded in the last polling interval
     */
    private fun sendStatsToClient(uplink: Long, downlink: Long) {
        try {
            val msg = Message.obtain(null, MSG_TRAFFIC_STATS)
            msg.data = Bundle().apply {
                putLong("uplink", uplink)
                putLong("downlink", downlink)
            }
            clientMessenger?.send(msg)
        } catch (e: Exception) {
            Log.w(TAG, "Failed to send stats", e)
        }
    }

    // =========================================================================
    // Notification updates
    // =========================================================================

    /**
     * Update the foreground notification with current traffic speeds.
     */
    private fun updateNotification(serverName: String, uplink: Long, downlink: Long) {
        val upStr = formatSpeed(uplink)
        val downStr = formatSpeed(downlink)
        val notification = VpnNotificationManager.buildNotification(
            this, "Connected", serverName, upStr, downStr
        )
        getSystemService(NotificationManager::class.java)
            .notify(VpnNotificationManager.NOTIFICATION_ID, notification)
    }

    /**
     * Format bytes per second into a human-readable speed string.
     */
    private fun formatSpeed(bytesPerSecond: Long): String {
        return when {
            bytesPerSecond < 1024 -> "$bytesPerSecond B/s"
            bytesPerSecond < 1024 * 1024 ->
                "${"%.1f".format(bytesPerSecond / 1024.0)} KB/s"
            bytesPerSecond < 1024 * 1024 * 1024 ->
                "${"%.1f".format(bytesPerSecond / (1024.0 * 1024))} MB/s"
            else ->
                "${"%.1f".format(bytesPerSecond / (1024.0 * 1024 * 1024))} GB/s"
        }
    }
}
