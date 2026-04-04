import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:hive_ce/hive_ce.dart';
import 'package:arma_proxy_vpn_client/features/server/domain/entities/server_config.dart';
import 'package:arma_proxy_vpn_client/features/server/data/datasources/server_local_datasource.dart';
import 'package:arma_proxy_vpn_client/features/server/data/models/server_config_model.dart';
import 'package:arma_proxy_vpn_client/features/server/data/repositories/server_repository_impl.dart';
import 'package:arma_proxy_vpn_client/features/server/domain/repositories/server_repository.dart';

part 'server_list_provider.g.dart';

/// Provides the [ServerRepository] instance backed by Hive.
///
/// Keep-alive so the repository persists for the app's lifetime.
@Riverpod(keepAlive: true)
ServerRepository serverRepository(Ref ref) {
  final box = Hive.box<ServerConfigModel>('configs');
  final datasource = ServerLocalDatasource(box);
  return ServerRepositoryImpl(datasource);
}

/// Riverpod notifier for the reactive list of saved server configurations.
///
/// Exposes methods to add and delete servers, automatically refreshing
/// the list when changes occur.
@riverpod
class ServerListNotifier extends _$ServerListNotifier {
  @override
  Future<List<ServerConfig>> build() async {
    final repository = ref.watch(serverRepositoryProvider);
    return repository.getAllConfigs();
  }

  /// Adds a server configuration and refreshes the list.
  Future<void> addServer(ServerConfig config) async {
    final repository = ref.read(serverRepositoryProvider);
    await repository.saveConfig(config);
    ref.invalidateSelf();
  }

  /// Deletes a server configuration by ID and refreshes the list.
  Future<void> deleteServer(String id) async {
    final repository = ref.read(serverRepositoryProvider);
    await repository.deleteConfig(id);
    ref.invalidateSelf();
  }
}
