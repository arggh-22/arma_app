package com.arma.vpn

import android.content.Context
import android.content.Intent
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel
import com.arma.vpn.ipc.VpnServiceConnection
import com.arma.vpn.service.ArmaVpnService

/**
 * Main activity bridging Flutter platform channels to the VPN process.
 *
 * Two-hop IPC pattern (from 02-RESEARCH.md):
 *   Flutter ↔ MainActivity (MethodChannel/EventChannel in main process)
 *          ↔ ArmaVpnService (Messenger in :vpn_process)
 *
 * Flutter CANNOT directly communicate with the VPN process — all commands
 * and events flow through this activity.
 *
 * MethodChannel "com.arma.vpn/method":
 *   - startVpn(config, serverName) → bool
 *   - stopVpn() → bool
 *   - isRunning() → bool
 *   - requestVpnPermission() → bool
 *
 * EventChannel "com.arma.vpn/vpn_status":
 *   - {"type": "status", "state": "connecting"|"connected"|"disconnected"|"error"}
 *   - {"type": "stats", "uplink": long, "downlink": long}
 */
class MainActivity : FlutterActivity() {

    private lateinit var methodChannel: MethodChannel
    private var eventSink: EventChannel.EventSink? = null
    private var vpnPermissionResult: MethodChannel.Result? = null
    private lateinit var vpnConnection: VpnServiceConnection
    private var isVpnActive = false

    companion object {
        private const val METHOD_CHANNEL = "com.arma.vpn/method"
        private const val EVENT_CHANNEL = "com.arma.vpn/vpn_status"
        private const val VPN_PERMISSION_REQUEST_CODE = 24
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // Initialize IPC bridge — events from VPN process forwarded to Flutter EventChannel
        vpnConnection = VpnServiceConnection { event ->
            runOnUiThread {
                // Track actual VPN running state from service events
                if (event["type"] == "status") {
                    isVpnActive = event["state"] == "connected" || event["state"] == "connecting"
                }
                eventSink?.success(event)
            }
        }

        // Bind to VPN service (but don't start it — just establish IPC channel)
        bindVpnService()

        // MethodChannel setup — Flutter → native commands
        methodChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, METHOD_CHANNEL)
        methodChannel.setMethodCallHandler { call, result ->
            when (call.method) {
                "startVpn" -> {
                    val config = call.argument<String>("config")
                    val serverName = call.argument<String>("serverName")
                    if (config == null || serverName == null) {
                        result.error("INVALID_ARGS", "config and serverName required", null)
                        return@setMethodCallHandler
                    }
                    startVpnService(config, serverName)
                    result.success(true)
                }
                "stopVpn" -> {
                    stopVpnService()
                    result.success(true)
                }
                "isRunning" -> {
                    // Return actual VPN state, not just Messenger binding state
                    result.success(isVpnActive)
                }
                "requestVpnPermission" -> {
                    requestVpnPermission(result)
                }
                else -> result.notImplemented()
            }
        }

        // EventChannel setup — native → Flutter streaming (status + stats)
        val eventChannel = EventChannel(flutterEngine.dartExecutor.binaryMessenger, EVENT_CHANNEL)
        eventChannel.setStreamHandler(object : EventChannel.StreamHandler {
            override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                eventSink = events
            }
            override fun onCancel(arguments: Any?) {
                eventSink = null
            }
        })
    }

    /**
     * Bind to the ArmaVpnService in the :vpn_process.
     * BIND_AUTO_CREATE starts the service process if not already running.
     */
    private fun bindVpnService() {
        val intent = Intent(this, ArmaVpnService::class.java)
        bindService(intent, vpnConnection.serviceConnection, Context.BIND_AUTO_CREATE)
    }

    /**
     * Start the VPN foreground service with the given config, then also
     * send start command via Messenger if already bound.
     */
    private fun startVpnService(config: String, serverName: String) {
        val intent = Intent(this, ArmaVpnService::class.java).apply {
            action = ArmaVpnService.ACTION_START
            putExtra(ArmaVpnService.EXTRA_CONFIG, config)
            putExtra(ArmaVpnService.EXTRA_SERVER_NAME, serverName)
        }
        startForegroundService(intent)
    }

    /**
     * Stop the VPN service via both Intent and Messenger for reliability.
     */
    private fun stopVpnService() {
        // Send stop via Messenger (fastest path if bound)
        vpnConnection.sendStop()
        // Also send stop Intent in case Messenger isn't connected
        val intent = Intent(this, ArmaVpnService::class.java).apply {
            action = ArmaVpnService.ACTION_STOP
        }
        startService(intent)
    }

    /**
     * Request VPN permission from the system.
     * If permission is already granted, returns true immediately.
     * Otherwise, launches the system VPN permission dialog.
     */
    private fun requestVpnPermission(result: MethodChannel.Result) {
        val intent = android.net.VpnService.prepare(this)
        if (intent != null) {
            vpnPermissionResult = result
            startActivityForResult(intent, VPN_PERMISSION_REQUEST_CODE)
        } else {
            result.success(true) // Already granted
        }
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        if (requestCode == VPN_PERMISSION_REQUEST_CODE) {
            vpnPermissionResult?.success(resultCode == RESULT_OK)
            vpnPermissionResult = null
            return
        }
        super.onActivityResult(requestCode, resultCode, data)
    }

    override fun onDestroy() {
        try {
            unbindService(vpnConnection.serviceConnection)
        } catch (e: Exception) {
            // Ignore — service may already be unbound
        }
        super.onDestroy()
    }
}
