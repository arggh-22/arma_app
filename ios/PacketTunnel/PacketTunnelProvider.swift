import NetworkExtension

/// NEPacketTunnelProvider that runs the Xray core for the Arma VPN.
///
/// Lifecycle:
///   startTunnel  → read Xray JSON from providerConfiguration → configure the
///                  utun network settings → start Xray → bridge packets.
///   stopTunnel   → stop Xray.
///
/// The Xray core itself is NOT included here yet. It must be supplied as an
/// `xcframework` built from Xray-core via `gomobile bind` on macOS, then called
/// through the `XrayBridge` seam below. See ios/IOS_SETUP.md.
class PacketTunnelProvider: NEPacketTunnelProvider {

  override func startTunnel(
    options _: [String: NSObject]?,
    completionHandler: @escaping (Error?) -> Void
  ) {
    guard
      let proto = protocolConfiguration as? NETunnelProviderProtocol,
      let providerConfig = proto.providerConfiguration,
      let config = providerConfig["config"] as? String
    else {
      completionHandler(PacketTunnelError.missingConfig)
      return
    }

    // utun settings: full-tunnel IPv4 (+IPv6) with app DNS. The address is a
    // private placeholder for the virtual interface; Xray handles real routing.
    let settings = NEPacketTunnelNetworkSettings(tunnelRemoteAddress: "127.0.0.1")
    let ipv4 = NEIPv4Settings(addresses: ["198.18.0.1"], subnetMasks: ["255.255.0.0"])
    ipv4.includedRoutes = [NEIPv4Route.default()]
    settings.ipv4Settings = ipv4
    settings.mtu = 9000
    settings.dnsSettings = NEDNSSettings(servers: ["1.1.1.1", "8.8.8.8"])

    setTunnelNetworkSettings(settings) { [weak self] error in
      guard let self else { return }
      if let error = error {
        completionHandler(error)
        return
      }
      do {
        // TODO(ios-core): start the Xray core with `config`, bridging packets
        // between `self.packetFlow` and Xray (tun2socks or Xray tun inbound).
        try XrayBridge.shared.start(config: config, packetFlow: self.packetFlow)
        completionHandler(nil)
      } catch {
        completionHandler(error)
      }
    }
  }

  override func stopTunnel(
    with _: NEProviderStopReason,
    completionHandler: @escaping () -> Void
  ) {
    XrayBridge.shared.stop()
    completionHandler()
  }

  override func handleAppMessage(_ messageData: Data, completionHandler: ((Data?) -> Void)?) {
    completionHandler?(nil)
  }
}

enum PacketTunnelError: Error {
  case missingConfig
}

/// Seam for the Xray core. Replace the body with calls into the bundled Xray
/// `xcframework` (e.g. `LibXrayRun(...)` / a gomobile-generated API) plus a
/// tun2socks bridge over `packetFlow`. Kept as a stub so the extension compiles
/// before the core is integrated. See ios/IOS_SETUP.md.
final class XrayBridge {
  static let shared = XrayBridge()
  private init() {}

  func start(config _: String, packetFlow _: NEPacketTunnelFlow) throws {
    // TODO(ios-core): integrate the Xray xcframework here.
    throw PacketTunnelError.missingConfig
  }

  func stop() {
    // TODO(ios-core): stop the Xray core and tear down the packet bridge.
  }
}
