import NetworkExtension

/// Derives the utun network settings from the Xray JSON config the app sends.
///
/// The app builds one Xray config for all platforms; here we read the pieces
/// the NEPacketTunnelProvider needs (DNS servers, MTU) and otherwise install a
/// full-tunnel (default-route) interface — Xray's own `routing` block decides
/// what is actually proxied vs sent direct.
struct TunnelConfig {
  let dnsServers: [String]
  let mtu: Int

  /// Local address for the virtual interface (Xray does the real routing).
  private let ipv4Address = "198.18.0.1"
  private let ipv4Mask = "255.255.255.0"
  private let ipv6Address = "fd00:2::1"
  private let ipv6Prefix: NSNumber = 64

  init(xrayConfigJson: String) {
    var dns: [String] = []
    var mtu = 1500

    if let data = xrayConfigJson.data(using: .utf8),
       let root = (try? JSONSerialization.jsonObject(with: data)) as? [String: Any] {
      // DNS: xray `dns.servers` may hold plain IPs and/or objects with `address`.
      if let dnsBlock = root["dns"] as? [String: Any],
         let servers = dnsBlock["servers"] as? [Any] {
        for s in servers {
          if let ip = s as? String, TunnelConfig.isPlainIp(ip) {
            dns.append(ip)
          } else if let obj = s as? [String: Any],
                    let ip = obj["address"] as? String,
                    TunnelConfig.isPlainIp(ip) {
            dns.append(ip)
          }
        }
      }
      // MTU: read from the tun inbound if present.
      if let inbounds = root["inbounds"] as? [[String: Any]] {
        for inbound in inbounds where (inbound["protocol"] as? String) == "tun" {
          if let settings = inbound["settings"] as? [String: Any],
             let m = settings["mtu"] as? Int {
            mtu = m
          }
        }
      }
    }

    // System DNS can't be a DoH/DoT URL; fall back to sane resolvers.
    dnsServers = dns.isEmpty ? ["1.1.1.1", "8.8.8.8"] : dns
    // A 9000 MTU (Android tun default) is too large for the packet tunnel;
    // clamp to a safe value for utun.
    self.mtu = (mtu >= 1280 && mtu <= 1500) ? mtu : 1500
  }

  func networkSettings() -> NEPacketTunnelNetworkSettings {
    let settings = NEPacketTunnelNetworkSettings(tunnelRemoteAddress: ipv4Address)

    let ipv4 = NEIPv4Settings(addresses: [ipv4Address], subnetMasks: [ipv4Mask])
    ipv4.includedRoutes = [NEIPv4Route.default()]
    settings.ipv4Settings = ipv4

    let ipv6 = NEIPv6Settings(addresses: [ipv6Address], networkPrefixLengths: [ipv6Prefix])
    ipv6.includedRoutes = [NEIPv6Route.default()]
    settings.ipv6Settings = ipv6

    let dns = NEDNSSettings(servers: dnsServers)
    dns.matchDomains = [""] // route all DNS through the tunnel
    settings.dnsSettings = dns

    settings.mtu = NSNumber(value: mtu)
    return settings
  }

  private static func isPlainIp(_ s: String) -> Bool {
    // Accept bare IPv4/IPv6; reject DoH/DoT and hostnames.
    if s.contains("://") || s == "localhost" { return false }
    var v4 = in_addr()
    var v6 = in6_addr()
    return s.withCString { inet_pton(AF_INET, $0, &v4) } == 1
      || s.withCString { inet_pton(AF_INET6, $0, &v6) } == 1
  }
}
