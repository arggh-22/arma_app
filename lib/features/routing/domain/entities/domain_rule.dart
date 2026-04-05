/// A custom domain routing rule.
///
/// Specifies how traffic to a particular domain should be handled:
/// 'proxy' routes through the VPN, 'direct' bypasses it,
/// 'block' drops the traffic.
class DomainRule {
  final String domain;

  /// Routing action: 'proxy', 'direct', or 'block'.
  final String action;

  const DomainRule({required this.domain, required this.action});
}
