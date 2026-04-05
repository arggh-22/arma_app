/// Real-time traffic statistics from the VPN engine.
///
/// Updated every ~1 second while connected via EventChannel from native.
class TrafficStats {
  final int uplinkBytesPerSecond;
  final int downlinkBytesPerSecond;

  const TrafficStats({
    this.uplinkBytesPerSecond = 0,
    this.downlinkBytesPerSecond = 0,
  });

  /// Zero-traffic constant for initial/disconnected state.
  static const zero = TrafficStats();
}
