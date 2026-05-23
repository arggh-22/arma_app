import 'package:arma_proxy_vpn_client/features/api/presentation/providers/auth_bootstrap_provider.dart';
import 'package:arma_proxy_vpn_client/features/api/presentation/providers/auth_provider.dart';
import 'package:arma_proxy_vpn_client/features/api/presentation/providers/default_server_keys_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('authBootstrapProvider', () {
    test(
      'resolves startup auth and key prewarm only once per container lifecycle',
      () async {
        var authReads = 0;
        var keyPrewarmReads = 0;
        final container = ProviderContainer(
          overrides: [
            authTokenProvider.overrideWith((ref) async {
              authReads++;
              return 'startup-token';
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

        expect(authReads, 1);
        expect(keyPrewarmReads, 1);
      },
    );
  });
}
