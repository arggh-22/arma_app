import 'dart:convert';

import 'package:uuid/uuid.dart';

import 'package:arma_proxy_vpn_client/core/constants/app_constants.dart';
import 'package:arma_proxy_vpn_client/core/constants/protocol_constants.dart';
import 'package:arma_proxy_vpn_client/features/server/domain/entities/server_config.dart';

/// Parses VMess share links into [ServerConfig].
///
/// Handles **both** formats per CONF-05:
/// - **Legacy base64-JSON:** `vmess://` + base64-encoded JSON blob
/// - **Standard URI:** `vmess://uuid@host:port?params#name`
class VmessParser {
  VmessParser._();

  static const _maxInputLength = 10000;

  /// Parses a VMess share link.
  ///
  /// Detects format by checking for `@` in the content after stripping
  /// the `vmess://` prefix. If `@` is present with query params,
  /// routes to URI parser; otherwise to legacy base64-JSON parser.
  static ServerConfig? parse(String input) {
    try {
      if (input.length > _maxInputLength) return null;

      final content = input.replaceFirst('vmess://', '');
      if (content.isEmpty) return null;

      // Format detection per Pitfall 7:
      // If content contains @ with ? and & → standard URI
      if (content.contains('@') &&
          content.contains('?') &&
          content.contains('&')) {
        return _parseStandardUri(input);
      }

      // Otherwise → legacy base64-JSON
      return _parseLegacyBase64(content);
    } catch (_) {
      return null;
    }
  }

  /// Parses legacy VMess base64-JSON format.
  ///
  /// Input is the content AFTER stripping `vmess://`.
  static ServerConfig? _parseLegacyBase64(String content) {
    try {
      // Normalize URL-safe base64 to standard base64
      var normalized = content.replaceAll('-', '+').replaceAll('_', '/');

      // Fix missing padding
      final remainder = normalized.length % 4;
      if (remainder > 0) {
        normalized += '=' * (4 - remainder);
      }

      final decoded = utf8.decode(base64Decode(normalized));
      final json = jsonDecode(decoded) as Map<String, dynamic>;

      final address = json['add']?.toString() ?? '';
      if (address.isEmpty) return null;

      final port = int.tryParse(json['port']?.toString() ?? '');
      if (port == null || port <= 0 || port > 65535) return null;

      final uuid = json['id']?.toString() ?? '';
      if (uuid.isEmpty) return null;

      final tlsValue = json['tls']?.toString() ?? '';
      final security = tlsValue.isNotEmpty ? tlsValue : 'none';

      var name = json['ps']?.toString() ?? '';
      if (name.isEmpty) name = '$address:$port';
      if (name.length > AppConstants.maxServerNameLength) {
        name = name.substring(0, AppConstants.maxServerNameLength);
      }

      return ServerConfig(
        id: const Uuid().v4(),
        name: name,
        protocol: ProtocolType.vmess,
        address: address,
        port: port,
        uuid: uuid,
        alterId: int.tryParse(json['aid']?.toString() ?? '0') ?? 0,
        encryption: _nonEmptyOr(json['scy']?.toString(), 'auto'),
        network: _nonEmptyOr(json['net']?.toString(), 'tcp'),
        security: security,
        sni: _nonEmpty(json['sni']?.toString()),
        host: _nonEmpty(json['host']?.toString()),
        path: _nonEmpty(json['path']?.toString()),
        addedAt: DateTime.now(),
      );
    } catch (_) {
      return null;
    }
  }

  /// Parses standard VMess URI format (same structure as VLESS).
  static ServerConfig? _parseStandardUri(String input) {
    try {
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
        protocol: ProtocolType.vmess,
        address: address,
        port: port,
        uuid: uuid,
        alterId: int.tryParse(params['alterId'] ?? '0') ?? 0,
        encryption: params['encryption'] ?? 'auto',
        network: params['type'] ?? 'tcp',
        security: params['security'] ?? 'none',
        sni: _nonEmpty(params['sni']),
        host: _nonEmpty(params['host']),
        path: _decodeParam(params['path']),
        addedAt: DateTime.now(),
      );
    } catch (_) {
      return null;
    }
  }

  static String _nonEmptyOr(String? value, String fallback) =>
      (value != null && value.isNotEmpty) ? value : fallback;

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
