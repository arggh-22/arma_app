import 'dart:convert';

import 'package:uuid/uuid.dart';

import 'package:arma_proxy_vpn_client/core/constants/protocol_constants.dart';
import 'package:arma_proxy_vpn_client/features/server/domain/entities/server_config.dart';

/// Parses SIP008 JSON subscription format into [ServerConfig] list.
///
/// SIP008 is a Shadowsocks standard for subscription delivery.
/// Supports two formats:
/// - Direct JSON array: `[{"server":"...","server_port":...,...}]`
/// - Wrapped format: `{"version":1,"servers":[...]}`
///
/// Validates required fields per T-03-06: entries with missing
/// `server` or `server_port` are skipped, not rejected.
class Sip008Parser {
  Sip008Parser._();

  /// Attempts to parse a SIP008 JSON body.
  ///
  /// Returns a list of [ServerConfig] on success, or `null` if the
  /// input is not valid SIP008 JSON.
  static List<ServerConfig>? tryParse(String body) {
    if (body.trim().isEmpty) return null;

    try {
      final decoded = jsonDecode(body);
      List<dynamic>? servers;

      if (decoded is List) {
        servers = decoded;
      } else if (decoded is Map<String, dynamic>) {
        final serversField = decoded['servers'];
        if (serversField is List) {
          servers = serversField;
        }
      }

      if (servers == null) return null;

      final results = <ServerConfig>[];
      for (final entry in servers) {
        if (entry is! Map<String, dynamic>) continue;
        final config = _parseEntry(entry);
        if (config != null) results.add(config);
      }

      return results.isEmpty ? null : results;
    } catch (_) {
      return null;
    }
  }

  /// Parses a single SIP008 server entry.
  ///
  /// Required fields: `server`, `server_port`.
  /// Returns `null` if required fields are missing or invalid.
  static ServerConfig? _parseEntry(Map<String, dynamic> entry) {
    final server = entry['server']?.toString();
    if (server == null || server.isEmpty) return null;

    final port = _parseInt(entry['server_port']);
    if (port == null || port <= 0 || port > 65535) return null;

    final password = entry['password']?.toString() ?? '';
    final method = entry['method']?.toString() ?? 'aes-256-gcm';

    // Name priority: remarks > tag > address:port
    final remarks = entry['remarks']?.toString();
    final tag = entry['tag']?.toString();
    final name = (remarks != null && remarks.isNotEmpty)
        ? remarks
        : (tag != null && tag.isNotEmpty)
        ? tag
        : '$server:$port';

    return ServerConfig(
      id: const Uuid().v4(),
      name: name,
      protocol: ProtocolType.shadowsocks,
      address: server,
      port: port,
      password: password,
      method: method,
      addedAt: DateTime.now(),
    );
  }

  static int? _parseInt(dynamic value) {
    if (value is int) return value;
    if (value is String) return int.tryParse(value);
    return null;
  }
}
