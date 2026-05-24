import 'package:arma_proxy_vpn_client/features/api/data/datasources/default_server_cache_datasource.dart';
import 'package:arma_proxy_vpn_client/features/api/data/models/default_server_cache_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ce/hive_ce.dart';

final defaultServerCacheDatasourceProvider =
    Provider<DefaultServerCacheDatasource>((ref) {
      final box = Hive.box<dynamic>(DefaultServerCacheDatasource.boxName);
      return DefaultServerCacheDatasource(box);
    });

final defaultServerCacheProvider = FutureProvider<DefaultServerCacheModel?>(
  (ref) => ref.watch(defaultServerCacheDatasourceProvider).read(),
);
