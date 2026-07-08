import Foundation
import NetworkExtension
import os.log

// tun2socks is provided by the `HevSocks5Tunnel` pod
// (https://github.com/heiher/hev-socks5-tunnel, used by most iOS proxy apps).
// Add it in the Podfile for the PacketTunnel target, then uncomment:
//
//   import HevSocks5Tunnel
//
// It reads raw IP packets from the utun file descriptor and forwards them to a
// local SOCKS5 server (our Xray inbound), handling TCP + UDP.

/// Bridges the packet-tunnel utun device to Xray's local SOCKS inbound.
final class Tun2SocksBridge {
  static let shared = Tun2SocksBridge()
  private init() {}

  private let log = OSLog(subsystem: "com.arma.vpn.PacketTunnel", category: "tun2socks")
  private let queue = DispatchQueue(label: "com.arma.vpn.tun2socks", qos: .userInitiated)
  private var started = false

  func start(provider: NEPacketTunnelProvider, socksHost: String, socksPort: Int) throws {
    guard let fd = Self.tunnelFileDescriptor(provider: provider) else {
      os_log("could not resolve utun fd", log: log, type: .error)
      throw PacketTunnelError.tunFdUnavailable
    }

    // Keep in sync with TunnelConfig's utun MTU clamp.
    let config = """
    tunnel:
      mtu: 1500
    socks5:
      address: \(socksHost)
      port: \(socksPort)
      udp: 'udp'
    misc:
      task-stack-size: 20480
      log-level: warn
    """

    started = true
    queue.async { [weak self] in
      guard let self else { return }
      os_log("starting tun2socks on fd=%d → %{public}@:%d", log: self.log,
             type: .info, fd, socksHost, socksPort)
      // HevSocks5Tunnel.start(withConfigString: config, fileDescriptor: fd)
      _ = config  // remove once the pod is linked
    }
  }

  func stop() {
    guard started else { return }
    started = false
    // HevSocks5Tunnel.quit()
    os_log("tun2socks stopped", log: log, type: .info)
  }

  // MARK: - utun fd discovery

  /// NEPacketTunnelProvider doesn't expose the utun fd, but the extension owns
  /// exactly one; find it by locating the open socket whose control name starts
  /// with "utun". This is the standard technique used by iOS proxy clients.
  private static func tunnelFileDescriptor(provider _: NEPacketTunnelProvider) -> Int32? {
    var buf = [CChar](repeating: 0, count: Int(IFNAMSIZ))
    for fd: Int32 in 0..<1024 {
      var len = socklen_t(buf.count)
      let ret = getsockopt(fd, 2 /* SYSPROTO_CONTROL */, 2 /* UTUN_OPT_IFNAME */, &buf, &len)
      if ret == 0, String(cString: buf).hasPrefix("utun") {
        return fd
      }
    }
    return nil
  }
}
