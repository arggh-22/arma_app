import 'package:arma_proxy_vpn_client/features/api/domain/entities/default_server_key.dart';
import 'package:arma_proxy_vpn_client/features/dashboard/domain/entities/default_server_item.dart';
import 'package:arma_proxy_vpn_client/features/server/data/parsers/share_link_parser.dart';

/// Maps API key payloads into dashboard/connection-ready default server items.
class DefaultServerItemMapper {
  const DefaultServerItemMapper._();

  static DefaultServerItem map(DefaultServerKey key) {
    final normalizedId = 'default-api-${key.id}';
    final parsedConfig = ShareLinkParser.parse(key.keyBody);
    final serverConfig = parsedConfig?.copyWith(
      id: normalizedId,
      name: key.name,
    );

    return DefaultServerItem(
      id: normalizedId,
      name: key.name,
      status: key.status,
      usedTraffic: key.usedTraffic,
      dataLimit: key.dataLimit,
      subscriptionUrl: key.subscriptionUrl,
      expireDate: key.expireDate,
      isActive: key.isActive,
      serverConfig: serverConfig,
    );
  }
}
