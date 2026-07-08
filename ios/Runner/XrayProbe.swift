import Foundation

// In-app (Runner target) helper for the two core calls that don't need the
// tunnel: the Xray version string and a one-shot latency probe. Runs inside the
// app process, so `LibXray.xcframework` must be linked to the **Runner** target
// too (in addition to the PacketTunnel extension).
//
//   import LibXray
//
// Self-contained (no dependency on the extension) — swap the two marked calls
// to match your libXray version.
enum XrayProbe {
  static func version() -> String {
    let response = call { _ in
      // return LibXrayXrayVersion()      // ← real call
      notLinked()
    } request: nil
    if let obj = decode(response), let v = obj["data"] as? String { return v }
    return "Unknown"
  }

  /// Latency in ms through [configJson], or -1 on failure.
  static func measureDelay(configJson: String, url: String) -> Int {
    guard !configJson.isEmpty else { return -1 }
    let request: [String: Any] = ["config": configJson, "url": url, "timeout": 3]
    let response = call { req in
      // return LibXrayTestXray(req)      // ← real call (name varies by version)
      notLinked()
    } request: request
    if let obj = decode(response), let ms = (obj["data"] as? NSNumber)?.intValue {
      return ms
    }
    return -1
  }

  // MARK: - libXray base64 request/response plumbing

  private static func call(_ invoke: (String) -> String, request: [String: Any]?) -> String {
    var reqB64 = ""
    if let request, let data = try? JSONSerialization.data(withJSONObject: request) {
      reqB64 = data.base64EncodedString()
    }
    return invoke(reqB64)
  }

  private static func decode(_ base64: String) -> [String: Any]? {
    guard let data = Data(base64Encoded: base64),
          let obj = (try? JSONSerialization.jsonObject(with: data)) as? [String: Any]
    else { return nil }
    return obj
  }

  private static func notLinked() -> String {
    let payload: [String: Any] = ["success": false, "err": "LibXray not linked"]
    let data = (try? JSONSerialization.data(withJSONObject: payload)) ?? Data()
    return data.base64EncodedString()
  }
}
