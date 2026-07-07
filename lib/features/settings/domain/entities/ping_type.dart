/// Latency-measurement strategy selectable in Advanced Settings (spec §2).
///
/// [http] is the default/recommended end-to-end check; [tcpConnect] is a fast
/// direct TCP handshake for bulk liveness; [icmp] is a raw system ping that
/// bypasses the tunnel (useful for gamers).
enum PingType {
  http('http', 'HTTP'),
  tcpConnect('tcp', 'TCP Connect'),
  icmp('icmp', 'ICMP');

  const PingType(this.key, this.label);

  /// Stable key persisted in preferences.
  final String key;

  /// Short display label.
  final String label;

  static PingType fromKey(String? key) {
    for (final type in values) {
      if (type.key == key) return type;
    }
    return PingType.http; // default / recommended
  }
}
