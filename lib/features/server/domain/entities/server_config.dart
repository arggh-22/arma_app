import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:arma_proxy_vpn_client/core/constants/protocol_constants.dart';

part 'server_config.freezed.dart';
part 'server_config.g.dart';

/// Domain entity representing a proxy server configuration.
///
/// Supports all protocol-specific fields for VLESS, VMess, Trojan,
/// Shadowsocks, and Hysteria2. Protocol-irrelevant fields are left null.
@freezed
abstract class ServerConfig with _$ServerConfig {
  const factory ServerConfig({
    /// Unique identifier (UUID v4).
    required String id,

    /// User-facing display name (e.g., "Tokyo #3").
    required String name,

    /// Proxy protocol type.
    required ProtocolType protocol,

    /// Server hostname or IP address.
    required String address,

    /// Server port number.
    required int port,

    /// UUID for VLESS/VMess authentication.
    String? uuid,

    /// Password for Trojan/Shadowsocks/Hysteria2.
    String? password,

    /// Encryption method (VMess: auto/aes-128-gcm/chacha20-poly1305/none).
    @Default('none') String encryption,

    /// Transport network type: tcp, ws, grpc, h2, kcp.
    @Default('tcp') String network,

    /// TLS security: none, tls, reality.
    @Default('none') String security,

    /// TLS Server Name Indication.
    String? sni,

    /// WebSocket/HTTP/2 host header.
    String? host,

    /// WebSocket/HTTP/2 path.
    String? path,

    /// ALPN negotiation protocols (comma-separated).
    String? alpn,

    /// TLS fingerprint (e.g., chrome, firefox, safari).
    String? fingerprint,

    /// VLESS XTLS flow control (e.g., xtls-rprx-vision).
    String? flow,

    /// VMess alterId (legacy, usually 0 for AEAD).
    @Default(0) int alterId,

    /// gRPC service name.
    String? serviceName,

    /// gRPC authority.
    String? authority,

    /// Reality public key.
    String? publicKey,

    /// Reality short ID.
    String? shortId,

    /// Reality spiderX path.
    String? spiderX,

    /// Shadowsocks encryption method (e.g., aes-256-gcm, chacha20-ietf-poly1305).
    String? method,

    /// Hysteria2 obfuscation type.
    String? obfs,

    /// Hysteria2 obfuscation password.
    String? obfsPassword,

    /// Hysteria2 upload bandwidth hint in Mbps (optional — auto-detect if null).
    int? upMbps,

    /// Hysteria2 download bandwidth hint in Mbps (optional — auto-detect if null).
    int? downMbps,

    /// Hysteria2: skip TLS certificate verification.
    @Default(false) bool insecure,

    /// ID of the subscription this config belongs to (null = manual import).
    String? subscriptionId,

    /// Group name for UI grouping.
    @Default('Manual') String groupName,

    /// Timestamp when the config was added.
    required DateTime addedAt,
  }) = _ServerConfig;

  factory ServerConfig.fromJson(Map<String, dynamic> json) =>
      _$ServerConfigFromJson(json);
}
