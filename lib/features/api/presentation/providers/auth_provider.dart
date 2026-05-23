import 'dart:io';

import 'package:arma_proxy_vpn_client/features/api/data/datasources/api_client.dart';
import 'package:arma_proxy_vpn_client/features/api/data/datasources/auth_local_datasource.dart';
import 'package:arma_proxy_vpn_client/features/api/data/repositories/auth_repository_impl.dart';
import 'package:arma_proxy_vpn_client/features/api/data/services/device_id_service.dart';
import 'package:arma_proxy_vpn_client/features/api/domain/entities/auth_state.dart';
import 'package:arma_proxy_vpn_client/features/api/domain/repositories/auth_repository.dart';
import 'package:hive_ce/hive_ce.dart';
import 'package:http/http.dart' as http;
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'auth_provider.g.dart';

@Riverpod(keepAlive: true)
ApiClient apiClient(Ref ref) {
  final client = http.Client();
  ref.onDispose(client.close);
  return ApiClient(client: client);
}

@Riverpod(keepAlive: true)
AuthLocalDatasource authLocalDatasource(Ref ref) {
  final box = Hive.box<dynamic>(AuthLocalDatasource.authStateBoxName);
  return AuthLocalDatasource(box);
}

@Riverpod(keepAlive: true)
DeviceIdService deviceIdService(Ref ref) {
  final datasource = ref.watch(authLocalDatasourceProvider);
  return DeviceIdService(datasource);
}

@Riverpod(keepAlive: true)
AuthRepository authRepository(Ref ref) {
  final apiClient = ref.watch(apiClientProvider);
  final datasource = ref.watch(authLocalDatasourceProvider);
  final deviceIdService = ref.watch(deviceIdServiceProvider);
  return AuthRepositoryImpl(
    apiClient: apiClient,
    authLocalDatasource: datasource,
    deviceIdService: deviceIdService,
    appVersion: '1.0.0',
    osType: Platform.isAndroid ? 'android' : 'ios',
  );
}

@Riverpod(keepAlive: true)
class AuthStateNotifier extends _$AuthStateNotifier {
  @override
  Future<AuthState> build() async {
    final datasource = ref.watch(authLocalDatasourceProvider);
    return datasource.readAuthState();
  }

  Future<void> reload() async {
    final datasource = ref.read(authLocalDatasourceProvider);
    state = AsyncValue.data(datasource.readAuthState());
  }
}

@riverpod
Future<String> authToken(Ref ref) async {
  final repository = ref.watch(authRepositoryProvider);
  final token = await repository.getValidToken();
  await ref.read(authStateProvider.notifier).reload();
  return token;
}
