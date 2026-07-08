import 'package:arma_proxy_vpn_client/features/server/domain/entities/server_config.dart';

/// Dashboard-facing contract for an API-provided default server.
class DefaultServerItem {
  const DefaultServerItem({
    required this.id,
    required this.name,
    required this.status,
    required this.usedTraffic,
    required this.dataLimit,
    required this.subscriptionUrl,
    required this.expireDate,
    required this.isActive,
    required this.serverConfig,
    this.keyName = '',
    this.announcement,
    this.supportUrl,
    this.webPageUrl,
  });

  final String id;
  final String name;

  /// Display name of the parent API key (the subscription this server belongs
  /// to). Shared by every server row from the same key so the dashboard can
  /// group rows into one per-subscription block.
  final String keyName;

  final String status;
  final int usedTraffic;
  final int dataLimit;
  final String subscriptionUrl;
  final DateTime expireDate;
  final bool isActive;
  final ServerConfig? serverConfig;

  /// Per-key `announce` notice (spec §2), if the subscription carried one.
  final String? announcement;

  /// Per-key `support-url` header.
  final String? supportUrl;

  /// Per-key `profile-web-page-url` header.
  final String? webPageUrl;

  bool get isConnectable => isActive && serverConfig != null;
}
