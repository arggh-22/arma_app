import Cocoa
import FlutterMacOS

class MainFlutterWindow: NSWindow {
  private var vpnChannel: VpnChannel?

  override func awakeFromNib() {
    let flutterViewController = FlutterViewController()
    let windowFrame = self.frame
    self.contentViewController = flutterViewController
    self.setFrame(windowFrame, display: true)

    RegisterGeneratedPlugins(registry: flutterViewController)

    // Wire the shared VPN MethodChannel/EventChannel (same contract as iOS).
    // Add `VpnChannel.swift` + `XrayProbe.swift` (from ios/Runner/) to the
    // macOS Runner target so this resolves.
    vpnChannel = VpnChannel(messenger: flutterViewController.engine.binaryMessenger)

    super.awakeFromNib()
  }
}
