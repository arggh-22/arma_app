package com.arma.vpn.monitor

import libv2ray.CoreController
import java.util.Timer
import java.util.TimerTask

/**
 * Polls Xray-core QueryStats at 1-second intervals for real-time traffic monitoring.
 *
 * QueryStats returns cumulative bytes since last call and resets the counter,
 * so each poll returns the bytes transferred in that 1-second window (= bytes/sec).
 *
 * The tag "proxy" must match the outbound tag in the Xray JSON config.
 * The config must include `"stats": {}` and `"policy": {"system": {"statsOutboundUplink": true,
 * "statsOutboundDownlink": true}}` sections for QueryStats to return data (Pitfall #6).
 *
 * @param controller The active CoreController running the Xray-core loop
 * @param onStats Callback invoked every second with (uplinkBytes, downlinkBytes)
 */
class TrafficMonitor(
    private val controller: CoreController,
    private val onStats: (uplink: Long, downlink: Long) -> Unit
) {

    private var timer: Timer? = null

    /**
     * Start polling QueryStats every 1 second.
     * Safe to call multiple times — previous timer is cancelled first.
     */
    fun start() {
        stop()
        timer = Timer().apply {
            scheduleAtFixedRate(object : TimerTask() {
                override fun run() {
                    try {
                        val up = controller.queryStats("proxy", "uplink")
                        val down = controller.queryStats("proxy", "downlink")
                        onStats(up, down)
                    } catch (e: Exception) {
                        // Core might be shutting down — ignore
                    }
                }
            }, 0L, 1000L)  // Every 1 second
        }
    }

    /**
     * Stop polling. Safe to call even if not started.
     */
    fun stop() {
        timer?.cancel()
        timer = null
    }
}
