import NetworkExtension
import os.log

/// NEPacketTunnelProvider that runs the Xray core for Arma VPN on iOS/macOS.
///
/// Flow:
///   startTunnel → read Xray JSON from the provider configuration → configure
///                 the utun (DNS/MTU/routes parsed from the config) → start the
///                 Xray core + a tun2socks bridge over the utun fd.
///   stopTunnel  → stop the bridge and the core.
///
/// The heavy lifting lives in [XrayTunnel] (core + tun2socks). This class only
/// owns the NetworkExtension lifecycle and the utun network settings.
///
/// Shared verbatim by the iOS and macOS PacketTunnel targets.
final class PacketTunnelProvider: NEPacketTunnelProvider {
  private let log = OSLog(subsystem: "com.arma.vpn.PacketTunnel", category: "tunnel")

  override func startTunnel(
    options _: [String: NSObject]?,
    completionHandler: @escaping (Error?) -> Void
  ) {
    guard
      let proto = protocolConfiguration as? NETunnelProviderProtocol,
      let providerConfig = proto.providerConfiguration,
      let configJson = providerConfig["config"] as? String,
      !configJson.isEmpty
    else {
      os_log("startTunnel: missing config", log: log, type: .error)
      completionHandler(PacketTunnelError.missingConfig)
      return
    }

    let parsed = TunnelConfig(xrayConfigJson: configJson)
    os_log("startTunnel: dns=%{public}@ mtu=%d", log: log, type: .info,
           parsed.dnsServers.joined(separator: ","), parsed.mtu)

    setTunnelNetworkSettings(parsed.networkSettings()) { [weak self] error in
      guard let self else { return }
      if let error {
        os_log("setTunnelNetworkSettings failed: %{public}@", log: self.log,
               type: .error, error.localizedDescription)
        completionHandler(error)
        return
      }
      do {
        try XrayTunnel.shared.start(
          configJson: configJson,
          provider: self,
          appGroup: providerConfig["appGroup"] as? String
        )
        os_log("startTunnel: core + bridge up", log: self.log, type: .info)
        completionHandler(nil)
      } catch {
        os_log("XrayTunnel.start failed: %{public}@", log: self.log, type: .error,
               error.localizedDescription)
        completionHandler(error)
      }
    }
  }

  override func stopTunnel(
    with reason: NEProviderStopReason,
    completionHandler: @escaping () -> Void
  ) {
    os_log("stopTunnel: reason=%d", log: log, type: .info, reason.rawValue)
    XrayTunnel.shared.stop()
    completionHandler()
  }

  override func handleAppMessage(_ messageData: Data, completionHandler: ((Data?) -> Void)?) {
    // The app can request a live stats snapshot over the provider session.
    if String(data: messageData, encoding: .utf8) == "stats" {
      completionHandler?(XrayTunnel.shared.statsSnapshotData())
    } else {
      completionHandler?(nil)
    }
  }
}

enum PacketTunnelError: Error, LocalizedError {
  case missingConfig
  case coreStartFailed(String)
  case tunFdUnavailable

  var errorDescription: String? {
    switch self {
    case .missingConfig: return "Missing Xray config"
    case let .coreStartFailed(msg): return "Xray core failed to start: \(msg)"
    case .tunFdUnavailable: return "Could not obtain the tunnel file descriptor"
    }
  }
}
