import 'package:arma_proxy_vpn_client/features/api/presentation/providers/auth_bootstrap_provider.dart';
import 'package:arma_proxy_vpn_client/features/api/domain/entities/auth_state.dart';
import 'package:arma_proxy_vpn_client/features/api/presentation/providers/auth_provider.dart';
import 'package:arma_proxy_vpn_client/features/api/presentation/providers/default_server_keys_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('authBootstrapProvider', () {
    test(
      'resolves startup auth and key prewarm only once per container lifecycle',
      () async {
        var refreshCalls = 0;
        var keyPrewarmReads = 0;
        final container = ProviderContainer(
          overrides: [
            authStatusRefreshProvider.overrideWithValue(() async {
              refreshCalls++;
              return const AuthState(
                token: 'startup-token',
                isAuthenticated: true,
                isGuest: true,
                userId: 1,
              );
            }),
            defaultServerKeysProvider.overrideWith((ref) async {
              keyPrewarmReads++;
              return const [];
            }),
          ],
        );
        addTearDown(container.dispose);

        await container.read(authBootstrapProvider.future);
        await container.read(authBootstrapProvider.future);
        await Future<void>.delayed(Duration.zero);

        expect(refreshCalls, 1);
        expect(keyPrewarmReads, 1);
      },
    );

    test('supports manual rerun after provider refresh', () async {
      var refreshCalls = 0;
      var keyPrewarmReads = 0;
      final container = ProviderContainer(
        overrides: [
          authStatusRefreshProvider.overrideWithValue(() async {
            refreshCalls++;
            return const AuthState(
              token: 'startup-token',
              isAuthenticated: true,
              isGuest: true,
              userId: 1,
            );
          }),
          defaultServerKeysProvider.overrideWith((ref) async {
            keyPrewarmReads++;
            return const [];
          }),
        ],
      );
      addTearDown(container.dispose);

      await container.read(authBootstrapProvider.future);
      await Future<void>.delayed(Duration.zero);
      expect(refreshCalls, 1);
      expect(keyPrewarmReads, 1);

      container.refresh(authBootstrapProvider);
      await container.read(authBootstrapProvider.future);
      await Future<void>.delayed(Duration.zero);

      expect(refreshCalls, 2);
      expect(keyPrewarmReads, 2);
    });
  });
}
