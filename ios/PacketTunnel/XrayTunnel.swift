import Foundation
import NetworkExtension
import os.log

/// Orchestrates the Xray core + tun2socks bridge inside the packet-tunnel
/// extension.
///
/// The app-built config carries a `tun` inbound (that's what Android's core
/// reads via a file descriptor). iOS has no such fd for Xray, so we run Xray
/// with a local **SOCKS** inbound and bridge the utun packets to it with
/// tun2socks (hev-socks5-tunnel). Everything else in the config — outbounds,
/// routing, dns, balancers — is preserved unchanged.
final class XrayTunnel {
  static let shared = XrayTunnel()
  private init() {}

  private let log = OSLog(subsystem: "com.arma.vpn.PacketTunnel", category: "xray")
  private let socksHost = "127.0.0.1"
  private let socksPort = 10808
  private var appGroup: String?
  private var statsTimer: DispatchSourceTimer?
  private var running = false

  func start(configJson: String, provider: NEPacketTunnelProvider, appGroup: String?) throws {
    self.appGroup = appGroup
    let coreConfig = Self.rewriteInboundToSocks(
      configJson, host: socksHost, port: socksPort
    )

    // 1) Start the Xray core with the rewritten (SOCKS-inbound) config.
    try XrayCore.shared.run(configJson: coreConfig)

    // 2) Bridge the utun device to the SOCKS inbound.
    do {
      try Tun2SocksBridge.shared.start(
        provider: provider, socksHost: socksHost, socksPort: socksPort
      )
    } catch {
      XrayCore.shared.stop()
      throw error
    }

    running = true
    startStatsReporting()
    os_log("XrayTunnel started (socks %{public}@:%d)", log: log, type: .info,
           socksHost, socksPort)
  }

  func stop() {
    guard running else { return }
    running = false
    stopStatsReporting()
    Tun2SocksBridge.shared.stop()
    XrayCore.shared.stop()
    os_log("XrayTunnel stopped", log: log, type: .info)
  }

  // MARK: - Stats (App Group + provider message)

  func statsSnapshotData() -> Data? {
    let s = XrayCore.shared.stats()
    return try? JSONSerialization.data(withJSONObject: [
      "type": "stats", "up": s.uplink, "down": s.downlink,
    ])
  }

  private func startStatsReporting() {
    guard let appGroup, let defaults = UserDefaults(suiteName: appGroup) else { return }
    let timer = DispatchSource.makeTimerSource(queue: .global(qos: .utility))
    timer.schedule(deadline: .now() + 1, repeating: 1)
    timer.setEventHandler { [weak self] in
      guard let self, self.running else { return }
      let s = XrayCore.shared.stats()
      defaults.set(s.uplink, forKey: "vpn.stats.up")
      defaults.set(s.downlink, forKey: "vpn.stats.down")
      defaults.set(Date().timeIntervalSince1970, forKey: "vpn.stats.at")
    }
    timer.resume()
    statsTimer = timer
  }

  private func stopStatsReporting() {
    statsTimer?.cancel()
    statsTimer = nil
  }

  // MARK: - Config transform

  /// Replaces the config's inbounds with a single SOCKS inbound so tun2socks
  /// can feed traffic into Xray. Leaves outbounds/routing/dns untouched.
  static func rewriteInboundToSocks(_ json: String, host: String, port: Int) -> String {
    guard let data = json.data(using: .utf8),
          var root = (try? JSONSerialization.jsonObject(with: data)) as? [String: Any]
    else { return json }

    root["inbounds"] = [[
      "tag": "socks-in",
      "protocol": "socks",
      "listen": host,
      "port": port,
      "settings": ["udp": true, "auth": "noauth"],
      "sniffing": [
        "enabled": true,
        "destOverride": ["http", "tls", "quic"],
        "routeOnly": false,
      ],
    ]]

    guard let out = try? JSONSerialization.data(withJSONObject: root),
          let str = String(data: out, encoding: .utf8)
    else { return json }
    return str
  }
}
