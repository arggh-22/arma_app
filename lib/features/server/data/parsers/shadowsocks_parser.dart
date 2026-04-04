import 'dart:convert';

import 'package:uuid/uuid.dart';

import 'package:arma_proxy_vpn_client/core/constants/app_constants.dart';
import 'package:arma_proxy_vpn_client/core/constants/protocol_constants.dart';
import 'package:arma_proxy_vpn_client/features/server/domain/entities/server_config.dart';

/// Parses Shadowsocks (SS) share links into [ServerConfig].
///
/// Format: `ss://base64(method:password)@host:port#name`
///
/// The base64-encoded portion contains `method:password` where `method` is
/// the encryption algorithm and `password` is the auth credential.
///
/// Also supports SIP002 format with query parameters for plugin info.
class ShadowsocksParser {
  ShadowsocksParser._();

  static const _maxInputLength = 10000;

  /// Known valid Shadowsocks encryption methods per T-01-03-04.
  static const _validMethods = <String>{
    'aes-128-gcm',
    'aes-256-gcm',
    'chacha20-ietf-poly1305',
    'xchacha20-ietf-poly1305',
    '2022-blake3-aes-128-gcm',
    '2022-blake3-aes-256-gcm',
    '2022-blake3-chacha20-poly1305',
    'none',
    'plain',
  };

  /// Parses a Shadowsocks share link.
  ///
  /// Returns a [ServerConfig] on success, or `null` if the input is
  /// malformed, has an unknown encryption method, or exceeds length limits.
  static ServerConfig? parse(String input) {
    try {
      if (input.length > _maxInputLength) return null;

      final content = input.replaceFirst('ss://', '');
      if (content.isEmpty) return null;

      // Split fragment (server name) first
      String mainPart;
      String? fragment;

      final hashIdx = content.indexOf('#');
      if (hashIdx >= 0) {
        mainPart = content.substring(0, hashIdx);
        fragment = content.substring(hashIdx + 1);
      } else {
        mainPart = content;
      }

      // Split on @ to separate base64(method:password) from server:port
      final atIdx = mainPart.lastIndexOf('@');
      if (atIdx < 0) return null;

      final userInfoEncoded = mainPart.substring(0, atIdx);
      final serverPart = mainPart.substring(atIdx + 1);

      // Decode base64 userInfo to get method:password
      final decoded = _decodeBase64(userInfoEncoded);
      if (decoded == null) return null;

      // Split on first ':' to separate method from password
      final colonIdx = decoded.indexOf(':');
      if (colonIdx < 0) return null;

      final method = decoded.substring(0, colonIdx);
      final password = decoded.substring(colonIdx + 1);

      if (method.isEmpty || password.isEmpty) return null;

      // Validate method against known ciphers per T-01-03-04
      if (!_validMethods.contains(method)) return null;

      // Parse server:port — handle query params for SIP002
      String hostPort;
      final qIdx = serverPart.indexOf('?');
      if (qIdx >= 0) {
        hostPort = serverPart.substring(0, qIdx);
      } else {
        hostPort = serverPart;
      }

      // Extract host and port
      final lastColon = hostPort.lastIndexOf(':');
      if (lastColon < 0) return null;

      final address = hostPort.substring(0, lastColon);
      if (address.isEmpty) return null;

      final port = int.tryParse(hostPort.substring(lastColon + 1));
      if (port == null || port <= 0 || port > 65535) return null;

      var name = (fragment != null && fragment.isNotEmpty)
          ? Uri.decodeComponent(fragment)
          : '$address:$port';
      if (name.length > AppConstants.maxServerNameLength) {
        name = name.substring(0, AppConstants.maxServerNameLength);
      }

      return ServerConfig(
        id: const Uuid().v4(),
        name: name,
        protocol: ProtocolType.shadowsocks,
        address: address,
        port: port,
        password: password,
        method: method,
        addedAt: DateTime.now(),
      );
    } catch (_) {
      return null;
    }
  }

  /// Decodes base64 content, handling URL-safe chars and missing padding.
  static String? _decodeBase64(String input) {
    try {
      // Normalize URL-safe base64
      var normalized = input.replaceAll('-', '+').replaceAll('_', '/');

      // Fix missing padding
      final remainder = normalized.length % 4;
      if (remainder > 0) {
        normalized += '=' * (4 - remainder);
      }

      return utf8.decode(base64Decode(normalized));
    } catch (_) {
      return null;
    }
  }
}
