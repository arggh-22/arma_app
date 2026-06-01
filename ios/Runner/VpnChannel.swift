import Flutter
import Foundation
import NetworkExtension
import UserNotifications

/// Bridges the Flutter `com.arma.vpn/method` MethodChannel and
/// `com.arma.vpn/vpn_status` EventChannel to an iOS NEPacketTunnelProvider.
///
/// This mirrors the Android `MainActivity`/`ArmaVpnService` contract so the
/// shared Dart layer (`VpnPlatformService`) works unchanged on iOS. The actual
/// Xray core runs inside the PacketTunnel app extension (see
/// `PacketTunnel/PacketTunnelProvider.swift`); this class only installs/controls
/// the VPN profile and relays status.
///
/// IMPORTANT: keep these identifiers in sync with the Xcode project:
///   - `tunnelBundleId`  = the PacketTunnel extension's bundle identifier
///   - `appGroup`        = the App Group shared by app + extension
final class VpnChannel: NSObject, FlutterStreamHandler {
  static let methodChannelName = "com.arma.vpn/method"
  static let eventChannelName = "com.arma.vpn/vpn_status"

  // TODO(ios-setup): set these to your real identifiers (see ios/IOS_SETUP.md).
  private let tunnelBundleId = "com.arma.vpn.PacketTunnel"
  private let appGroup = "group.com.arma.vpn"

  private let methodChannel: FlutterMethodChannel
  private let eventChannel: FlutterEventChannel
  private var eventSink: FlutterEventSink?
  private var statusObserver: NSObjectProtocol?

  init(messenger: FlutterBinaryMessenger) {
    methodChannel = FlutterMethodChannel(
      name: VpnChannel.methodChannelName, binaryMessenger: messenger)
    eventChannel = FlutterEventChannel(
      name: VpnChannel.eventChannelName, binaryMessenger: messenger)
    super.init()
    methodChannel.setMethodCallHandler { [weak self] call, result in
      self?.handle(call, result)
    }
    eventChannel.setStreamHandler(self)
  }

  // MARK: - MethodChannel

  private func handle(_ call: FlutterMethodCall, _ result: @escaping FlutterResult) {
    let args = call.arguments as? [String: Any]
    switch call.method {
    case "requestVpnPermission":
      // Installing/saving the tunnel profile triggers the iOS consent prompt.
      ensureManager { manager, error in
        result(error == nil && manager != nil)
      }

    case "startVpn":
      guard let config = args?["config"] as? String else {
        result(FlutterError(code: "bad_args", message: "Missing config", details: nil))
        return
      }
      let serverName = args?["serverName"] as? String ?? "VPN"
      startVpn(config: config, serverName: serverName, result: result)

    case "stopVpn":
      stopVpn(result: result)

    case "isRunning":
      loadManager { manager in
        let status = manager?.connection.status
        result(status == .connected || status == .connecting || status == .reasserting)
      }

    case "requestNotificationPermission":
      UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, _ in
        DispatchQueue.main.async { result(granted) }
      }

    case "getXrayVersion":
      // TODO(ios-core): surface the real version from the bundled Xray xcframework.
      result("Unknown")

    case "measureDelay":
      // TODO(ios-core): run a one-shot latency probe via the Xray core.
      result(-1)

    // Android-only features — safe no-ops on iOS.
    case "getInstalledApps":
      result([[String: Any]]())
    case "setPerAppConfig", "setNotificationDetailsEnabled":
      result(nil)

    default:
      result(FlutterMethodNotImplemented)
    }
  }

  // MARK: - Tunnel control

  private func startVpn(config: String, serverName: String, result: @escaping FlutterResult) {
    ensureManager { [weak self] manager, error in
      guard let self, let manager, error == nil else {
        result(FlutterError(code: "manager", message: error?.localizedDescription ?? "no manager", details: nil))
        return
      }
      let proto = (manager.protocolConfiguration as? NETunnelProviderProtocol) ?? NETunnelProviderProtocol()
      proto.providerBundleIdentifier = self.tunnelBundleId
      // serverAddress is required by iOS but only shown in Settings.
      proto.serverAddress = serverName
      proto.providerConfiguration = [
        "config": config,
        "serverName": serverName,
        "appGroup": self.appGroup,
      ]
      manager.protocolConfiguration = proto
      manager.localizedDescription = serverName
      manager.isEnabled = true
      manager.saveToPreferences { saveError in
        if let saveError = saveError {
          result(FlutterError(code: "save", message: saveError.localizedDescription, details: nil))
          return
        }
        // Reload so the saved config is applied before starting.
        manager.loadFromPreferences { _ in
          do {
            try manager.connection.startVPNTunnel()
            result(true)
          } catch {
            result(FlutterError(code: "start", message: error.localizedDescription, details: nil))
          }
        }
      }
    }
  }

  private func stopVpn(result: @escaping FlutterResult) {
    loadManager { manager in
      manager?.connection.stopVPNTunnel()
      result(true)
    }
  }

  // MARK: - Manager helpers

  /// Loads the existing Arma tunnel manager (or nil if none installed yet).
  private func loadManager(_ completion: @escaping (NETunnelProviderManager?) -> Void) {
    NETunnelProviderManager.loadAllFromPreferences { managers, _ in
      completion(managers?.first)
    }
  }

  /// Loads the existing manager or creates a fresh one, returning it ready to configure.
  private func ensureManager(_ completion: @escaping (NETunnelProviderManager?, Error?) -> Void) {
    NETunnelProviderManager.loadAllFromPreferences { managers, error in
      if let error = error {
        completion(nil, error)
        return
      }
      completion(managers?.first ?? NETunnelProviderManager(), nil)
    }
  }

  // MARK: - EventChannel (status stream)

  func onListen(withArguments _: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
    eventSink = events
    statusObserver = NotificationCenter.default.addObserver(
      forName: .NEVPNStatusDidChange, object: nil, queue: .main
    ) { [weak self] note in
      guard let conn = note.object as? NEVPNConnection else { return }
      self?.emitStatus(conn.status)
    }
    // Emit the current status immediately so the UI syncs on subscribe.
    loadManager { [weak self] manager in
      self?.emitStatus(manager?.connection.status ?? .disconnected)
    }
    return nil
  }

  func onCancel(withArguments _: Any?) -> FlutterError? {
    if let statusObserver = statusObserver {
      NotificationCenter.default.removeObserver(statusObserver)
    }
    statusObserver = nil
    eventSink = nil
    return nil
  }

  private func emitStatus(_ status: NEVPNStatus) {
    guard let sink = eventSink else { return }
    let state: String
    switch status {
    case .connecting, .reasserting: state = "connecting"
    case .connected: state = "connected"
    case .disconnecting, .disconnected, .invalid: state = "disconnected"
    @unknown default: state = "disconnected"
    }
    sink(["type": "status", "state": state])
  }
}
