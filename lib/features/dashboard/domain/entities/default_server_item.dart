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
  });

  final String id;
  final String name;
  final String status;
  final int usedTraffic;
  final int dataLimit;
  final String subscriptionUrl;
  final DateTime expireDate;
  final bool isActive;
  final ServerConfig? serverConfig;

  bool get isConnectable => isActive && serverConfig != null;
}
