import 'dart:convert';

import 'package:arma_proxy_vpn_client/features/server/data/parsers/hysteria2_parser.dart';
import 'package:arma_proxy_vpn_client/features/server/data/parsers/shadowsocks_parser.dart';
import 'package:arma_proxy_vpn_client/features/server/data/parsers/trojan_parser.dart';
import 'package:arma_proxy_vpn_client/features/server/data/parsers/vless_parser.dart';
import 'package:arma_proxy_vpn_client/features/server/data/parsers/vmess_parser.dart';
import 'package:arma_proxy_vpn_client/features/server/domain/entities/server_config.dart';

/// Dispatcher that routes share link input to the correct protocol parser.
///
/// Supports all 5 proxy protocol share link formats:
/// - `vless://` → [VlessParser]
/// - `vmess://` → [VmessParser] (both legacy base64-JSON and standard URI)
/// - `trojan://` → [TrojanParser]
/// - `ss://` → [ShadowsocksParser]
/// - `hysteria2://` / `hy2://` → [Hysteria2Parser]
///
/// Also handles raw JSON VMess config objects (for CONF-06 support).
class ShareLinkParser {
  ShareLinkParser._();

  static const _maxInputLength = 10000;

  /// Parses any supported share link or raw JSON VMess config.
  ///
  /// Trims whitespace, detects the scheme, and dispatches to the
  /// appropriate protocol parser.
  ///
  /// Returns a [ServerConfig] on success, or `null` for invalid,
  /// unsupported, or malformed input.
  static ServerConfig? parse(String input) {
    try {
      final trimmed = input.trim();
      if (trimmed.isEmpty) return null;
      if (trimmed.length > _maxInputLength) return null;

      final lower = trimmed.toLowerCase();

      // Scheme-based dispatch
      if (lower.startsWith('vless://')) {
        return VlessParser.parse(trimmed);
      }
      if (lower.startsWith('vmess://')) {
        return VmessParser.parse(trimmed);
      }
      if (lower.startsWith('trojan://')) {
        return TrojanParser.parse(trimmed);
      }
      if (lower.startsWith('ss://')) {
        return ShadowsocksParser.parse(trimmed);
      }
      if (lower.startsWith('hysteria2://') || lower.startsWith('hy2://')) {
        return Hysteria2Parser.parse(trimmed);
      }

      // Fallback: try raw JSON VMess config (CONF-06 support)
      return _tryRawJsonVmess(trimmed);
    } catch (_) {
      return null;
    }
  }

  /// Attempts to parse raw JSON as a VMess config object.
  ///
  /// This handles cases where a user pastes a raw JSON blob
  /// like `{"v":"2","ps":"name","add":"server",...}`.
  static ServerConfig? _tryRawJsonVmess(String input) {
    try {
      // Quick check — must look like JSON
      if (!input.startsWith('{')) return null;

      final json = jsonDecode(input) as Map<String, dynamic>;
      // Must have 'add' and 'id' fields to be a VMess config
      if (!json.containsKey('add') || !json.containsKey('id')) return null;

      // Re-encode as vmess:// link for the VMess parser
      final base64Content = base64Encode(utf8.encode(jsonEncode(json)));
      return VmessParser.parse('vmess://$base64Content');
    } catch (_) {
      return null;
    }
  }
}
