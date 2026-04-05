package com.arma.vpn

import android.content.Context
import android.content.Intent
import android.content.pm.ApplicationInfo
import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.drawable.BitmapDrawable
import android.os.Bundle
import android.util.Base64
import android.util.Log
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel
import kotlinx.coroutines.*
import com.arma.vpn.ipc.VpnServiceConnection
import com.arma.vpn.service.ArmaVpnService
import java.io.ByteArrayOutputStream

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
        private const val TAG = "ArmaMainActivity"
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        Log.w(TAG, "configureFlutterEngine — setting up channels")

        // Initialize IPC bridge — events from VPN process forwarded to Flutter EventChannel
        vpnConnection = VpnServiceConnection { event ->
            runOnUiThread {
                if (event["type"] == "status") {
                    isVpnActive = event["state"] == "connected" || event["state"] == "connecting"
                    Log.w(TAG, "VPN status event: state=${event["state"]}, isVpnActive=$isVpnActive")
                }
                if (event["type"] == "debug") {
                    Log.w(TAG, "[VPN-DEBUG] ${event["message"]}")
                }
                eventSink?.success(event)
            }
        }

        bindVpnService()
        Log.w(TAG, "VPN service bind initiated")

        methodChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, METHOD_CHANNEL)
        methodChannel.setMethodCallHandler { call, result ->
            Log.w(TAG, "MethodChannel call: ${call.method}")
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
                    // Return actual VPN state — check lastKnownStatus from service too
                    val running = isVpnActive ||
                        vpnConnection.lastKnownStatus == "connected" ||
                        vpnConnection.lastKnownStatus == "connecting"
                    result.success(running)
                }
                "requestVpnPermission" -> {
                    requestVpnPermission(result)
                }
                "measureDelay" -> {
                    val config = call.argument<String>("config")
                    val url = call.argument<String>("url") ?: "https://www.google.com/generate_204"
                    if (config == null) {
                        result.error("INVALID_ARGS", "config required", null)
                        return@setMethodCallHandler
                    }
                    Log.w(TAG, "measureDelay — url=$url, config.length=${config.length}")
                    CoroutineScope(Dispatchers.IO).launch {
                        try {
                            val delay = libv2ray.Libv2ray.measureOutboundDelay(config, url)
                            Log.w(TAG, "measureDelay result: ${delay}ms")
                            withContext(Dispatchers.Main) {
                                result.success(delay)
                            }
                        } catch (e: Exception) {
                            Log.e(TAG, "measureDelay error: ${e.message}")
                            withContext(Dispatchers.Main) {
                                result.error("MEASURE_FAILED", e.message, null)
                            }
                        }
                    }
                }
                "getInstalledApps" -> {
                    CoroutineScope(Dispatchers.IO).launch {
                        try {
                            val pm = applicationContext.packageManager
                            val apps = pm.getInstalledApplications(0)
                                .filter { it.flags and ApplicationInfo.FLAG_SYSTEM == 0 }
                                .map { appInfo ->
                                    val iconBase64 = try {
                                        val drawable = pm.getApplicationIcon(appInfo)
                                        val bitmap = if (drawable is BitmapDrawable) {
                                            drawable.bitmap
                                        } else {
                                            val bmp = Bitmap.createBitmap(48, 48, Bitmap.Config.ARGB_8888)
                                            val canvas = Canvas(bmp)
                                            drawable.setBounds(0, 0, 48, 48)
                                            drawable.draw(canvas)
                                            bmp
                                        }
                                        val stream = ByteArrayOutputStream()
                                        bitmap.compress(Bitmap.CompressFormat.PNG, 80, stream)
                                        Base64.encodeToString(stream.toByteArray(), Base64.NO_WRAP)
                                    } catch (e: Exception) {
                                        ""
                                    }
                                    mapOf(
                                        "packageName" to appInfo.packageName,
                                        "appName" to (pm.getApplicationLabel(appInfo)?.toString() ?: appInfo.packageName),
                                        "icon" to iconBase64
                                    )
                                }
                                .sortedBy { (it["appName"] as String).lowercase() }
                            withContext(Dispatchers.Main) {
                                result.success(apps)
                            }
                        } catch (e: Exception) {
                            withContext(Dispatchers.Main) {
                                result.error("APP_LIST_FAILED", e.message, null)
                            }
                        }
                    }
                }
                "setPerAppConfig" -> {
                    val mode = call.argument<String>("mode")
                    val apps = call.argument<List<String>>("selectedApps") ?: emptyList()
                    val prefs = getSharedPreferences("per_app_config", MODE_PRIVATE)
                    prefs.edit()
                        .putString("per_app_mode", mode)
                        .putStringSet("selected_apps", apps.toSet())
                        .apply()
                    Log.w(TAG, "setPerAppConfig: mode=$mode, apps=${apps.size}")
                    result.success(true)
                }
                else -> result.notImplemented()
            }
        }

        // EventChannel setup — native → Flutter streaming (status + stats)
        val eventChannel = EventChannel(flutterEngine.dartExecutor.binaryMessenger, EVENT_CHANNEL)
        eventChannel.setStreamHandler(object : EventChannel.StreamHandler {
            override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                eventSink = events
                // If VPN status was already received from the service (e.g., app killed
                // and reopened while VPN was running), replay it immediately so Dart
                // gets the correct initial state.
                vpnConnection.lastKnownStatus?.let { status ->
                    Log.w(TAG, "EventChannel.onListen: replaying lastKnownStatus=$status")
                    isVpnActive = status == "connected" || status == "connecting"
                    events?.success(mapOf("type" to "status", "state" to status))
                }
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
     * Stop the VPN service via Messenger.
     *
     * Only uses Messenger (not Intent) to avoid race condition: a queued
     * Intent STOP can arrive after a subsequent Intent START, killing
     * the reconnection. Messenger delivery is immediate and synchronous.
     */
    private fun stopVpnService() {
        vpnConnection.sendStop()
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
