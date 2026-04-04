import 'package:uuid/uuid.dart';

import 'package:arma_proxy_vpn_client/core/constants/app_constants.dart';
import 'package:arma_proxy_vpn_client/core/constants/protocol_constants.dart';
import 'package:arma_proxy_vpn_client/features/server/domain/entities/server_config.dart';

/// Parses VLESS share links into [ServerConfig].
///
/// Format: `vless://uuid@host:port?params#name`
class VlessParser {
  VlessParser._();

  static const _maxInputLength = 10000;

  /// Parses a VLESS share link URI.
  ///
  /// Returns a [ServerConfig] on success, or `null` if the input is
  /// malformed, missing required fields, or exceeds length limits.
  static ServerConfig? parse(String input) {
    try {
      if (input.length > _maxInputLength) return null;

      final uri = Uri.parse(input);

      final address = uri.host;
      if (address.isEmpty) return null;

      final port = uri.port;
      if (port <= 0 || port > 65535) return null;

      final uuid = uri.userInfo;
      if (uuid.isEmpty) return null;

      final params = uri.queryParameters;

      var name = uri.fragment.isNotEmpty
          ? Uri.decodeComponent(uri.fragment)
          : '$address:$port';
      if (name.length > AppConstants.maxServerNameLength) {
        name = name.substring(0, AppConstants.maxServerNameLength);
      }

      return ServerConfig(
        id: const Uuid().v4(),
        name: name,
        protocol: ProtocolType.vless,
        address: address,
        port: port,
        uuid: uuid,
        network: params['type'] ?? 'tcp',
        security: params['security'] ?? 'none',
        sni: _nonEmpty(params['sni']),
        host: _nonEmpty(params['host']),
        path: _decodeParam(params['path']),
        fingerprint: _nonEmpty(params['fp']),
        flow: _nonEmpty(params['flow']),
        publicKey: _nonEmpty(params['pbk']),
        shortId: _nonEmpty(params['sid']),
        spiderX: _decodeParam(params['spx']),
        serviceName: _nonEmpty(params['serviceName']),
        alpn: _nonEmpty(params['alpn']),
        addedAt: DateTime.now(),
      );
    } catch (_) {
      return null;
    }
  }

  static String? _nonEmpty(String? value) =>
      (value != null && value.isNotEmpty) ? value : null;

  static String? _decodeParam(String? value) {
    if (value == null || value.isEmpty) return null;
    try {
      return Uri.decodeComponent(value);
    } catch (_) {
      return value;
    }
  }
}
