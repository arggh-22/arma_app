/// Protocol type enumeration for all supported proxy protocols.
///
/// Each protocol has a display [label] and a URI [scheme].
enum ProtocolType {
  vless(label: 'VLESS', scheme: 'vless'),
  vmess(label: 'VMess', scheme: 'vmess'),
  trojan(label: 'Trojan', scheme: 'trojan'),
  shadowsocks(label: 'SS', scheme: 'ss'),
  hysteria2(label: 'Hysteria2', scheme: 'hysteria2');

  const ProtocolType({required this.label, required this.scheme});

  /// Display name for the protocol (e.g., 'VLESS', 'VMess').
  final String label;

  /// URI scheme used in share links (e.g., 'vless', 'vmess').
  final String scheme;

  /// Returns the [ProtocolType] matching the given URI [scheme],
  /// or `null` if no match is found.
  ///
  /// Also matches 'hy2' as an alias for [hysteria2].
  static ProtocolType? fromScheme(String scheme) {
    final normalized = scheme.toLowerCase();
    if (normalized == 'hy2') return ProtocolType.hysteria2;
    for (final type in ProtocolType.values) {
      if (type.scheme == normalized) return type;
    }
    return null;
  }
}
