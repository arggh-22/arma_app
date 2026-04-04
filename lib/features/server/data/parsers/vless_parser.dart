import 'package:uuid/uuid.dart';

import 'package:arma_proxy_vpn_client/core/constants/protocol_constants.dart';
import 'package:arma_proxy_vpn_client/features/server/data/parsers/parser_utils.dart';
import 'package:arma_proxy_vpn_client/features/server/domain/entities/server_config.dart';

/// Parses VLESS share links into [ServerConfig].
///
/// Format: `vless://uuid@host:port?params#name`
class VlessParser {
  VlessParser._();

  /// Parses a VLESS share link URI.
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

      final uuid = uri.userInfo;
      if (uuid.isEmpty) return null;

      final params = uri.queryParameters;
      final name = ParserUtils.extractName(uri.fragment, address, port);

      return ServerConfig(
        id: const Uuid().v4(),
        name: name,
        protocol: ProtocolType.vless,
        address: address,
        port: port,
        uuid: uuid,
        network: params['type'] ?? 'tcp',
        security: params['security'] ?? 'none',
        sni: ParserUtils.nonEmpty(params['sni']),
        host: ParserUtils.nonEmpty(params['host']),
        path: ParserUtils.decodeParam(params['path']),
        fingerprint: ParserUtils.nonEmpty(params['fp']),
        flow: ParserUtils.nonEmpty(params['flow']),
        publicKey: ParserUtils.nonEmpty(params['pbk']),
        shortId: ParserUtils.nonEmpty(params['sid']),
        spiderX: ParserUtils.decodeParam(params['spx']),
        serviceName: ParserUtils.nonEmpty(params['serviceName']),
        alpn: ParserUtils.nonEmpty(params['alpn']),
        addedAt: DateTime.now(),
      );
    } catch (_) {
      return null;
    }
  }
}
