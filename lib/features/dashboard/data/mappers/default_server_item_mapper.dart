import 'package:arma_proxy_vpn_client/features/api/domain/entities/default_server_key.dart';
import 'package:arma_proxy_vpn_client/features/dashboard/domain/entities/default_server_item.dart';
import 'package:arma_proxy_vpn_client/features/server/data/parsers/subscription_parser.dart';
import 'package:arma_proxy_vpn_client/features/server/domain/entities/server_config.dart';

/// Maps API key payloads into dashboard/connection-ready default server items.
class DefaultServerItemMapper {
  const DefaultServerItemMapper._();

  static DefaultServerItem map(DefaultServerKey key) {
    return mapAll(key).first;
  }

  static List<DefaultServerItem> mapAll(DefaultServerKey key) {
    final parsedConfigs = SubscriptionParser.parseBody(key.keyBody);
    return mapResolved(key, parsedConfigs);
  }

  static List<DefaultServerItem> mapResolved(
    DefaultServerKey key,
    List<ServerConfig> servers,
  ) {
    final parsedConfigs = servers;
    if (parsedConfigs.isEmpty) {
      return [_fallbackItem(key)];
    }

    if (parsedConfigs.length == 1) {
      final normalizedId = 'default-api-${key.id}';
      final serverConfig = parsedConfigs.single.copyWith(
        id: normalizedId,
        name: key.name,
      );
      return [
        _toItem(
          key,
          id: normalizedId,
          name: key.name,
          serverConfig: serverConfig,
        ),
      ];
    }

    return List<DefaultServerItem>.generate(parsedConfigs.length, (index) {
      final parsedConfig = parsedConfigs[index];
      final rowId = 'default-api-${key.id}-${index + 1}';
      final parsedName = parsedConfig.name.trim();
      final rowName = parsedName.isEmpty
          ? '${key.name} ${index + 1}'
          : parsedName;
      final scopedConfig = parsedConfig.copyWith(id: rowId, name: rowName);
      return _toItem(key, id: rowId, name: rowName, serverConfig: scopedConfig);
    }, growable: false);
  }

  static DefaultServerItem _fallbackItem(DefaultServerKey key) {
    final normalizedId = 'default-api-${key.id}';
    return _toItem(key, id: normalizedId, name: key.name, serverConfig: null);
  }

  static DefaultServerItem _toItem(
    DefaultServerKey key, {
    required String id,
    required String name,
    required ServerConfig? serverConfig,
  }) {
    return DefaultServerItem(
      id: id,
      name: name,
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
