import 'package:uuid/uuid.dart';

import 'package:arma_proxy_vpn_client/core/constants/app_constants.dart';
import 'package:arma_proxy_vpn_client/core/constants/protocol_constants.dart';
import 'package:arma_proxy_vpn_client/features/server/domain/entities/server_config.dart';

/// Parses Hysteria2 share links into [ServerConfig].
///
/// Supports both `hysteria2://` and `hy2://` URI schemes.
///
/// Format: `hysteria2://auth@host:port?params#name`
class Hysteria2Parser {
  Hysteria2Parser._();

  static const _maxInputLength = 10000;

  /// Parses a Hysteria2 share link URI.
  ///
  /// Handles both `hysteria2://` and `hy2://` schemes.
  /// Returns a [ServerConfig] on success, or `null` if the input is
  /// malformed, missing required fields, or exceeds length limits.
  static ServerConfig? parse(String input) {
    try {
      if (input.length > _maxInputLength) return null;

      // Normalize hy2:// to hysteria2:// for consistent Uri parsing
      final normalized = input.startsWith('hy2://')
          ? input.replaceFirst('hy2://', 'hysteria2://')
          : input;

      final uri = Uri.parse(normalized);

      final address = uri.host;
      if (address.isEmpty) return null;

      final port = uri.port;
      if (port <= 0 || port > 65535) return null;

      final password = Uri.decodeComponent(uri.userInfo);
      if (password.isEmpty) return null;

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
        protocol: ProtocolType.hysteria2,
        address: address,
        port: port,
        password: password,
        sni: _nonEmpty(params['sni']),
        obfs: _nonEmpty(params['obfs']),
        obfsPassword: _nonEmpty(params['obfs-password']),
        addedAt: DateTime.now(),
      );
    } catch (_) {
      return null;
    }
  }

  static String? _nonEmpty(String? value) =>
      (value != null && value.isNotEmpty) ? value : null;
}
