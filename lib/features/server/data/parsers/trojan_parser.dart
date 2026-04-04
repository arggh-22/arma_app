import 'package:uuid/uuid.dart';

import 'package:arma_proxy_vpn_client/core/constants/protocol_constants.dart';
import 'package:arma_proxy_vpn_client/features/server/data/parsers/parser_utils.dart';
import 'package:arma_proxy_vpn_client/features/server/domain/entities/server_config.dart';

/// Parses Trojan share links into [ServerConfig].
///
/// Format: `trojan://password@host:port?params#name`
///
/// Password is in the `userInfo` portion and may be URL-encoded.
/// Security defaults to `tls` when not specified (Trojan convention).
class TrojanParser {
  TrojanParser._();

  /// Parses a Trojan share link URI.
  ///
  /// Returns a [ServerConfig] on success, or `null` if the input is
  /// malformed, missing required fields, or exceeds length limits.
  static ServerConfig? parse(String input) {
    try {
      if (ParserUtils.exceedsMaxLength(input)) return null;

      final uri = Uri.parse(input);

      final address = uri.host;
      final port = uri.port;
      if (!ParserUtils.isValidHostPort(address, port)) return null;

      final password = Uri.decodeComponent(uri.userInfo);
      if (password.isEmpty) return null;

      final params = uri.queryParameters;
      final name = ParserUtils.extractName(uri.fragment, address, port);

      return ServerConfig(
        id: const Uuid().v4(),
        name: name,
        protocol: ProtocolType.trojan,
        address: address,
        port: port,
        password: password,
        network: params['type'] ?? 'tcp',
        security: params['security'] ?? 'tls',
        sni: ParserUtils.nonEmpty(params['sni']),
        host: ParserUtils.nonEmpty(params['host']),
        path: ParserUtils.decodeParam(params['path']),
        fingerprint: ParserUtils.nonEmpty(params['fp']),
        alpn: ParserUtils.nonEmpty(params['alpn']),
        addedAt: DateTime.now(),
      );
    } catch (_) {
      return null;
    }
  }
}
