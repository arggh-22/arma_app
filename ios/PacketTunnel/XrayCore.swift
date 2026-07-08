import Foundation
import os.log

// The Xray core is supplied as a gomobile-built xcframework. The XTLS project
// publishes `LibXray` (https://github.com/XTLS/libXray); drop
// `LibXray.xcframework` into this target and uncomment the import.
//
//   import LibXray
//
// If you use a different binding, only the calls inside this file need to
// change — the rest of the extension talks to `XrayCore` through the small API
// below.

/// Thin wrapper around the Xray-core xcframework.
///
/// Isolates every framework-specific call so swapping cores / libXray versions
/// is a one-file change. Uses libXray's base64-JSON request/response protocol
/// (v1.x). Adjust the function names/shape to match your framework version.
final class XrayCore {
  static let shared = XrayCore()
  private init() {}

  private let log = OSLog(subsystem: "com.arma.vpn.PacketTunnel", category: "core")
  private var configPath: String?

  struct Stats { let uplink: Int64; let downlink: Int64 }

  /// Starts the core with [configJson] (already rewritten to a SOCKS inbound).
  func run(configJson: String) throws {
    let dir = FileManager.default.temporaryDirectory
    let path = dir.appendingPathComponent("xray-config.json").path
    try configJson.write(toFile: path, atomically: true, encoding: .utf8)
    configPath = path

    // libXray expects a base64 request: {"datDir","configPath","maxMemory"}.
    let request: [String: Any] = [
      "datDir": Self.assetDir(),      // geoip/geosite dir (bundle or App Group)
      "configPath": path,
      "maxMemory": 67_108_864,        // 64 MB soft cap
    ]
    let response = Self.callLibXray { req in
      // return LibXrayRunXray(req)   // ← real call once LibXray is linked
      Self.notLinked()
    } requestObject: request

    try Self.throwIfFailed(response, context: "runXray")
    os_log("core running (config=%{public}@)", log: log, type: .info, path)
  }

  func stop() {
    _ = Self.callLibXray { _ in
      // return LibXrayStopXray()     // ← real call
      Self.notLinked()
    } requestObject: nil
    if let p = configPath { try? FileManager.default.removeItem(atPath: p) }
    configPath = nil
    os_log("core stopped", log: log, type: .info)
  }

  /// Live traffic counters via Xray's stats service (config includes `stats`
  /// + `policy`, which the app already emits).
  func stats() -> Stats {
    let response = Self.callLibXray { _ in
      // return LibXrayQueryStats("")  // ← real call (or per-tag queries)
      Self.notLinked()
    } requestObject: nil
    guard let obj = Self.decode(response),
          let data = obj["data"] as? [String: Any] else {
      return Stats(uplink: 0, downlink: 0)
    }
    let up = (data["uplink"] as? NSNumber)?.int64Value ?? 0
    let down = (data["downlink"] as? NSNumber)?.int64Value ?? 0
    return Stats(uplink: up, downlink: down)
  }

  /// Xray version string (used by `getXrayVersion`).
  func version() -> String {
    let response = Self.callLibXray { _ in
      // return LibXrayXrayVersion()   // ← real call
      Self.notLinked()
    } requestObject: nil
    if let obj = Self.decode(response), let v = obj["data"] as? String { return v }
    return "Unknown"
  }

  /// One-shot latency probe through the given config (used by `measureDelay`).
  /// Returns delay in ms, or -1 on failure.
  func measureDelay(configJson: String, url: String) -> Int {
    let request: [String: Any] = ["config": configJson, "url": url, "timeout": 3]
    let response = Self.callLibXray { req in
      // return LibXrayTestXray(req)   // ← real call (name varies by version)
      Self.notLinked()
    } requestObject: request
    if let obj = Self.decode(response), let ms = (obj["data"] as? NSNumber)?.intValue {
      return ms
    }
    return -1
  }

  // MARK: - libXray request/response plumbing

  /// libXray takes a base64-encoded JSON request and returns a base64-encoded
  /// JSON `CallResponse` ({"success":Bool,"data":...,"err":String}).
  private static func callLibXray(
    _ invoke: (String) -> String,
    requestObject: [String: Any]?
  ) -> String {
    var reqB64 = ""
    if let requestObject,
       let data = try? JSONSerialization.data(withJSONObject: requestObject) {
      reqB64 = data.base64EncodedString()
    }
    return invoke(reqB64)
  }

  private static func decode(_ base64Response: String) -> [String: Any]? {
    guard let data = Data(base64Encoded: base64Response),
          let obj = (try? JSONSerialization.jsonObject(with: data)) as? [String: Any]
    else { return nil }
    return obj
  }

  private static func throwIfFailed(_ base64Response: String, context: String) throws {
    guard let obj = decode(base64Response) else {
      throw PacketTunnelError.coreStartFailed("\(context): no response")
    }
    if let success = obj["success"] as? Bool, success == false {
      throw PacketTunnelError.coreStartFailed((obj["err"] as? String) ?? context)
    }
  }

  /// geoip.dat / geosite.dat directory. Ship them in the extension bundle (or
  /// the App Group) so routing rules like `geoip:ru` work.
  private static func assetDir() -> String {
    Bundle.main.resourcePath ?? FileManager.default.temporaryDirectory.path
  }

  /// Placeholder used until `LibXray.xcframework` is linked. Returns a failed
  /// CallResponse so the extension reports a clear error instead of crashing.
  private static func notLinked() -> String {
    let payload: [String: Any] = ["success": false, "err": "LibXray.xcframework not linked"]
    let data = (try? JSONSerialization.data(withJSONObject: payload)) ?? Data()
    return data.base64EncodedString()
  }
}
