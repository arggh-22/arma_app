import 'package:flutter/material.dart';

import 'package:arma_proxy_vpn_client/core/theme/app_theme.dart';

/// Sentinel latency codes shared with [LatencyNotifier] state.
const int kLatencyTesting = -2;
const int kLatencyFailed = -1;

/// Anything slower than this (or a failure) is treated as unreachable (§3/§4.3).
const int kLatencyTimeoutMs = 600;

/// Latency quality bands and their colour coding, per the Health Check spec §3:
/// 🟢 0–120 ms · 🟡 121–250 ms · 🔴 251–600 ms · ❌ 600+ ms / error.
enum LatencyLevel { untested, testing, excellent, medium, poor, timeout }

/// Classifies a raw latency value (ms, or the -1/-2 sentinels) into a band.
LatencyLevel latencyLevelFor(int? ms) {
  if (ms == null) return LatencyLevel.untested;
  if (ms == kLatencyTesting) return LatencyLevel.testing;
  if (ms == kLatencyFailed) return LatencyLevel.timeout;
  if (ms <= 120) return LatencyLevel.excellent;
  if (ms <= 250) return LatencyLevel.medium;
  if (ms <= kLatencyTimeoutMs) return LatencyLevel.poor;
  return LatencyLevel.timeout;
}

/// The display colour for a latency band.
Color latencyColor(LatencyLevel level, ColorScheme scheme) {
  switch (level) {
    case LatencyLevel.excellent:
      return ArmaTokens.success; // green
    case LatencyLevel.medium:
      return ArmaTokens.warning; // yellow/orange
    case LatencyLevel.poor:
      return scheme.error; // red
    case LatencyLevel.timeout:
    case LatencyLevel.testing:
    case LatencyLevel.untested:
      return scheme.onSurfaceVariant; // gray
  }
}

/// True when a server responded within the timeout band — used by the
/// "Working" filter.
bool isLatencyWorking(int? ms) =>
    ms != null && ms > 0 && ms <= kLatencyTimeoutMs;

/// True when a server failed or timed out — used by the "Failed" filter.
bool isLatencyFailed(int? ms) =>
    ms == kLatencyFailed || (ms != null && ms > kLatencyTimeoutMs);
