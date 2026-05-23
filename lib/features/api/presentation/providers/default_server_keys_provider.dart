import 'package:arma_proxy_vpn_client/features/api/domain/entities/default_server_key.dart';
import 'package:arma_proxy_vpn_client/features/api/presentation/providers/auth_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'default_server_keys_provider.g.dart';

/// Supports manual retry by calling `ref.refresh(defaultServerKeysProvider)`.
@riverpod
Future<List<DefaultServerKey>> defaultServerKeys(Ref ref) async {
  final repository = ref.watch(authRepositoryProvider);
  final apiClient = ref.watch(apiClientProvider);

  return repository.executeWithAuthRetry((token) async {
    final models = await apiClient.getKeys(token);
    return models.map((model) => model.toDomain()).toList(growable: false);
  });
}
