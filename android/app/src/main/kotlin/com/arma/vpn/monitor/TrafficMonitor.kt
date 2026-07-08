package com.arma.vpn.monitor

import libv2ray.CoreController
import org.json.JSONObject
import java.util.Timer
import java.util.TimerTask

/**
 * Polls Xray-core QueryStats at 1-second intervals for real-time traffic monitoring.
 *
 * QueryStats returns cumulative bytes since last call and resets the counter,
 * so each poll returns the bytes transferred in that 1-second window (= bytes/sec).
 *
 * Traffic is summed across every proxy outbound tag, not just "proxy":
 * JSON-subscription "auto-select" profiles route through a balancer whose
 * selector `["proxy"]` prefix-matches `proxy`, `proxy-2`, `proxy-3`, … so on
 * those configs the live traffic flows through whichever outbound the balancer
 * picked. Querying only "proxy" then reads 0. The tag set is read from the
 * actual config's outbounds so any number of proxy-N outbounds is covered.
 *
 * The config must include `"stats": {}` and `"policy": {"system": {"statsOutboundUplink": true,
 * "statsOutboundDownlink": true}}` sections for QueryStats to return data (Pitfall #6).
 *
 * @param controller The active CoreController running the Xray-core loop
 * @param configJson The Xray config passed to startLoop, used to enumerate proxy outbound tags
 * @param onStats Callback invoked every second with (uplinkBytes, downlinkBytes)
 */
class TrafficMonitor(
    private val controller: CoreController,
    configJson: String?,
    private val onStats: (uplink: Long, downlink: Long) -> Unit
) {

    private var timer: Timer? = null

    /** Proxy outbound tags to aggregate, taken from the running config. */
    private val statsTags: List<String> = proxyTagsFrom(configJson)

    companion object {
        /**
         * Every outbound tag the balancer selector `["proxy"]` prefix-matches.
         * Falls back to just "proxy" (the tag app-built configs always use)
         * when the config is absent or unparseable.
         */
        fun proxyTagsFrom(configJson: String?): List<String> {
            val fallback = listOf("proxy")
            if (configJson == null) return fallback
            return try {
                val outbounds =
                    JSONObject(configJson).optJSONArray("outbounds") ?: return fallback
                val tags = (0 until outbounds.length())
                    .mapNotNull { outbounds.optJSONObject(it)?.optString("tag") }
                    .filter { it.startsWith("proxy") }
                tags.ifEmpty { fallback }
            } catch (_: Exception) {
                fallback
            }
        }
    }

    /** queryStats for one tag, treating a missing/errored counter as 0 so it
     *  can never abort the aggregate for the other tags. */
    private fun statFor(tag: String, direction: String): Long =
        try {
            controller.queryStats(tag, direction)
        } catch (_: Exception) {
            0L
        }

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
                        var up = 0L
                        var down = 0L
                        for (tag in statsTags) {
                            up += statFor(tag, "uplink")
                            down += statFor(tag, "downlink")
                        }
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
