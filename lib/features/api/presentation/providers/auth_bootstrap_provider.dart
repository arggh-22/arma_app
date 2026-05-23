import 'dart:async';

import 'package:arma_proxy_vpn_client/features/api/presentation/providers/auth_provider.dart';
import 'package:arma_proxy_vpn_client/features/api/presentation/providers/default_server_keys_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'auth_bootstrap_provider.g.dart';

/// Startup bootstrap that authenticates once and prewarms default key fetches.
@Riverpod(keepAlive: true)
class AuthBootstrap extends _$AuthBootstrap {
  Future<void>? _bootstrapFuture;

  @override
  Future<void> build() {
    return _bootstrapFuture ??= _runBootstrap();
  }

  Future<void> _runBootstrap() async {
    await ref.watch(authTokenProvider.future);
    unawaited(ref.read(defaultServerKeysProvider.future));
  }
}
