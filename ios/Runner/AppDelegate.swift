import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  private var vpnChannel: VpnChannel?

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    // Wire the VPN MethodChannel/EventChannel onto the implicit engine messenger.
    if let messenger = engineBridge.pluginRegistry
      .registrar(forPlugin: "ArmaVpnChannel")?.messenger() {
      vpnChannel = VpnChannel(messenger: messenger)
    }
  }
}
