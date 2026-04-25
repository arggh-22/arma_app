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
        const val MSG_DEBUG_LOG = 7
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
        Log.w(TAG, "=== onCreate() — VPN service created in :vpn_process ===")
        // Go runtime performs network operations during init (Pitfall #15)
        StrictMode.setThreadPolicy(StrictMode.ThreadPolicy.Builder().permitAll().build())
        VpnNotificationManager.createNotificationChannel(this)
        Log.w(TAG, "Initializing XrayCoreManager...")
        XrayCoreManager.initialize(this)
        Log.w(TAG, "XrayCoreManager initialized, Xray version: ${XrayCoreManager.getVersion()}")
    }

    override fun onBind(intent: Intent?): IBinder {
        Log.w(TAG, "onBind() — client binding to VPN service")
        return incomingMessenger.binder
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        Log.w(TAG, "onStartCommand() action=${intent?.action}, isRunning=$isRunning")
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
        Log.w(TAG, "=== startVpn() called, serverName=$serverName, isRunning=$isRunning ===")
        debugLog("startVpn called, serverName=$serverName, isRunning=$isRunning")

        // Clean up any leftover state from a previous session
        if (isRunning) {
            Log.w(TAG, "VPN still marked running, cleaning up first...")
            debugLog("Cleaning up previous session before reconnect")
            cleanupPreviousSession()
        } else {
            // Even if not "running", ensure no stale resources
            cleanupPreviousSession()
        }

        currentServerName = serverName
        isRunning = true

        // 1. Start foreground service with notification — must be within 5 seconds
        Log.w(TAG, "Step 1: Starting foreground notification")
        startForeground(
            VpnNotificationManager.NOTIFICATION_ID,
            VpnNotificationManager.buildNotification(
                this,
                "Connecting...",
                serverName,
                showDetails = isNotificationDetailsEnabled()
            )
        )

        // 2. Send connecting status to client
        Log.w(TAG, "Step 2: Sending 'connecting' status to client")
        sendStatusToClient("connecting")

        try {
            // 3. Configure TUN interface
            Log.w(TAG, "Step 3: Configuring TUN interface...")
            tunInterface = configureTunInterface()
            Log.w(TAG, "TUN configured: fd=${tunInterface!!.fd}")
            debugLog("TUN fd=${tunInterface!!.fd}")

            // 4. Create core callback — CRITICAL: must protect outbound sockets!
            val vpnService = this@ArmaVpnService
            val callback = object : CoreCallbackHandler {
                override fun onEmitStatus(p0: Long, p1: String?): Long {
                    Log.w(TAG, ">>> onEmitStatus(p0=$p0, p1='$p1') <<<")
                    debugLog("onEmitStatus: p0=$p0, p1=$p1")
                    // Protect outbound sockets from VPN routing loop
                    return if (p0 > 0) {
                        val protected = vpnService.protect(p0.toInt())
                        Log.w(TAG, "protect(fd=$p0) = $protected")
                        debugLog("protect(fd=$p0)=$protected")
                        if (protected) 0L else 1L
                    } else {
                        0L
                    }
                }
                override fun shutdown(): Long {
                    Log.w(TAG, ">>> Core shutdown callback <<<")
                    debugLog("Core shutdown callback")
                    return 0
                }
                override fun startup(): Long {
                    Log.w(TAG, ">>> Core startup callback <<<")
                    debugLog("Core startup callback")
                    return 0
                }
            }
            Log.w(TAG, "Step 4: Creating CoreController...")
            coreController = XrayCoreManager.createController(callback)
            Log.w(TAG, "CoreController created: $coreController")

            Log.w(TAG, "Step 5: Calling startLoop(config.length=${config.length}, tunFd=${tunInterface!!.fd})")
            Log.w(TAG, "=== FULL XRAY CONFIG START ===")
            // Log config in chunks (logcat has line length limits)
            config.chunked(1000).forEachIndexed { i, chunk ->
                Log.w(TAG, "CONFIG[$i]: $chunk")
            }
            Log.w(TAG, "=== FULL XRAY CONFIG END ===")
            debugLog("Calling startLoop, config.length=${config.length}, tunFd=${tunInterface!!.fd}")

            coreController?.startLoop(config, tunInterface!!.fd)

            val running = coreController?.isRunning ?: false
            Log.w(TAG, "Step 6: startLoop returned, isRunning=$running")
            debugLog("startLoop returned, isRunning=$running")

            if (!running) {
                throw IllegalStateException("Xray core failed to start — isRunning=false after startLoop")
            }

            // 7. Schedule delayed health check
            Handler(Looper.getMainLooper()).postDelayed({
                val stillRunning = coreController?.isRunning ?: false
                Log.w(TAG, "=== Health check (2s after start): isRunning=$stillRunning ===")
                debugLog("Health check 2s: isRunning=$stillRunning")
                try {
                    val upStats = coreController?.queryStats("proxy", "uplink") ?: -1
                    val downStats = coreController?.queryStats("proxy", "downlink") ?: -1
                    Log.w(TAG, "QueryStats: proxy uplink=$upStats, downlink=$downStats")
                    debugLog("QueryStats: up=$upStats, down=$downStats")
                } catch (e: Exception) {
                    Log.e(TAG, "QueryStats failed", e)
                    debugLog("QueryStats failed: ${e.message}")
                }
            }, 2000)

            // 8. Start traffic monitoring
            Log.w(TAG, "Step 7: Starting traffic monitor")
            trafficMonitor = TrafficMonitor(coreController!!) { up, down ->
                sendStatsToClient(up, down)
                updateNotification(serverName, up, down)
            }
            trafficMonitor?.start()

            // 9. Register network callback for auto-reconnect (D-10)
            Log.w(TAG, "Step 8: Registering network callback")
            registerNetworkCallback()

            // 10. Notify client of connected state
            Log.w(TAG, "Step 9: Sending 'connected' status to client")
            sendStatusToClient("connected")
            debugLog("VPN started successfully!")

        } catch (e: Exception) {
            Log.e(TAG, "!!! FAILED to start VPN !!!", e)
            debugLog("FAILED to start VPN: ${e.message}")
            debugLog("Stack: ${e.stackTraceToString().take(500)}")
            sendStatusToClient("error", e.message ?: "Failed to start VPN engine")
            isRunning = false
            trafficMonitor?.stop()
            trafficMonitor = null
            try { coreController?.stopLoop() } catch (_: Exception) {}
            coreController = null
            try { tunInterface?.close() } catch (_: Exception) {}
            tunInterface = null
            stopForeground(STOP_FOREGROUND_REMOVE)
        }
    }

    // =========================================================================
    // Cleanup — ensure no stale resources from previous session
    // =========================================================================

    /**
     * Cleanup any leftover resources from a previous VPN session.
     * Called at the start of startVpn to ensure clean state for reconnection.
     * The gVisor TCP/IP stack runs goroutines that may not stop instantly
     * when coreInstance.Close() is called, so we give it time.
     */
    private fun cleanupPreviousSession() {
        trafficMonitor?.stop()
        trafficMonitor = null

        if (coreController != null) {
            Log.w(TAG, "Cleaning up old CoreController...")
            try { coreController?.stopLoop() } catch (_: Exception) {}
            coreController = null
            // Give gVisor goroutines time to stop
            Thread.sleep(300)
        }

        unregisterNetworkCallback()

        if (tunInterface != null) {
            Log.w(TAG, "Closing old TUN interface...")
            try { tunInterface?.close() } catch (_: Exception) {}
            tunInterface = null
            // Give Android time to release VPN routing
            Thread.sleep(200)
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
        Log.w(TAG, "=== stopVpn() called, isRunning=$isRunning ===")
        debugLog("stopVpn called, isRunning=$isRunning")
        if (!isRunning) {
            Log.w(TAG, "stopVpn: already stopped, skipping")
            sendStatusToClient("disconnected")
            return
        }
        isRunning = false
        sendStatusToClient("disconnected")

        // D-09: Shutdown order is CRITICAL
        Log.w(TAG, "Stop step 1: Stopping traffic monitor")
        trafficMonitor?.stop()
        trafficMonitor = null

        Log.w(TAG, "Stop step 2: Stopping xray-core loop")
        try {
            coreController?.stopLoop()
            Log.w(TAG, "stopLoop completed")
        } catch (e: Exception) {
            Log.w(TAG, "Error stopping core", e)
        }
        coreController = null

        Log.w(TAG, "Stop step 3: Unregistering network callback")
        unregisterNetworkCallback()

        // Don't call stopSelf() — keep the service alive for fast reconnect.
        // The service is bound from MainActivity, so it stays alive anyway.
        // Just remove the foreground notification.
        Log.w(TAG, "Stop step 4: Removing foreground notification")
        stopForeground(STOP_FOREGROUND_REMOVE)

        Log.w(TAG, "Stop step 5: Closing TUN fd")
        try {
            tunInterface?.close()
            Log.w(TAG, "TUN closed")
        } catch (e: Exception) {
            Log.w(TAG, "Error closing TUN", e)
        }
        tunInterface = null
        Log.w(TAG, "=== stopVpn() complete ===")
        debugLog("stopVpn complete")
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
        Log.w(TAG, "configureTunInterface: building TUN...")
        val builder = Builder()
        builder.setMtu(9000)
        builder.addAddress("26.26.26.1", 30)
        builder.addRoute("0.0.0.0", 0)
        builder.addDnsServer("1.1.1.1")
        builder.addDnsServer("8.8.8.8")
        builder.addAddress("da26:2626::1", 126)
        builder.addRoute("::", 0)
        builder.setSession("Arma VPN")

        // Read per-app proxy config (Phase 4, D-04, ROUTE-04)
        val perAppPrefs = applicationContext.getSharedPreferences("per_app_config", MODE_PRIVATE)
        val perAppMode = perAppPrefs.getString("per_app_mode", null)
        val selectedApps = perAppPrefs.getStringSet("selected_apps", emptySet()) ?: emptySet()

        if (perAppMode == "whitelist" && selectedApps.isNotEmpty()) {
            // Whitelist mode: only selected apps route through VPN
            // Do NOT call addDisallowedApplication — can't mix with addAllowedApplication (Pitfall 3)
            // Self-exclusion is implicit: our app is not in the allowed list
            for (pkg in selectedApps) {
                try {
                    builder.addAllowedApplication(pkg)
                } catch (e: Exception) {
                    Log.w(TAG, "Skipping uninstalled whitelist app: $pkg")
                }
            }
            Log.w(TAG, "Per-app whitelist: ${selectedApps.size} apps allowed")
        } else {
            // Default or blacklist mode: all apps through VPN, exclude selected + self
            builder.addDisallowedApplication(packageName) // Self-exclusion (Pitfall #12)
            if (perAppMode == "blacklist" && selectedApps.isNotEmpty()) {
                for (pkg in selectedApps) {
                    if (pkg == packageName) continue // Already excluded
                    try {
                        builder.addDisallowedApplication(pkg)
                    } catch (e: Exception) {
                        Log.w(TAG, "Skipping uninstalled blacklist app: $pkg")
                    }
                }
                Log.w(TAG, "Per-app blacklist: ${selectedApps.size} apps excluded")
            }
        }

        Log.w(TAG, "TUN config: MTU=9000, addr=26.26.26.1/30, route=0.0.0.0/0, DNS=1.1.1.1+8.8.8.8, excl=$packageName")
        val iface = builder.establish()
            ?: throw IllegalStateException("VPN builder.establish() returned null")
        Log.w(TAG, "TUN established: fd=${iface.fd}")
        return iface
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
        Log.w(TAG, "sendStatusToClient: status=$status, message=$message, clientMessenger=${clientMessenger != null}")
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
     * Forward a debug log message from :vpn_process to the main process
     * via Messenger, so it appears in Flutter's EventChannel/logcat output.
     */
    private fun debugLog(message: String) {
        try {
            val msg = Message.obtain(null, MSG_DEBUG_LOG)
            msg.data = Bundle().apply {
                putString("log", message)
            }
            clientMessenger?.send(msg)
        } catch (_: Exception) {
            // Can't forward — client not connected yet. Native logcat still has it.
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
            this,
            "Connected",
            serverName,
            upStr,
            downStr,
            showDetails = isNotificationDetailsEnabled()
        )
        getSystemService(NotificationManager::class.java)
            .notify(VpnNotificationManager.NOTIFICATION_ID, notification)
    }

    private fun isNotificationDetailsEnabled(): Boolean {
        val prefs = getSharedPreferences("vpn_runtime_prefs", MODE_PRIVATE)
        return prefs.getBoolean("notification_details_enabled", true)
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
